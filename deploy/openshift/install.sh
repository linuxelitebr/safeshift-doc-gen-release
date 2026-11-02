#!/usr/bin/env bash
# SafeShift Doc Gen - one-shot OpenShift installer.
#
# Single self-contained script. Distribute this file; users do not need
# the rest of the repo. Re-runnable: existing token is preserved unless
# --rotate-token is passed.
#
# Usage:
#   bash install.sh                   # install or update
#   bash install.sh --rotate-token    # regenerate the auth token
#   bash install.sh --uninstall       # remove the namespace + cluster RBAC
#   bash install.sh -y                # skip confirmation prompt
#   bash install.sh --help
#
# Requires: oc on PATH, an active `oc login`, openssl.
#
# The YAML below mirrors the numbered manifests in this directory
# (00-namespace ... 05-route). When you change one, mirror the change here.

set -euo pipefail

NAMESPACE="safeshift-doc-gen"
SECRET_NAME="safeshift-doc-gen-auth"
DEPLOYMENT="safeshift-doc-gen"
ROUTE="safeshift-doc-gen"

ROTATE_TOKEN=false
UNINSTALL=false
NO_CONFIRM=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [--rotate-token] [--uninstall] [-y] [--help]

  --rotate-token   Replace the auth token even if the Secret already exists.
  --uninstall      Remove namespace, ClusterRole and ClusterRoleBinding.
  -y, --yes        Skip the confirmation prompt.
  -h, --help       Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rotate-token) ROTATE_TOKEN=true; shift ;;
        --uninstall)    UNINSTALL=true; shift ;;
        -y|--yes)       NO_CONFIRM=true; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              error "unknown argument: $1" ;;
    esac
done

for cmd in oc openssl; do
    command -v "$cmd" &>/dev/null || error "'$cmd' not found. Install it and try again."
done

oc whoami &>/dev/null || error "Not logged into a cluster. Run 'oc login ...' first."
CLUSTER=$(oc whoami --show-server)
WHO=$(oc whoami)
info "Logged in as '${WHO}' on ${CLUSTER}"

if [ "$UNINSTALL" = true ]; then
    if [ "$NO_CONFIRM" = false ]; then
        echo
        warn "This will remove the '${NAMESPACE}' namespace and the cluster-scoped"
        warn "RBAC objects (${DEPLOYMENT}-reader ClusterRole + ClusterRoleBinding)."
        read -r -p "Continue? [y/N] " confirm
        [[ "${confirm,,}" == "y" ]] || { warn "Aborted."; exit 0; }
    fi
    info "Removing ClusterRoleBinding..."
    oc delete clusterrolebinding "${DEPLOYMENT}-reader" --ignore-not-found
    info "Removing ClusterRole..."
    oc delete clusterrole "${DEPLOYMENT}-reader" --ignore-not-found
    info "Removing namespace ${NAMESPACE}..."
    oc delete namespace "${NAMESPACE}" --ignore-not-found
    info "Done."
    exit 0
fi

if [ "$NO_CONFIRM" = false ]; then
    echo
    echo -e "${CYAN}This will install SafeShift Doc Gen in namespace '${NAMESPACE}'.${NC}"
    echo "Container image: ghcr.io/elastocera/safeshift-doc-gen:latest"
    read -r -p "Continue? [y/N] " confirm
    [[ "${confirm,,}" == "y" ]] || { warn "Aborted."; exit 0; }
    echo
fi

if ! oc get namespace "$NAMESPACE" &>/dev/null; then
    info "Creating namespace ${NAMESPACE}..."
    oc create namespace "$NAMESPACE" >/dev/null
fi

TOKEN_NEW=false
if oc -n "$NAMESPACE" get secret "$SECRET_NAME" &>/dev/null && [ "$ROTATE_TOKEN" = false ]; then
    info "Secret ${SECRET_NAME} already exists; keeping current token."
    info "Pass --rotate-token to replace it."
    TOKEN=$(oc -n "$NAMESPACE" get secret "$SECRET_NAME" -o jsonpath='{.data.token}' | base64 --decode)
else
    info "Generating new auth token..."
    TOKEN=$(openssl rand -hex 32)
    oc -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
        --from-literal=token="$TOKEN" \
        --dry-run=client -o yaml | oc apply -f - >/dev/null
    TOKEN_NEW=true
fi

info "Applying manifests..."

# Older bash (4.x on RHEL bastions) trips on heredocs inside $(...)
# command substitution. Drop the YAML to a tempfile at top level so any
# bash from 3.0 onward can parse the script cleanly.
TMPYAML=$(mktemp)
trap 'rm -f "$TMPYAML"' EXIT

cat > "$TMPYAML" <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: safeshift-doc-gen
  labels:
    app.kubernetes.io/name: safeshift-doc-gen
    app.kubernetes.io/part-of: safeshift-doc-gen
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: safeshift-doc-gen
  namespace: safeshift-doc-gen
  labels:
    app.kubernetes.io/name: safeshift-doc-gen
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: safeshift-doc-gen-reader
  labels:
    app.kubernetes.io/name: safeshift-doc-gen
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
  - nonResourceURLs: ["*"]
    verbs: ["get"]
  - apiGroups: ["authentication.open-cluster-management.io"]
    resources: ["managedserviceaccounts"]
    verbs: ["get", "list", "create", "delete"]
  - apiGroups: ["work.open-cluster-management.io"]
    resources: ["manifestworks"]
    verbs: ["get", "list", "create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: safeshift-doc-gen-reader
  labels:
    app.kubernetes.io/name: safeshift-doc-gen
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: safeshift-doc-gen-reader
subjects:
  - kind: ServiceAccount
    name: safeshift-doc-gen
    namespace: safeshift-doc-gen
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: safeshift-doc-gen
  namespace: safeshift-doc-gen
  labels:
    app.kubernetes.io/name: safeshift-doc-gen
    app.kubernetes.io/component: web
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app.kubernetes.io/name: safeshift-doc-gen
  template:
    metadata:
      labels:
        app.kubernetes.io/name: safeshift-doc-gen
        app.kubernetes.io/component: web
    spec:
      serviceAccountName: safeshift-doc-gen
      terminationGracePeriodSeconds: 120
      containers:
        - name: app
          image: ghcr.io/elastocera/safeshift-doc-gen:latest
          imagePullPolicy: IfNotPresent
          args: ["--web"]
          ports:
            - name: http
              containerPort: 5000
              protocol: TCP
          env:
            - name: PYTHONUNBUFFERED
              value: "1"
            - name: SSDG_DEBUG
              value: "false"
            - name: SSDG_AUTH_TOKEN
              valueFrom:
                secretKeyRef:
                  name: safeshift-doc-gen-auth
                  key: token
          readinessProbe:
            httpGet:
              path: /api/health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 2
          livenessProbe:
            httpGet:
              path: /api/health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 30
            timeoutSeconds: 3
            failureThreshold: 3
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: "1"
              memory: 2Gi
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: RuntimeDefault
          volumeMounts:
            - name: output
              mountPath: /app/output
            - name: cache
              mountPath: /app/cache
            - name: kube
              mountPath: /home/docgen/.kube
            - name: tmp
              mountPath: /tmp
      # All scratch volumes are emptyDir so the pod has zero persistent state.
      volumes:
        - name: output
          emptyDir:
            sizeLimit: 1Gi
        - name: cache
          emptyDir:
            sizeLimit: 256Mi
        - name: kube
          emptyDir:
            sizeLimit: 16Mi
        - name: tmp
          emptyDir:
            sizeLimit: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: safeshift-doc-gen
  namespace: safeshift-doc-gen
  labels:
    app.kubernetes.io/name: safeshift-doc-gen
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: safeshift-doc-gen
  ports:
    - name: http
      port: 5000
      targetPort: http
      protocol: TCP
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: safeshift-doc-gen
  namespace: safeshift-doc-gen
  labels:
    app.kubernetes.io/name: safeshift-doc-gen
  annotations:
    # above the 300 s asciidoctor-pdf cap, since /api/convert-pdf renders inside the request
    haproxy.router.openshift.io/timeout: "330s"
spec:
  to:
    kind: Service
    name: safeshift-doc-gen
    weight: 100
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
YAML

APPLY_EXIT=0
APPLY_OUTPUT=$(oc apply -f "$TMPYAML" 2>&1) || APPLY_EXIT=$?
echo "${APPLY_OUTPUT}"

# spec.selector on a Deployment is immutable. If a previous install had a
# different selector (e.g. an older version), apply fails. Offer to recreate
# only the Deployment when we see that exact error.
if [ "$APPLY_EXIT" -ne 0 ]; then
    if echo "${APPLY_OUTPUT}" | grep -q 'spec.selector.*field is immutable'; then
        echo
        warn "An existing Deployment has a selector incompatible with this version."
        warn "Kubernetes does not allow changing 'spec.selector'."
        if [ "$NO_CONFIRM" = false ]; then
            read -r -p "Delete the existing Deployment and re-apply? Other resources are kept. [y/N] " replace
            [[ "${replace,,}" == "y" ]] || error "Aborted. Run 'oc -n ${NAMESPACE} delete deployment ${DEPLOYMENT}' manually to retry."
        fi
        info "Deleting existing Deployment..."
        oc -n "$NAMESPACE" delete deployment "$DEPLOYMENT" --ignore-not-found
        info "Re-running installer..."
        exec "$0" -y
    else
        error "oc apply failed. See output above."
    fi
fi

info "Waiting for the Deployment to become ready..."
oc -n "$NAMESPACE" rollout status "deployment/${DEPLOYMENT}" --timeout=180s

URL="https://$(oc -n "$NAMESPACE" get route "$ROUTE" -o jsonpath='{.spec.host}')"

echo
info "SafeShift Doc Gen is ready."
echo "  Dashboard:  ${URL}"
echo "  Open:       ${URL}/?token=${TOKEN}"
if [ "$TOKEN_NEW" = true ]; then
    echo
    warn "Save this auth token; it is only printed when first generated:"
    echo "  ${TOKEN}"
fi

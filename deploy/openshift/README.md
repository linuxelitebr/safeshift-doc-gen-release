# SafeShift Doc Gen - OpenShift Deployment

Kubernetes manifests to run SafeShift Doc Gen as a Deployment inside an OpenShift cluster. The pod uses its own ServiceAccount to talk to the cluster, so no token or kubeconfig needs to be entered through the UI.

## What's in here

Files are prefixed with a number so `oc apply -f <dir>` processes them in the right order (namespace first, then the rest):

| File | Purpose |
|------|---------|
| `00-namespace.yaml` | Dedicated `safeshift-doc-gen` namespace |
| `01-rbac.yaml` | ServiceAccount + read-only ClusterRole covering every resource SSDG collects, plus binding |
| `02-pvc.yaml` | 5 GiB RWO volume that persists generated `.adoc` / `.pdf` under `/app/output` |
| `03-deployment.yaml` | Single-replica Deployment (Recreate strategy) with readiness/liveness on `/api/health`. Reads `SSDG_AUTH_TOKEN` from the `safeshift-doc-gen-auth` Secret (see below). |
| `04-service.yaml` | ClusterIP Service on port 5000 |
| `05-route.yaml` | Edge-TLS Route with HTTP -> HTTPS redirect |
| `install.sh` | Self-contained installer (the YAML above is embedded inline). Distribute it on its own to install on a fresh cluster without the rest of the repo. |

## About the auth token

The dashboard requires `SSDG_AUTH_TOKEN`. Without it the pod refuses to bind `0.0.0.0` and the Service ends up with no backends. `install.sh` creates and rotates this Secret automatically; the manual path further below shows the equivalent commands.

Anyone consuming the Route needs this token in `Authorization: Bearer <token>` for `/api/*`, or as the cookie set by the `?token=...` handoff URL the SafeShift binary opens locally.

## Easiest path: install.sh

A single self-contained installer that creates the namespace, generates the auth token, applies every manifest, and prints the dashboard URL ready to use:

```bash
bash deploy/openshift/install.sh
```

Re-runnable. The token is preserved across re-runs unless you pass `--rotate-token`. To remove everything: `bash deploy/openshift/install.sh --uninstall`. Run with `--help` to see the full flag list.

The script is fully standalone (the YAML is embedded via heredoc), so you can copy `install.sh` alone to a target machine and run it without cloning the repo.

## Manual apply (numbered files)

Prefer GitOps or per-file review? The numbered manifests are the canonical source:

```bash
TOKEN=$(openssl rand -hex 32)
oc create namespace safeshift-doc-gen 2>/dev/null || true
oc -n safeshift-doc-gen create secret generic safeshift-doc-gen-auth --from-literal=token="$TOKEN"
oc apply -f deploy/openshift/
echo "Token: $TOKEN"
```

## Get the URL

```bash
oc -n safeshift-doc-gen get route safeshift-doc-gen \
   -o jsonpath='https://{.spec.host}{"\n"}'
```

## Verify

Pod is ready:

```bash
oc -n safeshift-doc-gen get pod -l app.kubernetes.io/name=safeshift-doc-gen
```

Health probe responds:

```bash
oc -n safeshift-doc-gen exec deploy/safeshift-doc-gen -- \
   curl -fsS http://localhost:5000/api/health
```

ServiceAccount auto-login happened. Expect a line like `[SA] Logged in via ServiceAccount to https://...`:

```bash
oc -n safeshift-doc-gen logs deploy/safeshift-doc-gen | grep '\[SA\]'
```

## How the ServiceAccount auth works

When the Flask app starts, it checks for `/var/run/secrets/kubernetes.io/serviceaccount/token`. If the file exists (i.e., running inside a pod) and `oc whoami` currently reports no session, the app runs `oc login --token=$(cat .../token) --server=https://kubernetes.default.svc` automatically.

Outside the cluster (dev workstation, `ssdg --web` on a laptop), this code path is a no-op and the user still authenticates via the Dashboard form.

## Customizing

- **Image**: edit `spec.template.spec.containers[0].image` in `03-deployment.yaml`. The default is `ghcr.io/elastocera/safeshift-doc-gen:latest`.
- **Hostname**: set `spec.host` in `route.yaml` (otherwise the router auto-generates based on the default domain).
- **StorageClass**: `pvc.yaml` uses whatever the cluster marks as default. Add `storageClassName:` if you need a specific class.
- **Resources**: tune `requests`/`limits` under the container spec. Batch generation of many clusters can peak >1 GiB briefly.

## Namespace-scoped alternative

The default `rbac.yaml` uses a ClusterRole because SSDG needs to read cluster-wide resources (nodes, cluster config, operators, etc.). For a narrower scope (e.g., documenting a single tenant namespace only) you can replace the ClusterRoleBinding with a RoleBinding + Role limited to that namespace. Expect reduced coverage in the generated document.

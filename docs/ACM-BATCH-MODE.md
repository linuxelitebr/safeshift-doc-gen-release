# ACM Discovery Batch Mode

Generate documentation for all managed clusters from a single ACM Hub command.

## Overview

The `--acm-batch` flag enables automatic discovery of all managed clusters registered in an ACM (Advanced Cluster Management) Hub. It generates individual documentation for each cluster without manual intervention.

## Prerequisites

- Authenticated to an **ACM Hub** cluster (`oc login`)
- ACM in **Running** state
- **managed-serviceaccount** addon enabled (for imported clusters)
- Network connectivity from Hub to managed clusters API endpoints

## Usage

### CLI

Document all managed clusters:

```bash
python3 cli.py --acm-batch --client "Company Name" --output-dir output/
```

Include the Hub cluster itself:

```bash
python3 cli.py --acm-batch --client "Company Name" --output-dir output/ --include-hub
```

With language selection:

```bash
python3 cli.py --acm-batch --client "Company Name" --output-dir output/ --lang en_US
```

### Go Binary

```bash
ssdg --acm-batch --client "Company Name" --output-dir output/
ssdg --acm-batch --client "Company Name" --output-dir output/ --include-hub
```

### Container

```bash
podman run --rm \
  -v ~/.kube:/home/docgen/.kube:ro \
  ghcr.io/elastocera/safeshift-doc-gen:latest \
  --acm-batch --client "Company Name"
```

## How It Works

### Cluster Discovery

1. Validates the current cluster is an ACM Hub
2. Lists all `ManagedClusters` with status `Available`
3. Identifies cluster types: **Hosted**, **Imported**, or **Hub**

### Access Methods

| Cluster Type | Access Method | Credentials |
|---|---|---|
| **Hosted** | kubeconfig from Hub secret | `<hc-name>-admin-kubeconfig` in hosting namespace |
| **Imported** | Temporary ManagedServiceAccount | Created on demand, cleaned up after |
| **Hub** (with `--include-hub`) | Current oc context | No extra credentials needed |

### Batch Flow

```
Hub (ACM) ---> List ManagedClusters
               |
               +---> Hosted Cluster
               |     Extract kubeconfig from secret
               |     Generate documentation
               |
               +---> Imported Cluster
               |     Create MSA + RBAC (ManifestWork)
               |     Wait for token
               |     Generate documentation
               |     Cleanup MSA + RBAC
               |
               +---> Hub (if --include-hub)
                     Use current context
                     Generate documentation
```

## Output

One AsciiDoc file per cluster in the output directory:

```
output/
  cluster-name-1.pt_BR.adoc
  cluster-name-2.pt_BR.adoc
  hosting-cluster.pt_BR.adoc
```

## Security

### Principle of Least Privilege

- Uses **read-only** access (`cluster-reader` + custom `ssdg-batch-reader` ClusterRole)
- Never uses `cluster-admin`
- Custom role grants only `get` and `list` verbs on specific API groups
- ServiceAccount created in ACM addon namespace, not in application namespaces

### Temporary Resources

For **imported clusters**, the following resources are created temporarily:

**On the Hub:**
- `ManagedServiceAccount/ssdg-batch-reader` in `<cluster-namespace>`
- `ManifestWork/ssdg-batch-reader-rbac` in `<cluster-namespace>`

**On the remote cluster (via ManifestWork):**
- `ClusterRole/ssdg-batch-reader` (read-only rules)
- `ClusterRoleBinding/ssdg-batch-reader-cluster-reader`
- `ClusterRoleBinding/ssdg-batch-reader-ssdg-role`

All resources are:
- Labeled with `app.kubernetes.io/managed-by: safeshift-doc-gen`
- Annotated with purpose and auto-cleanup markers
- **Automatically removed** after documentation is generated (try/finally)
- Token validity: **1 hour** (auto-expires)

### Kubeconfig Handling

- Container mode: stored on **tmpfs** (`/home/docgen/.kube/`) with zero disk persistence
- CLI mode: stored in temp file with **0600 permissions** (owner read/write only)
- Removed immediately after use
- Never logged or included in output

### Data Sanitization

The existing SSDG sanitizer masks secrets, tokens, passwords, and sensitive data in all generated documents.

## Auditing

Check for residual resources (should return empty after successful execution):

```bash
oc get managedserviceaccount -A -l app.kubernetes.io/managed-by=safeshift-doc-gen
oc get manifestwork -A -l app.kubernetes.io/managed-by=safeshift-doc-gen
```

## Error Handling

- **Cluster unavailable**: skipped, logged, other clusters continue
- **MSA timeout**: skipped after 90 seconds, cleanup executed
- **Ctrl+C (SIGINT)**: cleanup of current cluster resources, graceful exit
- **Any exception**: cleanup guaranteed via try/finally

## Troubleshooting

### "This cluster is not an ACM Hub"

You must be logged into an ACM Hub cluster. Verify:

```bash
oc get multiclusterhub -n open-cluster-management
```

### "ManagedServiceAccount addon not available"

The `managed-serviceaccount` addon must be enabled. Imported clusters will be skipped without it. Check:

```bash
oc get crd managedserviceaccounts.authentication.open-cluster-management.io
oc get managedclusteraddon -A | grep managed-serviceaccount
```

### Permission errors on imported clusters

The `ssdg-batch-reader` ClusterRole covers the specific API groups SSDG needs. If a collector fails with Forbidden errors, the resource is simply skipped and the section appears empty in the document.

### Cleanup failed

If resources remain after a failed execution, clean them up manually:

```bash
oc delete manifestwork ssdg-batch-reader-rbac -n <cluster-namespace>
oc delete managedserviceaccount ssdg-batch-reader -n <cluster-namespace>
```

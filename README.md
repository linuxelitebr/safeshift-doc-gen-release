# SafeShift Doc Gen

Generates audit-grade AsciiDoc and PDF documentation from a live OpenShift cluster or a must-gather archive. Previously published as `OpenShift Documentation Generator`; same project, new home.

[![GHCR](https://img.shields.io/badge/image-ghcr.io%2Felastocera%2Fsafeshift--doc--gen-blue?logo=docker)](https://github.com/orgs/elastocera/packages/container/package/safeshift-doc-gen)
[![Quay](https://img.shields.io/badge/image-quay.io%2Felastocera%2Fssdg-orange?logo=docker)](https://quay.io/repository/elastocera/ssdg)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue)](https://www.python.org)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

---

## What it does

- **Audit-grade collectors.** 40 modules covering platform, storage, networking, auth, observability, virtualization, and multi-cluster management. The newer ones (ODF, CCLM, Descheduler) capture drift signals an auditor can act on, not just inventory snapshots.
- **Two collection modes.** Live cluster via `oc`, or offline from a must-gather archive.
- **Multi-cluster.** ACM Batch Mode documents every managed cluster from a single Hub command, with auto-provisioned read-only credentials per cluster.
- **Multiple outputs.** AsciiDoc as the canonical source, PDF rendered with the brand pack you pick, plain HTML.
- **Topology diagram (Alfa).** Off by default. Draws the cluster, and its node network design, offline with the d2 CLI the image ships: D2 sources, SVGs and a zip next to the document, and on request the diagrams in the PDF on landscape pages.
- **Multilingual.** Output and dashboard in English, Portuguese, or Spanish.
- **Three ways to run.** Standalone `ssdg` binary, container directly, or as a pod on OpenShift with the bundled manifests.
- **Privacy-first.** Automatic redaction of secrets, SSH keys, OAuth tokens, and IDP configs before render. See [`docs/PRIVACY.md`](docs/PRIVACY.md) for the full posture, base-legal coverage, and operator responsibilities.

---

## Quick Start

Two ways for the typical user, ordered easiest first.

### 1. The `ssdg` binary

Download the binary for your platform from the [latest `ssdg` release](https://github.com/elastocera/releases/releases?q=ssdg):

| Platform | Binary |
|---|---|
| macOS (Apple Silicon) | `ssdg-darwin-arm64` |
| macOS (Intel) | `ssdg-darwin-amd64` |
| Linux (x86_64) | `ssdg-linux-amd64` |
| Linux (ARM64) | `ssdg-linux-arm64` |
| Windows | `ssdg-windows-amd64.exe` |

Make it executable and put it on your `PATH`:

```bash
chmod +x ssdg-darwin-arm64
sudo mv ssdg-darwin-arm64 /usr/local/bin/ssdg
```

The binary needs `podman` (or `docker`) on the host. It pulls the container image on first run.

Open the dashboard:

```bash
ssdg --web
```

Or generate from the command line:

```bash
oc login https://api.cluster.example.com:6443
ssdg --client "Acme Corp" --pdf
```

Output lands in `./output/`.

**Tip:** To use a specific image (for example, a local build):

```bash
OCP_DOC_IMAGE=localhost/safeshift-doc-gen:latest ssdg --web --port 5002
```

### 2. Container directly

If you already have `podman` or `docker` and prefer not to install another binary.

Web interface:

```bash
podman run --rm -p 5050:5000 \
  -v $(pwd)/output:/app/output \
  ghcr.io/elastocera/safeshift-doc-gen:latest --web
```

Open `http://localhost:5050`. The Cluster Connection form is the entry point; the Dashboard also auto-detects an existing `oc login` session (or the in-cluster ServiceAccount token when running as a pod).

> Port 5000 is taken by AirPlay Receiver on macOS by default. The example maps host port 5050 to the container's 5000. Adjust if you turned AirPlay Receiver off.

CLI mode:

```bash
podman run --rm \
  -v ~/.kube:/home/docgen/.kube:ro \
  -v $(pwd)/output:/app/output \
  ghcr.io/elastocera/safeshift-doc-gen:latest \
  --client "Acme Corp" --output /app/output/acme.adoc
```

---

## Examples

Cases that go beyond the happy path of `ssdg --client X --pdf`.

Document every managed cluster on an ACM Hub in one shot:

```bash
oc login https://acm-hub.example.com:6443
ssdg --acm-batch --include-hub --pdf
```

Each managed cluster gets a separate `.adoc`/`.pdf` under `./output/batch/`. SSDG provisions a temporary read-only ServiceAccount per imported cluster and cleans it up at the end.

Offline mode from a must-gather archive:

```bash
ssdg --must-gather /path/to/must-gather --client "Acme Corp" --pdf
```

No `oc login` needed.

Pick a specific subset of modules:

```bash
ssdg --client "Acme Corp" --modules cluster nodes storage network --pdf
```

Add a custom logo to the cover page:

```bash
ssdg --client "Acme Corp" --logo ~/Pictures/acme-logo.png --pdf
```

PNG, JPG, WebP, and SVG are accepted. Path can be absolute or relative to the current directory.

Generate in Portuguese with a custom title:

```bash
ssdg --client "Banco Exemplo" --lang pt_BR \
     --title "Diagnóstico do Cluster de Produção" --pdf
```

Tell Me Everything: emit a per-namespace discovery dir next to the doc:

```bash
ssdg --client "Acme Corp" --tme --pdf
```

Writes `<name>-discovery/` with one markdown file per topic: cluster overview, OLM subscriptions, system NS summary, user NS index, one file per user NS, and a consolidated anomalies file. Next to it goes `<name>-discovery-tme.zip`, the same directory zipped, ready to attach to a ticket once you have read it: namespace labels go through the same Sanitizer as the document, while images, Route hosts and IPs ship as the cluster has them. `<name>` is the document name without its language suffix, so `acme-corp-2026-10-15.pt_BR.adoc` gets `acme-corp-2026-10-15-discovery/` and `acme-corp-2026-10-15-discovery-tme.zip`, whichever way you ran it. Off by default. Phase 1.7 ships Tier 1 (counts plus anomaly heuristics) at scope `full` only. Secret values are never shipped: names, types, and key counts only. Same toggle is available in the GUI under Settings, Experimental features, and the results list offers the zip for download next to the document. Under `ssdg --web` that download is the only way out: the launcher keeps the web UI's output in container RAM.

Draw the topology diagram and put it in the PDF (or tick the boxes under Settings, Experimental features, in the web UI):

```bash
ssdg --client "Acme Corp" --diagram-embed --pdf
```

Next to the document you get the diagram sources (`.topology.d2`, `.network.d2`), their SVGs and a `.diagrams.zip` that renders again anywhere with `d2 --layout=elk`. The PDF gets each diagram on an A4 landscape page and ends with an icon credits chapter. `--diagram` alone skips the PDF part. Everything renders offline, nothing is uploaded. See [`docs/FEATURES.md`](docs/FEATURES.md#topology-diagram-alfa) and [`docs/diagram-icons.md`](docs/diagram-icons.md).

---

## Deploy on OpenShift

Run SSDG as a pod inside an OpenShift cluster, served via Route. The bundled manifests provision a ServiceAccount, a read-only ClusterRole, the Deployment with health probes, the Service, and a TLS Route.

```bash
oc apply -f deploy/openshift/
oc -n safeshift-doc-gen get route safeshift-doc-gen \
   -o jsonpath='https://{.spec.host}{"\n"}'
```

See [deploy/openshift/README.md](deploy/openshift/README.md) for the RBAC scope, the auth token Secret, the user-facing OAuth path, and customization notes.

---

## Supported Modules

40 collectors, grouped by what they document:

| Group | Modules |
|---|---|
| **Platform** | `cluster`, `nodes`, `network`, `sriov`, `storage`, `auth`, `baremetal`, `etcd`, `certificates` |
| **Observability** | `monitoring`, `logging`, `cluster_observability` |
| **Workloads** | `virtualization`, `mtv`, `serverless`, `servicemesh`, `pipelines`, `gitops` |
| **Multi-cluster** | `acm`, `acm_hub_backup`, `multicluster_engine`, `hosted_control_planes`, `cclm` |
| **Storage and data** | `odf` |
| **Tuning and Day 2** | `feature_operators`, `machineconfig`, `node_tuning`, `node_health`, `policies`, `console_notifications`, `cronjobs`, `descheduler`, `upgrade_readiness` |
| **Security and compliance** | `compliance`, `rhacs`, `tsr_basic` |
| **Backup** | `backup` |
| **Operators** | `operators` |
| **Registry** | `quay`, `internal_registry` |

Each module can be enabled or disabled per run via `--modules`. Default is "everything detected on the cluster". See [`docs/FEATURES.md`](docs/FEATURES.md) for what each module actually captures.

---

## Documentation

| Guide | Description |
|---|---|
| [Quick Start](docs/QUICKSTART.md) | The dashboard walkthrough, in five minutes |
| [Collectors](docs/COLLECTORS.md) | The modules, what each one captures, and its maturity tier |
| [Features](docs/FEATURES.md) | Full feature reference and architecture |
| [OpenShift Deployment](deploy/openshift/README.md) | Run SSDG as a pod with ServiceAccount auth |
| [ACM Batch Mode](docs/ACM-BATCH-MODE.md) | Document every managed cluster from a single Hub |
| [PDF Generation](docs/PDF_GENERATION_GUIDE.md) | PDF styling, font setup and the diagram embed |
| [Brand packs](docs/BRAND_PACKS.md) | The look of the document, and how to pick or add one |
| [Diagram icons](docs/diagram-icons.md) | Topology stencils, your own vendor logos, icon credits |
| [Product Detection](docs/PRODUCT_DETECTION.md) | How the cover-page engagement whitelist works |
| [Security](docs/SECURITY.md) | Security practices and data handling |
| [Privacy](docs/PRIVACY.md) | Data-handling posture and operator responsibilities |

---

## Disconnected (air-gapped) environments

When the customer bastion has no internet but you can `scp` to it, ship the image as a tarball. The bastion is x86, so force the `amd64` variant, and name the archive the way the launcher expects so it runs without a pull.

On a machine with internet, export the image:

```bash
skopeo --override-arch amd64 --override-os linux copy \
  docker://ghcr.io/elastocera/safeshift-doc-gen:1.8.0 \
  docker-archive:ssdg-1.8.0-amd64.tar:ghcr.io/elastocera/safeshift-doc-gen:1.8.0
```

The `quay.io/elastocera/ssdg` mirror works as the source too, for hosts that block ghcr.io.

Copy it to the bastion:

```bash
scp ssdg-1.8.0-amd64.tar user@bastion:/tmp/
```

Load it on the bastion:

```bash
podman load -i /tmp/ssdg-1.8.0-amd64.tar
```

Run it directly, or via `ssdg`, which finds the loaded image locally and skips the pull:

```bash
podman run --rm -p 5050:5000 -v $(pwd)/output:/app/output ghcr.io/elastocera/safeshift-doc-gen:1.8.0 --web
```

If the loaded image has a different name than the launcher default, either retag it:

```bash
podman tag quay.io/elastocera/ssdg:latest ghcr.io/elastocera/safeshift-doc-gen:latest
```

or point the launcher straight at it with `OCP_DOC_IMAGE`:

```bash
OCP_DOC_IMAGE=quay.io/elastocera/ssdg:latest ssdg --web --port 5002
```

The image bundles `oc`, `omc` and `d2`, so the bastion needs nothing beyond `podman` and a way to reach the cluster (an `oc login` session, or a must-gather for the fully offline path). The topology diagram renders there too, d2 needs no network.

---

## Issues

Bugs and feature requests go to the [issue tracker](https://github.com/linuxelitebr/safeshift-doc-gen-release/issues). This repo holds the docs, the manifests and the changelog, and the binaries live on [elastocera/releases](https://github.com/elastocera/releases/releases?q=ssdg). Security reports do not go in a public issue, see [the policy](docs/SECURITY.md).

---

## License

Apache License 2.0. See [LICENSE](LICENSE) for the full text and [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) for the libraries this project depends on and the fonts/assets it bundles.

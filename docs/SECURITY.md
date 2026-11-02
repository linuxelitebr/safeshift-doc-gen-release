# Security Notes

## Container Image Vulnerability Report

The container image is scanned by Trivy on every build, with results uploaded to the GitHub Security tab. GHCR also surfaces Dependabot advisories on the published package. Vulnerabilities are categorized by origin below.

For the **current** list of CVEs against any given image tag, look at:

- The repo's **Security tab** on GitHub (`Security` > `Code scanning alerts` and `Dependabot alerts`). Trivy uploads SARIF on every container build, so this is the authoritative source.
- The package page on GHCR (`Packages` > `safeshift-doc-gen`), which surfaces Dependabot advisories per published version.

The categories below describe which vulnerabilities the project can fix and which it inherits from third parties.

### 1. UBI9 base image RPMs (fixable)

OpenSSL, glibc, curl, python3.12, gnutls, libarchive, and other RHEL 9 packages pulled into the image. The Containerfile runs `microdnf update -y` at build time, so rebuilding the image picks up whatever security patches Red Hat shipped for UBI9 since the last build. **Mitigation:** rebuild on a regular cadence (the `Container Build and Push` workflow already does this on every tagged release).

### 2. OpenShift CLI (`oc`), Go binary (partially fixable)

The `oc` binary ships pre-compiled with its own Go runtime and a vendored set of Go modules (`runc`, `containerd`, `sigstore`, `golang.org/x/crypto`, `golang.org/x/net`, plus the Go stdlib). Most advisories against the image are inherited from this single binary.

**Mitigation:** bump `OC_VERSION` in the Containerfile when Red Hat ships a new `oc` release with updated dependencies. We can't patch the embedded modules ourselves without forking and recompiling `oc`, which is not on the table.

### 3. omc (must-gather offline tool), Go binary (not fixable by us)

`omc` is a third-party tool from [github.com/gmeghnag/omc](https://github.com/gmeghnag/omc), shipped pre-compiled with its own Go runtime and dependencies (grpc, otel, oauth2, mapstructure, k8s.io/kubernetes, etc.). Some of those dependencies carry critical CVEs; we cannot patch them without an upstream `omc` release.

**Risk assessment for the project:**

- `omc` runs as non-root (UID 1001)
- `omc` only reads local files (must-gather archives), no network listeners
- `omc` is only invoked when the user passes `--must-gather` (offline mode)
- No user input from the web UI or API flows through `omc`

**Mitigations:**

1. Monitor [omc releases](https://github.com/gmeghnag/omc/releases) for dependency bumps
2. Open upstream issues when a high-severity advisory hits one of its dependencies
3. If your environment requires zero critical CVEs in shipped images, build the container without `omc` (remove the omc install step from the Containerfile). The cost is losing offline must-gather mode; everything else still works.

## Build Practices

- **Base image:** `registry.access.redhat.com/ubi9/ubi-minimal:latest` (Red Hat supported, receives regular security patches)
- **Non-root execution:** Application runs as UID 1001, never as root
- **Minimal attack surface:** UBI-minimal base, `--nodocs` installs, no unnecessary packages
- **Automated scanning:** Trivy runs on every CI build, results uploaded to GitHub Security tab
- **SBOM generation:** SPDX SBOM generated on every release build
- **No secrets in image:** All credentials are mounted at runtime via volumes

## Network Egress

SSDG does not phone home. There is no analytics or telemetry. The only outbound HTTP the server makes is from `generators/client_info.py`, which performs two optional lookups when filling in the auto-generated engagement summary:

- DuckDuckGo Instant Answer API (`api.duckduckgo.com`), searched by company name.
- Wikipedia REST API (`<lang>.wikipedia.org`), searched by company name in the document language.

The dashboard additionally shows a small update badge when a newer release exists. That check runs in the operator's **browser**, not in the SSDG server: the browser fetches the release list of the public `elastocera/releases` repo on `api.github.com` (anonymous, cached for 6 hours in localStorage, nothing about the cluster is sent). On an air-gapped bastion the fetch fails silently and the badge never appears. A regression test (`tests/test_update_badge.py`) fails if anyone moves this call into Python.

Both lookups send only what the operator typed in `--client` and `--company-website`. No cluster data, no kubeconfig content, no tokens. Both are best-effort and silently fall back to an empty engagement section on timeout, rate limit, or block. An air-gapped operator can disable them by passing `--company-description` explicitly (or by simply running without DNS; the timeouts are short).

The topology diagram (Alfa, off by default) makes no network call either. The image bundles d2 v0.9.0, which draws the SVG and the PDF's PNG with its own renderer (checked under `podman run --network none`): no headless browser to download, no font to fetch, the fonts ship in `fonts/`. The stencils ship in the image or come from a local override directory, and before d2 runs SSDG refuses any diagram source with an icon outside the icons directory next to it, a link or an import. asciidoctor-pdf reads local files only and runs in safe mode with `--base-dir` set to the document's directory. That jail covers `include::` and where the PDF is written. It does not cover images: an image macro with an absolute path still reads any image the process can read, which is how a `--logo` outside the document's directory keeps working. The catch is `/api/convert-pdf`, where an authenticated upload can embed any image the SSDG process can read by giving its absolute path, another job's diagram PNG under `output/jobs/` included. The document no longer points anyone at play.d2lang.com.

## Tell Me Everything output

Tell Me Everything (off by default) is a second path out of the cluster, next to the document. It runs its own `oc get` (or `omc`, offline) for the namespaces, the OLM subscriptions and, in each user namespace, Deployments, StatefulSets, DaemonSets, Pods, PVCs, Services, Routes, Secrets and ConfigMaps. It writes `<name>-discovery/` and `<name>-discovery-tme.zip`, which the GUI and `/api/jobs` serve for download.

What it ships: names, types, counts, phases, replica counts, container images, node names, Service ClusterIPs and ports, Route hosts and TLS termination, PVC classes and sizes, and namespace labels.

- Namespace labels and annotations go through the same Sanitizer as the document before any file is written, so a `db-password=...` label comes out as `***REDACTED*** (length: N)`.
- Secrets and ConfigMaps ship as name, type and key count. The values are in the `oc get` output and stop in the walker.
- Annotations, environment variables and container args are never rendered.
- The rest is not sanitized: image references, Route hosts and IPs come out as the cluster has them, as they do in the document. Read the zip before you attach it to a ticket.

On disk, every file goes to a temp name and is renamed into place, so a link planted at a TME name is replaced, not written through. A `<name>-discovery` that is a link, or belongs to another user, is refused and the run carries on without TME. A namespace name that is not a DNS-1123 label (only an offline must-gather can carry one) gets no file. The zip takes TME's own file names only, opened with `O_NOFOLLOW`.

## Reporting a Vulnerability

If you find a security issue in our application code, please do **not** open a public GitHub issue. We need a chance to ship a fix before the details are public.

The supported channels, in order of preference:

1. GitHub's private vulnerability reporting on this repo (`Security` tab > `Report a vulnerability`). This creates a private advisory and lets us coordinate the fix without leaking details.
2. Email `security@elastocera.com` (PGP key on request) if GitHub is not an option.

What helps us triage quickly:

- The version (commit SHA or release tag) you tested against.
- Steps to reproduce, ideally a minimal proof of concept.
- The impact you believe it has (read-only data leak, RCE, auth bypass, denial of service).
- Whether the issue is in our code, in the container image we ship (`oc`/`omc`/UBI), or in a Python dependency. Upstream issues we will redirect to the right project.

What you can expect from us:

- Acknowledgement within 5 business days.
- An initial assessment within 10 business days.
- A patched release before disclosure when we have a fix. Critical issues take priority over the regular release cadence.
- Credit in the release notes if you want it.

For vulnerabilities in upstream dependencies (oc, omc, UBI9 packages, Python libs from `requirements.txt`), please report directly to the upstream project. We track upstream advisories via Dependabot and Trivy and rebuild when fixes ship.

## Supported Versions

Only the latest tagged release receives security updates. The `main` branch tracks ongoing development and is not considered a "supported" release.

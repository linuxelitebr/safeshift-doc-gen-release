<!-- SPDX-License-Identifier: Apache-2.0 -->

# Privacy and Data-Handling Posture

This document describes how SafeShift Doc Gen (SSDG) treats data. It is the technical answer to "what does the tool do with my cluster information". The compliance question (LGPD, GDPR, HIPAA, sector regulations) is downstream of this and is the operator's call. See the disclaimer at the bottom.

For the network egress summary, see also `docs/SECURITY.md` § Network Egress.

## Data-handling model

SSDG runs in three modes. The data path is similar in each; the persistence point differs.

**CLI on a laptop** (`python3 cli.py ...`)

Operator runs SSDG from a shell. Authentication uses the operator's existing kubeconfig (`~/.kube/config`). SSDG reads cluster resources via the `oc` binary, processes them in-process, and writes the deliverable to `./output/`. The operator's filesystem is the persistence boundary.

**`ssdg --web` on a laptop**

The Go launcher binary spawns the container with a Flask UI on the port `--port` picks (5000 by default). Same data path as the CLI, with two differences. No host kubeconfig goes in: the operator logs in from the dashboard, which writes a 0600 kubeconfig inside the container. And the output directory is a tmpfs mount inside the container, not a host directory: the `.adoc`, the PDF, the diagram files and the TME zip leave only through the dashboard's download buttons, and vanish when the container stops. Logo uploads from the dashboard live in tmpfs only.

**Container deployed in an OpenShift pod**

For automation. Manifests in `deploy/openshift/` create a ServiceAccount with a tight read-only ClusterRole. Authentication is opt-in: the dashboard refuses to use the pod's in-cluster ServiceAccount token until the operator clicks "Use this cluster's ServiceAccount". Outputs land in an `emptyDir` by default (ephemeral, lost on pod restart) or a PVC if mounted (operator's choice; persists past restart).

Data flow, all three modes:

```
Source cluster -> oc CLI -> SSDG collectors -> Sanitizer
   -> Jinja2 templates -> AsciiDoc file
   -> (optional) asciidoctor-pdf -> PDF file
```

The sanitizer runs before the templates, not after. Generated documents do not contain values the sanitizer caught.

With Tell Me Everything on (off by default) there is a second path, next to the document:

```
Source cluster -> oc CLI -> TME walkers -> Sanitizer (namespace labels and annotations)
   -> Markdown files in <name>-discovery/ -> <name>-discovery-tme.zip
```

TME keeps a narrower set of fields than the collectors: names, counts, status, images, IPs, Route hosts and namespace labels. Only the labels and annotations go through the sanitizer, since nothing else it keeps is free text. Secret and ConfigMap values stop in the walker, which keeps name, type and key count; annotations, env and args are never rendered. See `docs/SECURITY.md` § Tell Me Everything output.

## What SSDG does NOT do

- No telemetry or analytics, and the server never checks for updates. The dashboard's version pill is the one exception, and it runs in the browser: it reads the public release list of `elastocera/releases` from the GitHub API, sends nothing of the cluster, and on an air-gapped network it just stays neutral
- No persistent log shipping; the runtime logger streams to stdout / SSE only
- No external data store, database, or registry of past runs
- No multi-tenant sharing of generated documents; one operator, one run, one file
- No storage of customer credentials. The kubeconfig stays wherever the operating system put it

## What SSDG DOES that is worth flagging

Two surfaces send data outside the operator's machine. Both are limited and documented.

**Engagement enrichment lookup** (`generators/client_info.py`)

When the operator does not supply `--company-description`, SSDG asks two public APIs to fill in a one-paragraph description of the customer for the cover page:

- DuckDuckGo Instant Answer API (`api.duckduckgo.com`)
- Wikipedia REST API (`<lang>.wikipedia.org`)

The query is the customer name the operator typed (`--client` flag). Nothing else leaves the machine. To disable: pass `--company-description "..."` explicitly, or run on an air-gapped network where these endpoints are unreachable (the call has a short timeout and silently falls back).

**Asciidoctor PDF rendering**

If `--pdf` is requested, SSDG invokes the bundled `asciidoctor-pdf` ruby tool locally. The PDF is produced in tmpfs and written to the same output directory as the AsciiDoc file. No network call.

## Sanitization scope

`processors/sanitizer.py` redacts based on regex patterns and a denylist of field names. What it covers:

- Bearer tokens (regex)
- JSON Web Tokens (three-segment dot-separated)
- SSH private keys (`BEGIN RSA PRIVATE KEY`, ED25519, DSA)
- PEM private key blocks generally
- OAuth client secrets
- Field names matching `token`, `password`, `client-secret`, `Authorization`, and similar known-sensitive keys

What the sanitizer does NOT cover:

- Free-text annotations and labels written by operators. If a customer puts `owner: joao@acme.com` in a namespace annotation, it appears verbatim in the deliverable. TME prints namespace labels too: a credential-shaped one is masked, an email address is not.
- Custom Resource fields that the sanitizer has no pattern for (operator-defined CRDs with PII).
- Cluster naming conventions that encode customer or project information (the document shows the cluster name as is).
- Inline comments in YAML manifests collected from the cluster.

This is a real limit, not a footnote. Sanitizer-as-regex catches known classes; it cannot guess novel patterns. Reviewers of the generated document remain the last line of defense.

## Token and credential handling

- Kubeconfig staged from the host: copied into `os.MkdirTemp` with mode 0600 and removed on exit. The staging is required because rootless podman's user-namespace remap leaves the host kubeconfig unreadable from inside the container.
- ACM batch mode creates a temporary `ManagedServiceAccount` on each imported managed cluster. TTL is one hour, rotation enabled, cleaned up in a `finally` block.
- Per-cluster kubeconfigs synthesized during a batch run are written 0600 and removed after the cluster's document is generated.
- App boot adopts a sentinel kubeconfig pointing at `127.0.0.1:1` so the dashboard cannot silently inherit the pod's in-cluster ServiceAccount token. Login is explicit.
- `SSDG_AUTH_TOKEN` minimum length is enforced at app boot: 32 characters or the pod refuses to start. The Go launcher (`32-byte hex` per run) and `deploy/openshift/install.sh` (`openssl rand -hex 32`) both produce 64-char tokens, so only a hand-rolled Secret with a weak value will trip this. The brute-force surface a rate limiter would mitigate is removed by the entropy requirement itself.

### Failed-auth log (LGPD-aware)

Every rejected token presentation produces one structured WARNING in the application log: `auth.failed reason=<...> client=<...> path=<...>`. The `client` field carries one of three values depending on the `SSDG_LOG_FAILED_AUTH` env var:

| Mode | Value logged | When to choose it |
|---|---|---|
| `hash` (default) | `h:` + first 8 hex chars of `SHA256(client_ip)` | The general case. Lets a SIEM correlate repeated tries from one client without identifying the person. Pseudonymization counts as minimization under LGPD Art. 6, IX. |
| `full` | Raw client IP (honors `X-Forwarded-For` first entry) | Operator has a stronger legal basis (regulated SIEM with formal RoPA entry, contractual obligation with the customer) and wants the raw signal. Explicit opt-in. |
| `off` | Nothing logged | Operator has a different observability path or has decided not to retain the signal at all. |

Base legal: legítimo interesse (LGPD Art. 7, IX). Security event logging is the example case cited by ANPD guidance and GDPR Recital 49. The operator is the data controller; SSDG is the processor providing the technical mechanism.

Retention guidance: 30 to 90 days is what most SIEMs run with in practice for auth event logs. The runtime logger writes to stdout, so the actual retention is whatever the container log driver and the operator's SIEM policy enforce. SSDG does not persist the log itself.

The successful-auth path does NOT log the IP. Only failures.

## Privacy-by-design properties

- Local-first artifact. The `.adoc` and `.pdf` land on the operator's disk. SSDG does not push them anywhere.
- No federated auth surface. `SSDG_AUTH_TOKEN` is a shared secret intended for a single operator's session; not OIDC, not a multi-user identity system.
- MSA tokens are time-bounded and self-cleaning.
- Sanitizer runs before template rendering, so the redacted form is what reaches Jinja2.
- Container image is reproducible (SBOM published per release, Trivy-scanned).

## Honest caveats

- The artifact persists on the operator's disk after generation. SSDG does not delete it. Lifecycle is the operator's responsibility.
- The operator's kubeconfig is the source of authority. If the kubeconfig carries cluster-admin RBAC, SSDG reads everything the cluster will return. Use the deploy/openshift/ ServiceAccount + read-only ClusterRole for tighter access.
- Sanitizer is pattern-based. Novel customer naming conventions or operator-defined PII fields can slip through. Review the deliverable before sharing.
- In pod mode with a PVC, deliverables persist across pod restarts. Operator decides the retention.
- DuckDuckGo and Wikipedia receive the customer name as a search query when `client_info.py` runs without `--company-description`. This is outbound HTTP to third parties governed by their own privacy policies.
- The runtime logger writes to stdout and to the SSE stream consumed by the dashboard. Container logging drivers (Kubernetes node logs, journald) capture stdout. Operator's log retention policy applies to that downstream.
- Browser memory can be swapped to disk under low-memory conditions. Browser extensions can read page memory. Both are outside SSDG's control and apply to any web tool.

## Operator responsibilities

The consultant, team, or service running SSDG is the data controller for the documents the tool produces. SSDG is the tooling, not the legal hat.

- Verify there is a base legal ground (contract, consent, legitimate interest) for processing the customer's cluster data.
- Maintain a Data Processing Agreement with the customer covering the engagement, when required by jurisdiction.
- Decide the retention policy for the generated deliverables: where they live, how long, who can access.
- Note the cluster's jurisdiction when running in cross-region ACM scenarios. Data residency rules may apply to the source cluster even when the documents are produced elsewhere.
- Maintain endpoint baseline on the host running SSDG (disk encryption, screen lock, OS patching). The tool cannot enforce this; it relies on the host being trustworthy.
- Document the SSDG run in the engagement's records of processing when local law requires it (Brazil's LGPD `relatório de impacto`, GDPR's `RoPA`, etc.).

## How to report a privacy concern

Same channels as for security vulnerabilities, see `docs/SECURITY.md` § Reporting a Vulnerability:

1. GitHub private vulnerability reporting on this repo (Security tab > Report a vulnerability).
2. Email `security@elastocera.com` (PGP key on request) if GitHub is not an option.

Privacy concerns and security concerns share the triage queue. Either disclosure path is fine.

## Disclaimer

This document is not legal advice. It describes the architecture and posture of SafeShift Doc Gen at the time of writing. Compliance decisions (LGPD, GDPR, HIPAA, sector-specific frameworks) are the responsibility of the operator's legal counsel, Data Protection Officer, or compliance function. Cite this document if it helps your assessment; do not treat it as a conformance claim.

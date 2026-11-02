# Features & Collectors Reference

## Architecture

SafeShift Doc Gen is a modular, containerized tool that automates OpenShift cluster documentation in AsciiDoc format.

### Core Components

| Component | Description |
|-----------|-------------|
| `OCClient` | Wrapper for `oc` and `omc` CLI operations |
| `BaseCollector` | Abstract base class for all data collectors |
| `Sanitizer` | Masks sensitive data (passwords, tokens, certificates) |
| `AsciiDocGenerator` | Jinja2-based template engine with custom filters |
| `OCPDocGenerator` | Main orchestrator with parallel collection support |

### Extension Pattern

To add a new collector:

1. Create a collector class in `collectors/` extending `BaseCollector`
2. No registration needed: auto-discovery picks it up at import time
3. Create a Jinja2 template in `templates/sections/`
4. Add i18n keys in `i18n/pt_BR.yaml`, `i18n/en_US.yaml`, `i18n/es_ES.yaml`

---

## Collectors

### Cluster

Collects core cluster information:
- OpenShift version, channel, update status
- Platform type (BareMetal, AWS, Azure, GCP, etc.)
- API server and console URLs
- Infrastructure and install configuration

### Nodes

Detailed node inventory:
- Hardware specs: CPU, RAM, storage per node
- Roles, conditions, taints, labels
- Machine sets and machine config pools

### Bare Metal Hosts

Only when the cluster has BareMetalHosts or a Provisioning (metal3):
- Per host: the node and Machine it backs, the BMC type from the address scheme (redfish, idrac-virtualmedia, ilo5, ipmi and so on), whether metal3 verified the BMC credentials, provisioning state, operational status, power, externally provisioned, boot mode, automated cleaning, inspection, RAID and firmware knobs when set, and the last error
- Hardware from inspection (status.hardware or HardwareData): system, CPU, RAM, NICs and their speeds, disks with total size and type, BIOS
- BMC fencing per host: yes only with verified BMC credentials and a MachineHealthCheck that remediates through a Metal3RemediationTemplate; could not be checked, never a guess either way, when the MachineHealthChecks, the Metal3RemediationTemplates or the Machines cannot be read
- Findings: hosts in error or not OK, BMC credentials not verified (rejected only when metal3 tried the current Secret and registration failed, pending while a rotation is in flight), no BMC, registered but never reconciled, automated cleaning that wipes the disks on deprovisioning, BMC TLS not verified
- BMC, NIC and provisioning network addresses only with `detailed_network_state`; MAC addresses, serial numbers and credentials Secret names never, not even in the collected data
- With a Node Health Check operator installed, a NodeHealthCheck that fences the node through Fence Agents Remediation (FAR), with the node's parameters in the template, counts as BMC fencing too, ahead of the BareMetalHost's own BMC and login: FAR logs in with its own settings. One that remediates through a Metal3RemediationTemplate needs what the MachineHealthCheck route needs. SNR and MDR answer no, with their own reason
- Disk counts take one entry per device: a Fibre Channel LUN that Ironic lists as its dm map and once per path is one disk, and the floppy and CD/DVD drives the BMC fakes for virtual media are not disks at all

### Node Health Check and Remediation

Only when a Node Health Check, Self Node Remediation, Fence Agents Remediation or Machine Deletion Remediation operator is installed (the Workload Availability operators), right after the bare metal chapter. Configuration only, enough to set it up again, plus whether each node can be fenced:
- Operators with version, CSV phase and namespace; the ones missing say "not installed"
- Each NodeHealthCheck: the selector in words, nodes observed and healthy, the unhealthy conditions, minHealthy or maxUnhealthy and how many nodes that lets it remediate at once at the current count (NHC rounds a percentage up, so 51% of 3 nodes is one at a time), the remediation template or the escalation order with timeouts, healthyDelay, stormCooldownDuration, pause requests, and the status with the reason when it is disabled
- Coverage per node: the checks that select it, what remediates it in what order, and whether that fences it through a BMC. FAR counts only with the node's own parameters in the template; SNR reboots the node from inside and MDR deletes its Machine, so neither is fencing; Metal3 depends on the BareMetalHost, which the bare metal chapter answers
- FenceAgentsRemediationTemplates as setting and value: agent, remediation strategy, every shared and per-node parameter, retries, interval, timeout, and the names of the credential Secrets. `--action off` gets a line of its own: the node stays off after fencing until somebody powers it on
- SelfNodeRemediationConfig settings, the SNR templates with their strategy and which one is the default, and how many SNR agents are ready; one line when SNR is installed and no NodeHealthCheck uses it. MDR templates, and the Metal3RemediationTemplates a NodeHealthCheck names
- Findings: a disabled check and why, a template that does not exist, a node in more than one check, a node selected for FAR with neither a node parameter nor a node Secret, minHealthy or maxUnhealthy that let a check remediate no node at all, credentials in clear in a FAR template, `--ssl-insecure`, SNR agents short of the nodes SNR covers, and remediations in progress
- FAR parameter values that look like credentials (pass, secret, token, key, kg, community, username, login, `-p`, `-l`) never, not even in the collected data; per-node values and shared addresses only with `detailed_network_state`. Secrets are never read, not even to see whether the ones the templates name exist

### Network

Network infrastructure:
- Ingress controllers and routes
- NetworkPolicies and EgressIPs
- Cluster network type (OVNKubernetes, OpenShiftSDN)

### Storage

Storage subsystem:
- StorageClasses: the cluster default and the default for VMs, volume expansion, binding mode, reclaim policy
- PersistentVolumes: per StorageClass the count, the allocated capacity (what the cluster reserved, not what the backend stores) and the access / volume mode mix
- CSI drivers: vendor, StorageClasses, snapshot support, CSIDriver settings, nodes with the node plugin
- Provisioners with no CSIDriver object (NFS provisioner pods, in-tree plugins), listed apart from CSI
- Object bucket provisioners (NooBaa, Rook/ODF RGW), listed apart from both and kept out of the VM disk tables
- VolumeSnapshotClasses
- With OpenShift Virtualization: the CDI claim property sets per StorageClass, the one a VM disk gets by default, and whether that disk can live-migrate
- With OpenShift Virtualization: CDI's scratch space StorageClass, the filesystem overhead (global and per class) and whether an importer proxy is set, without its URL
- LVM Storage (LVMS): device classes, the disks they select and use per node, thin pool config, the virtual free capacity per node (CSIStorageCapacity) next to the real thin pool usage from the TopoLVM metrics, and findings on overprovisioning, overcommitted and nearly full thin pools
- Upstream Rook Ceph (no ODF StorageCluster, any namespace): phase, health and its checks, version, mons, OSDs, raw capacity, pools with replica or EC and failure domain, flagged as outside Red Hat support, with single-copy pools called out

### Auth

Authentication and authorization:
- Identity providers (LDAP, HTPasswd, OIDC, etc.)
- OAuth configuration
- Security Context Constraints (SCCs)

### Monitoring

Monitoring stack configuration:
- `cluster-monitoring-config` ConfigMap
- User workload monitoring status
- PrometheusRules, ServiceMonitors
- Component configs (Prometheus, Alertmanager, KubeStateMetrics)

### Logging

Logging stack details:
- Red Hat OpenShift Logging and Loki Operator (versions, status)
- LokiStack: size, storage (S3), schemas, replication factor
- ClusterLogging and ClusterLogForwarder configurations
- S3 storage secrets (keys listed, values REDACTED)

### Operators

Installed operators:
- ClusterServiceVersions (CSVs) with status
- Subscriptions and install plans
- Operator groups

### ACM (Advanced Cluster Management)

If installed:
- MultiClusterHub status and observability
- Managed clusters inventory
- Policies and applications

### Multicluster Engine (MCE)

Lightweight multicluster management:
- MCE version and component status
- **Managed Clusters**: type (Hub/Hosted/Imported), platform, versions, capacity, health conditions
- **Infrastructure/Host Inventory**: CPU architecture, NMState config, agent details
- **Bare Metal Agents**: system info, CPU/memory/storage/network details per agent
- **Cluster Deployments**: base domain, platform, install status, power state
- **Add-ons**: global and per-cluster managed add-ons

### Hosted Control Planes (HyperShift)

If HyperShift is deployed:
- **HostedClusters**: namespace, version, status conditions
- **HostedControlPlanes**: platform config, networking (cluster/service networks)
- **NodePools**: replicas, scaling config, platform-specific settings
- **ConfigMaps**: associated MachineConfig and KubeletConfig
- Supported platforms: Agent (BareMetal), AWS, Azure, PowerVS, KubeVirt

### Certificates

Certificate analysis:
- Cluster certificates and expiration dates
- Custom certificates

### MachineConfig

Machine configuration:
- MachineConfigPools and custom MachineConfigs
- KubeletConfig (maxPods, reservations, eviction)
- ContainerRuntimeConfig (pidsLimit, logLevel, overlaySize)

### Backup

Backup infrastructure:
- OADP/Velero status and configuration

### Policies

Governance policies (ACM):
- Policy definitions and compliance status

### Feature Operators

NMState and MetalLB:
- **NMState**: instances, NodeNetworkConfigurationPolicies (NNCP), state reports
- **MetalLB**: instances, IPAddressPools, L2/BGP advertisements

### Quay

Quay registry instances detected on the cluster:
- QuayRegistry CRs, version, status
- Storage backend configuration
- Component status (mirror, clair, quay, postgres)

### CronJobs

Custom Day-2 automation CronJobs across the cluster:
- Name, namespace, schedule, concurrency policy
- Last schedule time, active jobs
- Container image and command

### Additional Collectors

- **Virtualization**: OpenShift Virtualization status and VMs
- **Serverless**: OpenShift Serverless (Knative) configuration
- **Pipelines**: OpenShift Pipelines (Tekton) status
- **GitOps**: OpenShift GitOps (ArgoCD) configuration
- **Service Mesh**: OpenShift Service Mesh status
- **Console Notifications**: ConsoleNotification banners

### Migration Toolkit for Virtualization (MTV)

Only when the cluster runs MTV, right after OpenShift Virtualization. It does not need local CNV: a hub can migrate every VM into other clusters. The chapter says how MTV is set up and whether it works, enough to install it again; how the migrations went is not part of it, and no Migration object is read.
- Operator version and CSV phase, the Subscription that installed it (package, channel, catalog, update approval, starting CSV) and the ForkliftController state
- ForkliftController settings: every key the spec sets, with its value. Keys SSDG does not know print by name, their values marked as not copied. Nothing is compared on the page; the MTV 2.11.7 defaults only feed the findings (a number given as a string that the operator most likely ignores, debug flags left on)
- Providers with type, readiness and the plans that name them; the vSphere VDDK image (said once when every provider uses the same one), AIO, SDK endpoint and whether a custom vddkConfig is set; ESXi Host objects
- Network mappings per destination (NADs and their namespaces, pod network, ignored), storage mappings per destination and storage class with volume and access mode and copy offload, and the not-ready maps an active plan uses
- Hooks per step, image and service account, how many carry a playbook (base64 in the Hook object, not encrypted) and how many hand the job to AAP
- Plans: totals by state and type, the options that vary between plans (counted only on plans where they do something) and the ones that do not, the PVC name templates, and the active plans with their state
- Findings, critical and warning only: ForkliftController not ready, inventory API without authentication, validation off, numeric settings given as strings, debug settings left on, providers not ready (split by whether an active plan waits on them), TLS verification skipped, vSphere without VDDK, active plans that cannot start, not-ready maps that active plans use
- Provider endpoints, ESXi Host addresses and addresses inside error messages only with `detailed_network_state`; Secret names, provider URL paths and user info, TLS fingerprints, vddkConfig text, playbooks and AAP settings never, not even in the collected data
- With the MTV CSV installed and no ForkliftController to show, one paragraph says why: none exists, the controllers could not be read, or the must-gather SSDG read has no MTV objects. The standard must-gather collects none (the preface lists the gap), and the MTV must-gather packs them in a layout SSDG cannot read yet

---

## Web Interface

SSDG ships with a **Flask + PatternFly 6** web interface served on port 5000 (launched with `--web`). Four pages:

| Page | Purpose |
|------|---------|
| **Dashboard** | Cluster connection card, status metrics, quick actions |
| **Generate** | Configure and run single-cluster or ACM Batch generation |
| **Convert to PDF** | Upload an existing AsciiDoc file and render it in the look of the document identity chosen in Settings |
| **Settings** | Config file, output directory, must-gather path, verbose logging, document identity (the brand pack), interface language (persisted to localStorage) |

**Interface i18n**: the web UI itself is fully translated (pt_BR, en_US, es_ES). Language detection order: `?lang=` query param, then `ssdg_ui_lang` cookie, then browser `Accept-Language`, then default `pt_BR`.

**Real-time log console**: Server-Sent Events stream every backend log line to a resizable footer console.

**Theming**: Dark (default) and light, toggleable via the masthead, persisted in localStorage. The log console intentionally stays dark regardless of theme (terminal aesthetic).

**About modal**: project logo, version, author, GitHub link and license. Theme-aware (dark or light background with matching text).

**OpenShift-aware**: when running as a pod, the Flask app auto-detects `/var/run/secrets/kubernetes.io/serviceaccount/token` at startup and runs `oc login` automatically. The Cluster Connection card shows the pod's ServiceAccount identity without any manual input.

---

## ACM Batch Mode

When launched against an ACM Hub cluster, `--acm-batch` documents every managed cluster in a single run:

1. Discovers managed clusters from `ManagedCluster` CRs on the Hub
2. For each managed cluster, provisions a temporary **read-only** ServiceAccount on the remote cluster using `ManagedServiceAccount` + `ManifestWork` (auto-cleanup at the end)
3. Collects data from the remote cluster using the obtained token
4. Generates one AsciiDoc/PDF document per cluster
5. Optional `--include-hub` also documents the Hub itself

The same workflow is available in the web interface via the **Operation Mode** section on the Generate page.

See [docs/ACM-BATCH-MODE.md](ACM-BATCH-MODE.md) for RBAC scope, security, and troubleshooting.

---

## OpenShift-native deployment

Ready-to-apply manifests under [`deploy/openshift/`](../deploy/openshift/):

- `00-namespace.yaml` through `05-route.yaml` (numeric prefix for ordered `oc apply`)
- Dedicated ServiceAccount with a wildcard read-only ClusterRole (get/list/watch on every API group) plus narrowly-scoped write on `ManagedServiceAccount` and `ManifestWork` for ACM Batch Mode
- PVC for persistent output, Deployment with readiness/liveness probes on `/api/health`, Service, edge-TLS Route

Apply:

```bash
oc apply -f deploy/openshift/
```

Full documentation: [deploy/openshift/README.md](../deploy/openshift/README.md).

---

## Document Generation

### Cover Page & Preface

Professional documents include:
- **Cover**: client name/logo, Red Hat Consulting branding, engagement description, version
- **Preface**: confidentiality notice, copyright, target audience, related documents
- **Engagement Description**: auto-generated from detected products (Virtualization, GitOps, ACM, etc.)

Use `--no-cover` or `--no-preface` to disable.

### Concepts used in this document

Every document that renders at least one linked chapter gets a short chapter after the brand pack's methodology chapter (or after the executive summary when the pack has none), before Cluster. Three sentences on what OpenShift is and on this document describing this cluster, not OpenShift in general, then a table: term, what it is, and the chapter where it appears, as a link. There is no flag to turn it off. It costs a page or two and answers "what is a MachineConfigPool" before someone asks it in the meeting.

Only terms whose chapter made it into the document show up: a cluster without virtualization gets no live migration, without ODF no Ceph, without bare metal no BMC. A few terms look closer than the chapter: infra node needs a node with the infra role, RHCOS a CoreOS node image, OVN-Kubernetes that network type, NMState and MetalLB their own operator. The 28 terms and the chapters they point at live in `processors/glossary.py`; the one-line definitions live under `templates.sections.concepts.terms` in the three i18n files.

The links need ids that do not move. AsciiDoc derives a section id from its title, and the titles are translated, so every top-level chapter in `templates/main.adoc.j2` carries `[[ssdg-<chapter>]]` on the line above its heading. The anchors print nothing. Add a chapter and give it one, `tests/test_chapter_anchors.py` insists. Change a chapter's `{% if %}` and change its copy in `glossary.CHAPTERS` too, `tests/test_glossary.py` fails until you do.

### PDF Generation

Add `--pdf` to the run:

```bash
python3 cli.py --client "Acme Corp" --output output/acme.adoc --pdf
```

Every path that builds a PDF (CLI, web UI, `/api/convert-pdf`, `/api/jobs`, ACM batch, the `ssdg` launcher) goes through `utils/pdf_render.py`: asciidoctor-pdf in safe mode, jailed to the document's directory with `--base-dir` (the jail covers `include::` and the output path; an image referenced by absolute path is still read, see docs/SECURITY.md), the brand pack's theme and the bundled fonts (see [BRAND_PACKS.md](BRAND_PACKS.md)). Without `--pdf` the CLI prints the exact command, so a manual conversion matches, and `--pdf-only FILE` converts a document that already exists the same way. The `ssdg` launcher keeps the PDF the CLI made inside the container, and its `--pdf-only` runs the CLI's. It used to convert a second time on its own, with the Red Hat theme, no safe mode and no diagram check, and write over the first PDF.

See [PDF_GENERATION_GUIDE.md](PDF_GENERATION_GUIDE.md) for theme customization, font setup and the manual command.

### Topology diagram (Alfa)

Off by default. Turn it on with `--diagram`, the Settings toggle, `features.diagram_d2_enabled` in the config, or `diagram_d2_enabled` on `/api/jobs`. SSDG then draws the cluster offline with the d2 CLI the container ships (d2 v0.9.0): nothing is uploaded, no icon is fetched. Next to the document you get:

- `<doc>.topology.d2` and `<doc>.topology.svg`, the cluster: node cards, network lanes, users, load balancer, storage drivers, fleet members.
- `<doc>.network.d2` and `<doc>.network.svg`, the Node Network Design, when `detailed_network_state` is on too: per group of nodes with the same config, the NICs, Linux and OVS bonds, VLANs, bridges and the patch links between OVS bridges, up to the machine network and the default gateway. Every hop is a card with an icon tile, VLAN and tagged patch ports are the purple ones, the data path is red, and a one-row legend at the bottom explains what the page shows.
- `<doc>.diagram-icons/`, the stencils the `.d2` files reference by relative path.
- With a client logo, both diagrams carry it in the bottom-right corner, boxed to 180 x 60 px with its proportions kept, from a re-encoded copy (`client-logo.png` or a scrubbed `client-logo.svg`) in the same icons directory; the zip carries it too, and it never appears in the icon credits.
- `<doc>.diagrams.zip`, all of the above plus ATTRIBUTION.txt and the license texts, ready to unzip and render again with `d2 --layout=elk`.

Without d2 on PATH (a source checkout without it) only the `.d2` files and the zip are written, and the document says how to render them. `detailed_virtual_machines` names up to 6 VMs per node on the diagram, and node IPs only show with `detailed_network_state`, so the diagram never shows more than the document does. The GUI, the ACM batch list and `/api/jobs` (`format=topology-svg` and friends) serve the files.

`--diagram-embed` (`diagram_d2_embed`) also puts the diagrams in the PDF, each on an A4 landscape page, and closes the document with an icon credits chapter carrying the full icon licenses. It turns the diagram on by itself. See [PDF_GENERATION_GUIDE.md](PDF_GENERATION_GUIDE.md#diagrams-in-the-pdf-alfa) for what a conversion checks, and [diagram-icons.md](diagram-icons.md) for the stencils, your own vendor logos and the credits.

Each run deletes the diagram files an earlier run left for the same document name before it collects anything, and fails right there if one of them cannot be removed. `diagram.render_timeout` (5 to 600 seconds, default 60) caps each render.

### Tell Me Everything (TME)

Off by default. Turn it on with `--tme` (the `ssdg` launcher passes it on), the Settings toggle, `features.tell_me_everything` in the config, or `tell_me_everything` on `/api/jobs`. After the collectors run, TME walks the namespaces, the OLM subscriptions and each user namespace's workloads through the same oc client (or omc, offline) and writes, next to the document:

- `<name>-discovery/`, one Markdown file per topic: the overview, OLM subscriptions, system namespaces, the user namespace index, one file per user namespace, and the anomalies.
- `<name>-discovery-tme.zip`, that directory zipped as its single top folder, so unzipping it gives you `<name>-discovery/` back.

`<name>` is the document name without its language suffix. The CLI, the GUI, the ACM batch, `/api/jobs` and the launcher all land on the same names: `acme-corp-2026-10-15.adoc` and `acme-corp-2026-10-15.pt_BR.adoc` both get `acme-corp-2026-10-15-discovery/`. The catch: a pt_BR and an es_ES run of the same document share one TME directory, and the later run wins.

To get it out of the GUI, tick Tell Me Everything under Settings, Experimental features, run, and download "TME discovery (ZIP)" from the results list, next to the document and the PDF. The ACM batch list carries one zip per cluster, `/api/jobs` serves it as `format=discovery`, and the CLI prints both paths at the end of the run. Under `ssdg --web` the download is the only way to it, since the launcher keeps the web UI's output in container RAM.

Each run deletes the zip and the TME files an earlier run left for the same name before it collects anything, TME on or off, so a run with TME off never shows an older zip as its own. A file TME did not write stays where it is and the log says so. The zip is only written when the walk succeeded; a failure is a warning and the document goes on without it. Secret values are never shipped: names, types and key counts only. See [COLLECTORS.md](COLLECTORS.md#discovery-sidecar-tme) for the tiers and the classifier.

### Multi-language Support

Three languages supported via `--lang`:
- `pt_BR` (default) - Portuguese (Brazil)
- `en_US` - English
- `es_ES` - Spanish

Output files include the language suffix: `cluster-doc.pt_BR.adoc`

### Data Sanitization

All sensitive data is automatically masked:
- Passwords, tokens, API keys - `***REDACTED***`
- Certificates - structure preserved, content masked
- S3/storage secrets - keys listed, values redacted
- Pattern-based regex rules in `processors/sanitizer.py`

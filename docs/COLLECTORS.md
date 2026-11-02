# Collectors

The 40 modules that make up an SSDG document, what each one captures, and how mature each one is. Use this page to decide whether the module you care about is ready to defend in front of a customer, or still in the "captures what it sees, no second opinion" tier.

## Maturity tiers

We classify each collector into one of three tiers, on facts that are easy to verify (tests in the suite, drift kinds emitted), not on adjectives.

- **audit-grade**: emits drift signals, has dedicated unit tests, has been validated end-to-end against a live cluster at least once. The output is something an auditor can act on, not just a snapshot. Today: ACM Hub Backup, CCLM, Descheduler, ODF, RHACS.
- **mature**: substantive collection logic and tests, but no dedicated drift detection. Useful for the customer doc, not yet wired into a "what is wrong" surface. Today: MCE.
- **inventory**: collects the resources, renders them, no dedicated tests. Exercised indirectly via integration runs against real clusters. Fine for "what does this cluster have" reporting. Most legacy modules sit here.

The tiers are not a value judgment. A cluster doc needs all three: the inventory modules describe the cluster, the mature modules add depth, and the audit-grade modules surface what to act on. The tier tells you where to expect rigor.

## The 40 modules

| Module | Tier | Tests | Drift kinds | Notes |
|---|---|---:|---:|---|
| `node_tuning` | audit-grade | 6 | 3 | PerformanceProfile + Tuned posture: CPU partition (reserved/isolated), hugepages, RT kernel, NUMA policy, per-node profiles.tuned applied state. Grounded live (lab-perf on a dedicated MCP, isolcpus verified in the kernel cmdline; BadMachineConfigLabels degraded shape captured). 1.8.x. |
| `upgrade_readiness` | audit-grade | 42 | 23 | Seventh audit-grade. Answers "if you upgrade tomorrow, what blows up". ClusterVersion conditions, deprecated APIs from APIRequestCount with named consumers, operator hygiene (Subscriptions/InstallPlans/CSVs), ClusterOperator state, MCP posture, node state. Cross-refs etcd backup posture via apply_cross_refs. 1.7.3 post-tag. |
| `etcd` | audit-grade | 75 | 24 | Sixth audit-grade. Member topology (3 or 5 on HA, single on SNO, external on hosted), disk IO p99 vs 10ms / 25ms SLOs, quota headroom, leader stability, db fragmentation, backup posture (cross-refs ACM Hub Backup; resolves the classic CronJob-to-NFS pattern's snapshot destination via PVC->PV or the inline mount, retention signal, and PrometheusRule alerting). Smoked live on ACM SNO, HyperShift hosted, and the HA lab cluster running the CronJob-to-NFS backup. 1.7.3 post-tag; backup storage audit in 1.8.x. |
| `acm_hub_backup` | audit-grade | 25 | 19 | ACM Hub Backup posture audit. Grounded in the Linux Elite five-part series. Detection gate MCH + BackupSchedule. Drift includes TLS off, MinIO in-cluster SPOF, useManagedServiceAccount disabled, five-schedules count mismatch, validation Policy NonCompliant. 1.7.3 post-tag. |
| `rhacs` | audit-grade | 24 | 14 | Red Hat Advanced Cluster Security. Both Central and SecuredCluster sides, topology classifier, fleet view via Prometheus telemetry. 1.7.3. |
| `compliance` | audit-grade | 27 | 13 | Compliance Operator, second `security` member. Reads the operator's own CRDs (no XCCDF parsing): ProfileBundles, ScanSettingBindings, suite results, the 1355-check rollup by status and FAIL-by-severity, named high-severity failures (capped at 25), remediation backlog. Severity maps to auditor action: high FAILs and broken scans are critical, NON-COMPLIANT is info (every cluster fails CIS day one). Live-validated across three lab clusters (5 bound frameworks on the hosting cluster, 4 on the others; handles the INCONSISTENT-vs-NON-COMPLIANT and orphaned-example variation between them). |
| `cclm` | audit-grade | 25 | 15 | Cross-Cluster Live Migration on RHACM hub. 1.7.1. |
| `descheduler` | audit-grade | 36 | 20 | Kube Descheduler on any cluster, pods first: what each active profile evicts, with the parameters from the rendered `DeschedulerPolicy`; the eviction rules read from where the operator actually puts them (top-level `nodeSelector` and limits, per-plugin namespace excludes, DefaultEvictor protections); the operator's Degraded conditions; and only the customizations an active profile reads. HyperConverged shows up only when a VM can be evicted (a KubeVirt profile, local-storage eviction next to OpenShift Virtualization, or VMs carrying `descheduler.alpha.kubernetes.io/evict`), and soft taints only when the operator deploys a softtainter. PSI shows up with a KubeVirt profile on 5.2+, or when a profile reads a pressure query. Drift is gated by profile family, CSV version (5.1 to 5.3) and the count of nodes a VM can run on. Profiles, policy parsing, the view and the drift live in `processors/descheduler_*.py`. The 109 tests (157 cases) sit in `tests/test_descheduler.py` and the four `tests/test_descheduler_*.py` files, on fixtures from a single-node 4.21 lab with operator 5.3.4. First shipped in 1.7.2. |
| `odf` | audit-grade | 19 | 4 | OpenShift Data Foundation. Prom + toolbox composite source, confidence tiers. 1.7.0. With no StorageCluster it hands upstream Rook CephClusters from any namespace, with their pool CRs, to the storage section (`processors/rook_ceph.py`). |
| `internal_registry` | mature | 30 | 19 | Closes the Quay gap (external only). emptyDir on HA (data loss), pruner posture (configured/suspended/never-succeeded/stale/failing), PVC capacity via Prometheus (70/85%), default route exposure (info) and TLS passthrough (warn), replicas vs HA, ImageStream count (5000/10000). Smoke-validated on ACM (Removed), Hosted (External), Hosting (Managed, 2 real drifts). Audit-grade promotion after 3 customer clusters. 1.7.3 post-tag. |
| `cluster_observability` | mature | 28 | 6 | Cluster Observability Operator (COO), distinct from the platform monitoring stack. Inventories console UIPlugins (Logging cross-refs the LokiStack, Monitoring, Tracing, TroubleshootingPanel, Dashboards) and standalone MonitoringStacks. Drift: degraded plugin/stack, no retention, single replica on HA, empty resourceSelector. Live-validated on the Hosting cluster (UIPlugin path); MonitoringStack drift is fixture-only until a cluster runs one. Audit-grade promotion after the stack path sees a live cluster. |
| `multicluster_engine` | mature | 6 | 0 | MCE. Coverage tests landed; drift detection not yet wired. |
| `acm` | inventory | 0 | 0 | Advanced Cluster Management hub state. ~180 LOC, no test file. |
| `auth` | inventory | 0 | 0 | OAuth, identity providers, RBAC. |
| `backup` | inventory | 9 | 0 | OADP / Velero presence. Walks all namespaces (1.7.x ACM Hub Backup fix). Flags `acm_hub_backup_enabled` from MCH component. Dedicated audit-grade collector planned (see `docs/ACM_HUB_BACKUP_DESIGN.md`). |
| `baremetal` | inventory | 91 | 0 | BareMetalHosts (metal3), and with hosts present their HardwareData, the Provisioning, Machines, MachineHealthChecks and Metal3RemediationTemplates. Everything goes through the allowlist in `processors/baremetal_curate.py` on the way in, so MACs, serials, WWNs and credentials Secret names never reach the collected data; BMC and NIC addresses only with `detailed_network_state`. Rows, BMC fencing and the eight finding kinds come from `processors/baremetal_hosts.py`, which the drift column does not count. The 91 tests (165 cases) sit across the four `tests/test_baremetal*.py` files. Fixture-only: no real server with a BMC has been through it, so it stays in inventory until one does. The fixtures follow the metal3 CRD schemas plus one real unreconciled host from a lab, and the only live run (read-only, on a lab with no hosts) proves the quiet path and nothing more. |
| `certificates` | inventory | 0 | 0 | TLS cert inventory. Thin (36 LOC). |
| `cluster` | inventory | 0 | 0 | Cluster version, operators, health. The "every doc has this" module. |
| `console_notifications` | inventory | 0 | 0 | Console banners. |
| `cronjobs` | inventory | 0 | 0 | Custom CronJobs (Day-2 automation). |
| `feature_operators` | inventory | 0 | 0 | NMState, MetalLB. |
| `gitops` | inventory | 0 | 0 | ArgoCD instances. |
| `hosted_control_planes` | inventory | 0 | 0 | HyperShift / Hosted Control Planes. ~185 LOC, no test file. |
| `logging` | inventory | 0 | 0 | Loki, logging operators, retention. |
| `machineconfig` | inventory | 0 | 0 | MachineConfigs, KubeletConfigs. |
| `monitoring` | inventory | 9 | 0 | Prometheus, Alertmanager, retention posture. Currently-firing alerts via `amtool` (Watchdog separated as heartbeat). |
| `mtv` | inventory | 122 | 0 | Migration Toolkit for Virtualization (Forklift), configuration only: the operator version and the Subscription that installed it, every setting the ForkliftController spec sets with its value, providers with readiness and vSphere VDDK settings, ESXi Host objects, network and storage mappings grouped by destination, hooks, the plan option conventions and the active plans with their state. Everything goes through `processors/mtv_curate.py`, `processors/mtv_controller.py` and `processors/mtv_plans.py` on the way in, so Secret references, playbooks, TLS fingerprints and AAP settings never reach the collected data. The 11 finding kinds live in `processors/mtv_findings.py`, which the drift column does not count. Migrations are not read. Fixture tests plus a replay of one redacted capture of a real hub; no live run of the collector yet, so it stays in inventory. |
| `network` | inventory | 0 | 0 | CNI, DNS, Ingress, LB. |
| `node_health` | inventory | 63 | 0 | NodeHealthChecks and the Workload Availability operators behind them (NHC, SNR, FAR, MDR), configuration only: operator versions, each check's selector, unhealthy conditions, minHealthy or maxUnhealthy with how many nodes that lets it remediate at once (NHC rounds a percentage up), and the template or escalation order; FAR templates with every parameter by name, SNR config, templates and agents, MDR templates, and per node whether its remediation fences it through a BMC. Everything goes through `processors/nhc_curate.py` and `processors/nhc_far.py` on the way in, so credential-looking FAR values never reach the collected data and per-node values (BMC addresses) only with `detailed_network_state`; Secrets are never read. Coverage, the 9 finding kinds and the view live in `processors/nhc_coverage.py`, `processors/nhc_findings.py` and `processors/nhc_section.py`, which the drift column does not count, and the bare metal chapter's fencing answer reads the coverage. The 63 tests (108 cases) sit in `tests/test_node_health.py` and the six `tests/test_nhc_*.py` files, plus 14 for the fencing extension in `tests/test_baremetal_nhc_fencing.py`. Fixtures follow one real hosted cluster (NHC 0.10.3, SNR 0.11.1, FAR 0.6.1), sanitized; no live run of the collector yet, so it stays in inventory. |
| `nodes` | inventory | 0 | 0 | Node inventory and per-node detail. |
| `operators` | inventory | 0 | 0 | All installed OLM operators. |
| `pipelines` | inventory | 0 | 0 | Tekton presence. Thin (25 LOC). |
| `policies` | inventory | 0 | 0 | ResourceQuotas, LimitRanges, NetworkPolicies. |
| `quay` | inventory | 0 | 0 | Quay registry instances. |
| `serverless` | inventory | 0 | 0 | Knative presence. Thin (32 LOC). |
| `servicemesh` | inventory | 0 | 0 | Istio / Service Mesh presence. Thin (27 LOC). |
| `storage` | inventory | 11 | 0 | StorageClasses, PVs, CSI drivers, CDI StorageProfiles and CDIConfig (import proxy URLs masked before they leave the collector), and with LVMS the LVMCluster, per-node status, CSIStorageCapacity and the TopoLVM thin pool usage from Prometheus. Thin (105 LOC); the section's rows come from `processors/storage_overview.py` and `processors/lvms.py`. |
| `tsr_basic` | inventory | 13 | 0 | Technical Supportability Review (TSR) Basic Checks, minimum hardware requirements slice: the 10 master/non-master CPU, memory, disk, OS, schedulability, and architecture checks (TSR 1.4.1.x/1.4.2.x), natively ported from `phased-gates` thresholds. Checklist-table output, not drift kinds, so it doesn't fit the drift-kind promotion path as-is. Pilot for the other ~29 Basic Checks and 7 remaining TSR categories; not yet live-validated against a real must-gather. See collector docstring for known simplifications (no exact RHCOS build matching, no system-reserved CPU/memory sizing, simplified multi-arch support gate). |
| `virtualization` | inventory | 0 | 0 | OpenShift Virtualization (CNV). |

Counted from the source: tests are `def test_*` in `tests/test_<module>.py`; drift kinds are unique `"kind": "..."` strings in `collectors/<module>.py` plus `processors/<module>_drift.py` when the collector hands its drift to one. Run `python3 hack/collector_tally.py` to regenerate the table when you suspect drift between this doc and the code.

- **What is a "drift kind"?** A named pattern the collector knows how to detect: a closed catalog of issues, not free-form messages. Examples: `policy_unknown`, `secured_without_crs`, `collector_no_collection`. Each one fires when the cluster's live state matches that pattern. The column counts how many patterns the collector enumerates today. Inventory modules sit at 0: they list what is there, they do not opine on what is wrong.

## Promotion checklist

To move a collector up a tier, the following is what changes.

### Inventory to mature

- [ ] A dedicated `tests/test_<module>.py` file exists.
- [ ] At least one test per non-trivial parser or extraction helper. Aim for the high-signal cases first (the field shape that actually broke in production); coverage percentage is a side effect, not the goal.
- [ ] The collector handles missing fields and empty lists without raising. Tests cover both the populated path and the empty path.
- [ ] Live-validated against a real cluster at least once. Note the cluster (sanitized) in the commit message.

### Mature to audit-grade

- [ ] A `_detect_drift` (or equivalent) function that returns a list of `{"kind": "...", ...}` entries.
- [ ] At least 3 drift kinds, each one tied to a real failure mode someone has seen in the wild. No speculative drift.
- [ ] Tests for each drift kind: one positive case (drift fires), one negative case (clean cluster does not trigger it).
- [ ] The template section renders the drift table with the WARNING admonition pattern used by CCLM and Descheduler. Skips cleanly when the drift list is empty.
- [ ] Validated against a cluster where at least one of the drift kinds fires. Commit message names which one.

## Discovery sidecar (TME)

Not a collector. Lives next to the document, not inside it.

Tell Me Everything (TME) is an opt-in feature that walks user namespaces and writes a sidecar `<name>-discovery/` directory with one markdown file per topic, plus `<name>-discovery-tme.zip` of it, where `<name>` is the document name without its language suffix. Off by default. Enable with `--tme` (the CLI and the `ssdg` launcher), the GUI Settings checkbox, `tell_me_everything` on `/api/jobs`, or `features.tell_me_everything: true` in the YAML. The GUI, the ACM batch list and `/api/jobs` (`format=discovery`) offer the zip for download; see [FEATURES.md](FEATURES.md#tell-me-everything-tme).

Phase 1.7 ships Tier 1 only: per-namespace inventory counts plus a per-kind anomaly heuristic (under-replicated Deployments, unbound PVCs, pods in CrashLoopBackOff, etc.). Only scope `full` is wired up; `known_only` and `operators_only` are config knobs reserved for later. Tier 2 (anomaly-triggered YAML excerpts) and Tier 3 (full raw YAML, gated by `tme_full_yaml`) are roadmap items.

The platform-classifier (`discovery/classifier.py`) is intentionally conservative: any namespace not matching a known platform prefix or exact name ends up in the "user" bucket. False positives are easier to silence than false negatives are to detect.

Secret values are never shipped. The per-namespace emitter renders Secret name, type, and key count. There is a defense-in-depth test that pins this behavior even if a `data` field leaks into the summarizer.

Code: `discovery/` (classifier, anomaly heuristics, walkers, synthesizer, emitters). Tests: `tests/test_discovery_*.py`.

## Updating this doc

When you add a collector, change tier, or land a drift kind, update the table in the same PR. Out-of-sync tables are worse than missing ones because they lie with authority.

When a new collector lands, add the row in the right tier group of the table, update the count in the header, and append the module key to the `MODULES` list in `hack/collector_tally.py` so the regen script picks it up.

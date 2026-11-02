# Cover-page product detection

The cover page and the Preface of every generated document carry a one-sentence engagement description that names the products SSDG detected on the cluster. That sentence is built from a hardcoded whitelist in `generators/engagement_description.py`. This page documents the whitelist, the contract a product has to meet to be eligible, and the steps to add a new entry.

## What you get on the cover

The description follows the shape "OpenShift cluster installation with X, Y, and Z, managed via M, with automation orchestrated by A". The pieces are decided by `_build_description()` in the same module:

- The first **platform** product becomes "cluster installation".
- The remaining platform products become the "with X, Y, Z" extras.
- The **management** products become the "managed via M" clause.
- The **automation** products become the "automation orchestrated by A" clause.

Order inside each clause follows the `priority` integer; lower priorities come first. Categories themselves render in a fixed order (platform, management, automation). Priorities can collide; equal priorities preserve insertion order in the source.

## How a product becomes eligible

There are two patterns in the file. Use whichever fits.

### Pattern 1: collector with an `installed` flag

Almost every new collector under `collectors/` returns `{"installed": True/False, ...}` after probing its top-level CR (KubeDescheduler/cluster, StorageCluster, ForkliftController, etc). For these, the `_is_installed(module)` helper handles everything: it returns True when the data block exists and either has `installed: True` or is a non-empty dict that is not `{"error": "not found"}`.

To wire one in, add a single block to `_detect_products()`:

```python
if self._is_installed("your_module_key"):
    self.detected_products.append(
        {"name": "Display Name", "category": "platform", "priority": N}
    )
```

The module key is the string returned by the collector's `name` property (typically the file's basename: `odf`, `descheduler`, `cclm`, etc).

### Pattern 2: operator-name pattern match

When the product is detected by the presence of an operator with a specific name rather than a dedicated collector, follow the `_detect_aap()` example. That function scans `data.operators.custom_operators` for a substring match and returns a bool; the result feeds the same `append()` shape.

Use this only when a dedicated collector does not exist. Most products deserve a real collector; this pattern exists for operators that are noteworthy enough to mention on the cover but where the audit depth would otherwise be wasted.

## Categories

Four categories exist today:

- **platform**: OpenShift components, storage, virtualization (MTV included, it is how the VMs got there), node remediation (Node Health Check, named only when a NodeHealthCheck exists), registry. Anything that runs the workloads.
- **management**: anything that orchestrates multiple clusters or governs them. RHACM, MCE, CCLM.
- **automation**: anything that drives changes into the cluster on its own. GitOps, Pipelines, AAP.
- **security**: anything that audits, scans, or enforces policy on the cluster. RHACS today; Compliance Operator standalone and Quay Security Scanner are candidate future entries.

Adding a new category requires touching `_build_description()` and adding the corresponding i18n key under `engagement.*` in all three locales. The `security` category was added in 1.7.3 when RHACS landed; its clause uses the `engagement.secured_by` template ("secured by {tools}"). Use that as the shape reference if you grow a fifth category later.

## Checklist for adding a product

1. Confirm the collector returns `{"installed": True/False}` at the top level. If not, fix the collector first or use the operator-pattern path.
2. Add the `if self._is_installed(...): self.detected_products.append({...})` block to `_detect_products()`. Pick a priority that puts the product where you want it in the sentence; the existing priorities run 1 to 13, leave room to grow.
3. Add at least one test in `tests/test_engagement_description.py` covering: detected when installed=True, not detected when installed=False, classified in the expected category.
4. If the product needs a non-default phrase (like AAP getting `automation_at_scale` instead of the default), add a new `engagement.*` key in all three locales and extend `_build_description()`.
5. Validate against a real cluster that has the product installed. Look for the `Products detected:` log line; the next line is `Engagement description:`, which is what lands on the cover.

## Why the list is hardcoded (and not auto-discovered)

Two reasons:

1. Not every collector represents a product. CCLM is a capability of ACM; it deserves a cover-page mention only when the ACM hub is set up specifically for cross-cluster migration. The collector's `installed` flag captures that signal precisely; an auto-discovered list would have to encode the same gate logic anyway.
2. The cover page is the first thing the customer reads. Letting it auto-balloon as collectors come and go would make the description noisy. Hardcoding forces a deliberate decision per product.

## Per-product UI toggle (parked)

A dashboard control letting the consultant disable specific products from the cover came up during the 1.7.2 work and was deferred. The use case (client does not want product X mentioned in the deliverable) is theoretical until a real engagement raises it. When that happens, the design lives in `project_open_questions.md` under "Per-product cover toggle". Until then, a consultant who needs to hide a product can comment out the corresponding block in `_detect_products()` locally; the change is one line.

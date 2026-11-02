# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.19.3] - 2026-11-02

No changes to what the tool collects or generates. This one is about finding the project.

### Added

- A public home for the docs, the OpenShift manifests, the changelog and the issues: [safeshift-doc-gen-release](https://github.com/linuxelitebr/safeshift-doc-gen-release), refreshed on every release. Picking this tool up for the first time? Start there.

### Fixed

- The HTTP User-Agent and the image's documentation label now point at that repo, so whoever follows them lands somewhere useful.
- The security contact in the docs was an address that never existed, which is a bold choice for a security contact. It is `security@elastocera.com` now.

## [1.19.2] - 2026-10-20

### Fixed

- The etcd chapter and the Backup chapter disagreed about the same cluster: an etcd backup CronJob in its own namespace (say `ocp-etcd-backup`) showed up in the etcd chapter and came out as "not configured" in the Backup chapter, which only looked in `openshift-etcd` and took whatever CronJob it found there first. Both chapters now share one rule (any CronJob in `openshift-etcd`, or one anywhere whose name or command says etcd snapshot) and pick the same job, the most recently successful. The "not configured" note no longer points at an operator-managed `cluster-backup` CronJob that OpenShift does not create on its own. Lab-checked on a single-node 4.21 cluster with a `cluster-backup.sh` job writing to NFS.

## [1.19.1] - 2026-10-20

### Added

- The client's logo in the bottom-right corner of the topology diagram and the Node Network Design, when the document has one. It sits outside the layout (`near: bottom-right`), so nothing in the drawing moves, and it is boxed to 180 x 60 px with its proportions kept: a square logo stops at the height, a long one at the width. The diagrams use a re-encoded copy, the same processing a GUI upload gets, never the file as given; the diagram zip carries it, and the icon credits leave it out, since it is the client's and not a stencil.

### Fixed

- In the Node Network Design the icon tile of every bordered card sat on the card's top border and covered part of the line: the card grids had no vertical gap, which also drops the top padding. A 5 px spacer row now lifts the tile off the line; borderless headers are unchanged.
- A logo passed with `--logo` on the CLI went into the document as given, while a GUI upload was decoded and re-encoded first. The CLI path now gets the same treatment: a re-encoded copy (`<stem>.client-logo.png` or `.svg`) next to the document feeds the cover and the diagrams, and a file that is not a usable image is dropped with a warning instead of reaching asciidoctor.
- The short description in the page footer was cut at 70 characters wherever that landed, mid-word included ("Virtualizatio..."). It now stops at the last whole word.
- The Recommendations headings carried hand-typed numbers ("1. Capacity") on top of the automatic section numbering, so the TOC showed both. The hand numbers are gone, in all three languages.
- `docs/PRIVACY.md` said SSDG does no update checks. The server does none, but the dashboard's version pill reads the public `elastocera/releases` list from GitHub in the browser. The page now says so.
- A collector that crashed left `{"error": ...}` in its slot, and the engagement description read that as the product being installed, so it could claim a product the cluster does not run. Only a real result counts now.
- `--modules tsr_basic` was rejected by the CLI even though the module exists and runs by default. The CLI list now matches `config/default.yaml`, and a test keeps them that way.

## [1.19.0] - 2026-10-20

### Added

- "Concepts used in this document": a short chapter right after the methodology chapter (or the executive summary when the brand pack has none) and before Cluster. One opening paragraph, then a table of the terms this document actually uses, each with a one-line definition and a link to its chapter: no virtualization, no live migration row; no ODF, no Ceph. 28 candidate terms in three languages, written from scratch. Always on. Every top-level chapter now carries a fixed `[[ssdg-<chapter>]]` anchor so those links survive translated titles; nothing else in the rendered document changes.
- Descheduler drift kinds that read what the operator says instead of guessing: `operator_degraded` (any Degraded condition, with its reason), `policy_out_of_date` (the operator has not applied the current CR yet), `customization_ignored` (a customization no active profile reads), `deprecated_profile`, `kubevirt_selector_narrows` (a KubeVirt profile restricts every other profile to VM nodes) and `evictionlimit_unset_with_vms`.

### Changed

- The Kube Descheduler chapter follows the profiles in use instead of assuming KubeVirtRelieveAndMigrate. Neutral title, an intro written for pods, and the VM paragraph only with a KubeVirt profile. A new Active Profiles table says in plain words what each enabled profile evicts, with the parameters the operator actually rendered. Eviction Rules replaces Rendered Policy Highlights. HyperConverged Coordination, Soft Taints and PSI Verification show only when they apply: HyperConverged whenever VMs can be evicted (a KubeVirt profile, local-storage eviction, or VMs annotated `descheduler.alpha.kubernetes.io/evict`, the documented 4.16 to 4.19 setup that gets past every evictor protection), PSI when the utilization profile reads pressure, on any profile that reads it. The utilization profile is the effective one, read off the rendered policy and marked as the operator default when the CR leaves it empty (4.21 moved that default to PrometheusCPUMemoryCombinedProfile, so guessing it would already be wrong). Drift is gated by profile family, operator version and node count. Validated against a live single-node 4.21 cluster with operator 5.3.4, once with the KubeVirt profile and once with container-only profiles in Predictive mode.

### Fixed

- On a cluster without OpenShift Virtualization the Descheduler chapter read like a VM manual and raised four false drift rows in the client document: `softtainter` missing, `descheduler-psi-alert` missing, an unset utilization profile, and PSI samples below the worker count. The last one pushed the client toward a `psi=1` MachineConfig, and a reboot of every worker, for a profile that never reads PSI. Found by a colleague on a container-only cluster.
- Rendered Policy Highlights read every field from the wrong place, on every cluster: "Node selector -", "Excluded namespaces 0" and "Max evictions -" while the policy had all three. The top-level selector and limits, the per-plugin namespace excludes and the evictor flags are now read where the operator writes them, and an absent `ignorePvcPods` means PVC pods are evictable, as the operator treats it.
- The "set HyperConverged evictionStrategy to LiveMigrate" drift fired on single-node clusters, where `None` is the right default and there is nowhere to migrate to, and `softtainter_no_taints` fired where one node can never deviate from the average. Single node is now counted from the nodes, not taken from the Infrastructure topology, which HyperShift sets to SingleReplica on every hosted cluster by default.
- The methodology chapter of the redhat and ibm packs described Navigate, a Red Hat Consulting offering that is no longer in Red Hat's public catalog, and linked to its datasheet, which now returns 404. The chapter is now "Methodology" and describes Red Hat Consulting's current three-stage approach (strategy and planning, implementation, scale) in text written for SSDG, linking to the Red Hat Consulting page; the executive summary line that named Navigate follows suit.
- Values copied from the rendered policy reached the AsciiDoc unescaped, and the policy parser trusted its input. They now go through the cell escaping, and the parser refuses YAML aliases and deep nesting (the check `utils/brand_files.py` already had, now shared) and treats a policy of the wrong shape as unavailable instead of crashing the chapter.

## [1.18.2] - 2026-10-15

### Added

- `<name>-discovery-tme.zip` next to `<name>-discovery/` whenever Tell Me Everything runs: the directory as its single top folder, so unzipping gives it back, with TME's own files only, written under a temp name and swapped in, so a half-written zip never sits at the real name. It is what the GUI offers as "TME discovery (ZIP)". The directory is still written, for whoever wants to grep it in place.

### Changed

- TME names drop the document's language suffix, on every surface. The launcher passed `acme.pt_BR.adoc` and got `acme.pt_BR-discovery/`, the GUI passed `acme.adoc` and got `acme-discovery/`; both get `acme-discovery/` and `acme-discovery-tme.zip` now. A pt_BR and an es_ES run of the same document share them, and the later run wins. A directory left under the old launcher name is not touched; delete it by hand. Only `.adoc` and the language come off: `-o out/report-2026.10.15` used to get `report-2026.10-discovery/`, the same name as `-o out/report-2026.10.16`, and now gets `report-2026.10.15-discovery/`.
- Every run deletes the TME zip and the TME files an earlier run left for the same name before it collects anything, TME on or off, the way it already did for the diagram files, and stops with `Cannot remove the stale TME file ...` when one will not go. Without that, a run with TME off would offer last week's zip as its own. Files TME did not write stay where they are, and the log names them.
- `/api/generate/status` gains `discovery_file_info`, and `FileInfo.kind` and the `/api/jobs` report formats gain `discovery`, after the diagram kinds, which keep their names and order.
- The `ssdg` launcher passes `--tme`, `--diagram` and `--diagram-embed` to the container. The diagram flags never made it through either; the README sent you to `podman run` for them.

### Fixed

- Turning Tell Me Everything on made no visible difference in the web GUI. TME wrote `<name>-discovery/` next to the document, but the results list only knew the .adoc, the PDF and the diagram files, and under `ssdg --web` the output lives in container RAM, so the directory was unreachable. The results list, the ACM batch list and the CLI's end-of-run listing now carry the TME zip, and `/api/jobs` serves it as `format=discovery`. The download route needed no change: it already served any regular file under the output roots, through the same `secure_filename`, `safe_join` and `relative_to` checks.
- `ssdg --client "Acme Corp" --tme --pdf`, straight from the README, died with `flag provided but not defined: -tme`. The launcher never had the flag.
- `ssdg --output reports/acme --pdf` warned `No PDF came out` and left the PDF out of its summary while the PDF sat in `output/reports/`. The launcher looked in `output/`, not next to the document. The TME and diagram zips it now lists had the same bug, and with an older `output/acme-discovery-tme.zip` around it listed that one as this run's.
- Tell Me Everything printed namespace labels as the cluster had them, so a `db-password=...` label on a namespace went verbatim into `30-ns-<name>.md`, and now into the zip the GUI offers. Labels and annotations now go through the same Sanitizer as the main document before any TME file is written, and come out as `***REDACTED*** (length: N)` wherever the document would mask them. Namespace names and the Secrets list (names, types and key counts, never values) are left as they were.
- A namespace name no cluster would accept became a TME file name. Offline, `omc` returns whatever a must-gather's YAML says, so a crafted one could name a namespace `x\..\..\Startup\evil` and get `30-ns-x\..\..\Startup\evil.md` on disk and in the zip, backslashes and all. TME now writes no per-namespace file for a name that is not a DNS-1123 label and logs a warning naming it, and the zip leaves out any member that is not a plain file name. The sweep still clears such a file if an older run left one.
- TME wrote its Markdown with a plain open-and-write, after a collection that takes minutes. Anyone else who could write next to the document could plant `<name>-discovery/00-overview.md` as a link in that window, and TME wrote through it. Each file now goes to a temp name and is swapped in, so a planted link is replaced, not followed, the way the diagram files already worked. TME also refuses a `<name>-discovery` that is a link or belongs to another user, with a warning, and the document carries on without it. The owner check compares against a file TME creates in there, not the process uid, so a podman bind mount that reports every file as one owner keeps working.

## [1.18.1] - 2026-10-07

### Changed

- The image build stops losing a release to one slow download. pip now waits 60 s per read with 10 retries (it gave up after 15 s and 5, which cost two builds in one week when PyPI reads stalled inside the podman VM), `curl` retries the `oc`, `omc` and `d2` downloads five times on any error, and `gem install` gets three tries. The pip settings are build args, so they stay out of the image.
- `omc` is pinned to v3.17.0 with a sha256 per architecture, like `d2`. It came from `releases/latest`, so every build took whatever upstream had published that week, unchecked. v3.17.0 is what that already resolved to, so the image ships the same binary.

### Fixed

- Bare metal fencing said yes through a BMC that metal3 could not reach. A host whose BareMetalHost sits in a registration or power management error (a Redfish service answering 500, a BMC that times out) had verified credentials from an earlier login, so a Metal3 MachineHealthCheck or NodeHealthCheck counted it as fenced while every power call to that BMC failed. It now answers no and names the metal3 error. FAR is not affected: it reaches the BMC with its own settings. Found on a compact cluster where one BMC had failed every power state read for a month.
- A Redfish error printed sushy's whole `@Message.ExtendedInfo` dump, braces, quotes and `@odata.type` keys included, while the readable part said only "A general error has occurred. See ExtendedInfo for more information." sushy promotes an entry only when its key is `Severity`, and newer BMCs say `MessageSeverity`. The bare metal chapter now prints each message as `MessageId: Message Resolution: ...`, most severe first, three at most. A dump it cannot parse prints as before.

## [1.18.0] - 2026-10-06

### Added

- Node Health Check and Remediation chapter, right after the bare metal one, when a Workload Availability operator (NHC, SNR, FAR or MDR) is installed. It is the configuration, enough to set it up again, plus whether each node can be fenced: operator versions; each NodeHealthCheck with its selector in words, unhealthy conditions, minHealthy or maxUnhealthy and how many nodes that really lets it remediate at once (NHC rounds a percentage up, so 51% of 3 nodes is one node at a time, and 51% of one node is none), the template or the escalation order and the status; a coverage table per node, where a paused check fences nothing and FAR behind another escalation step says it only runs once that step times out; the FAR templates as setting and value, with a line saying that `--action off` leaves the node off until somebody powers it on; the SNR config, templates and agents, MDR templates, and the Metal3RemediationTemplates a check names. Nine finding kinds: disabled check, missing template, a node in two checks, a node selected for FAR with no parameters for it, a minHealthy or maxUnhealthy that remediates nothing at the current count, credentials in clear in a FAR template, `--ssl-insecure`, SNR agents short of the nodes SNR covers, and remediations in progress. FAR parameters that look like credentials keep their names and nothing else, per-node values such as BMC addresses need `detailed_network_state`, and Secrets are never read, not even to check that the ones the templates name exist. Node labels come from the same `oc get nodes` the nodes collector runs, which the client caches. Fixtures follow one real hosted cluster with NHC 0.10.3, SNR 0.11.1 and FAR 0.6.1; the collector has not had a live run yet. The cover names Node Health Check when at least one NodeHealthCheck exists.

### Changed

- Bare metal fencing reads the NodeHealthChecks when a Node Health Check operator is installed. A check that fences the node through FAR, with the node's parameters in the template, answers yes even with no BMC or an unverified login on the BareMetalHost, since FAR logs in with its own settings; one through a Metal3RemediationTemplate needs the same BMC, login and Machine as the MachineHealthCheck route; SNR, MDR and a paused NodeHealthCheck answer no and say why. The chapter only mentions NodeHealthChecks when the operator is there, and without it the output is byte for byte what it was.

### Fixed

- A bare metal host on a Fibre Channel SAN reported every LUN once per path. Ironic lists a multipath LUN as its dm map and then once per path, all under the same WWN, so a Dell with one local disk and 11 LUNs on four paths read as about 58 disks and 5 TiB. Entries that share a WWN (`wwnWithExtension` when there is one) are now one disk, kept from the entry that says the most about it, and the floppy and CD/DVD drives the BMC fakes for virtual media are left out. The serial number is no key: on a SAN it is the array's, the same on every LUN. VMware's "Virtual disk" is a real disk and stays. HardwareData goes through the same path, and WWNs still never reach the collected data.

## [1.17.0] - 2026-10-05

### Added

- Brand packs: who issues the document is now something you pick, not something hardcoded. A pack is a directory with a `brand.yaml` (name, company, whether there is a methodology chapter, the images it uses), a `theme.yml` with the cover and the page header, the images, the identity strings in en_US, pt_BR and es_ES (author, confidentiality text, originator and owner, engagement intro, executive summary, the methodology chapter and its link) and a `NOTICE` saying who owns the marks. The provider side of the participants table takes the pack's company name. The `redhat` pack is today's document: the front matter of a fixture rendered in three languages is pinned against 1.16.0, and the PDFs of the fixture and of two live lab clusters, diagrams embedded, come out pixel for pixel the same, bar the fixes listed under Fixed. Pick a pack per run with the Document identity select in the GUI Settings, `--brand` on the CLI or `brand` on `/api/generate`, `/api/jobs` and `/api/convert-pdf`; else `SSDG_BRAND`, else `branding.pack` in the config, else `redhat`. The ACM batch uses one pack for every cluster, and an `/api/jobs` report keeps the pack it was issued with for its lazy PDF. An id no pack has is an error that lists the packs that exist, before anything runs. Extra packs come from a read-only directory named by `SSDG_BRAND_DIR`; there is no upload. A pack comes off somebody else's volume, so every file it names has to stay inside it once symlinks resolve (kubelet's ConfigMap and Secret symlinks are fine, the docs say how to mount one), image names are plain names, images are PNG, JPEG or inert SVG under 4 MiB, YAML goes through `safe_load` after refusing aliases and deep nesting, the theme sets only keys from a short list and names only the images it lists, and the strings are plain text with inline formatting: no brackets, no `{{ }}`, no `+++`, no line breaks, nothing that starts like an attribute entry or a block delimiter, because every way AsciiDoc reads a file needs one of those. What passes is copied into a private snapshot, and the PDF is rendered from that copy, so editing a pack after startup changes nothing. A broken pack is logged and skipped at startup, never a crash. How to make one is in docs/BRAND_PACKS.md.
- A second built-in pack, `linuxelite`: the light "Prompt" cover, drawn as outlines so it needs no font, the Linux Elite wordmark in the page header, a charcoal title with the client name in blue, issuer text written for Linux Elite in en_US, pt_BR and es_ES, and the Ground Truth methodology chapter, which links to linuxelite.com.br. docs/BRAND_PACKS.md walks through it as the worked example.
- A third built-in pack, `ibm`, for people delivering IBM Consulting engagements: the redhat document with IBM Consulting as the issuer (author, confidentiality paragraphs, originator and owner, engagement intro, additional copies, the first summary paragraph and the participants table), Red Hat kept where it is the product vendor, and the Navigate chapter word for word, still credited to Red Hat Consulting. The cover is white with the IBM 8-bar logo, a blue bar over the title, the client name in the logo blue and a block of the logo's stripes off the right edge; the header carries the logo as a vector. The pack is internal and leaves the repo before SSDG goes public.
- `cli.py --pdf-only FILE` converts an existing .adoc to PDF through the same `pdf_render` path as `--pdf`, in the look of the pack `--brand`, `SSDG_BRAND` or `branding.pack` picks. It collects nothing and needs no kubeconfig.
- The `ssdg` launcher takes `--brand`, or `brand:` in its `--config` file, else `SSDG_BRAND` from the shell, and passes it to the container (to the web server as `SSDG_BRAND` with `--web`). It needs an image from this release: if the cached one is older, the container turns the new arguments down and the launcher tells you to run `ssdg --pull`.

### Changed

- The PDF theme is split: `styles/pdf/ssdg-base-theme.yml` holds what every pack shares (Red Hat Text fonts, tables, headings, code, footer), the pack's `theme.yml` holds the cover and the header, and `utils/pdf_render.py` points asciidoctor-pdf at `ssdg-pack-theme.yml` with the pack directory as the themes dir. `styles/pdf/redhat-theme.yml` stays, now as the base plus the redhat pack, so the CJK themes that extend it, and a hand conversion that names it, render exactly as before. The identity strings moved out of `i18n/*.yaml` into `brands/redhat/i18n/`, and the Navigate URL out of `main.adoc.j2`.
- The dashboard footer reads "SafeShift Doc Gen | OpenShift Documentation Generator" instead of naming a company, the Convert page no longer promises the Red Hat Consulting theme, and the CLI's manual PDF line names the pack it uses.

### Fixed

- `ssdg ... --pdf` converted twice. The CLI in the container made the PDF with the selected pack, then the launcher ran asciidoctor-pdf again on its own, with the Red Hat theme, no safe mode and no diagram check, and wrote over it. The CLI's PDF is now the only one, and `ssdg --pdf-only` runs the CLI's `--pdf-only` instead of its own asciidoctor-pdf call.
- pt_BR and es_ES PDFs said "Chapter 1." and "Version 1.0". The templates set `:chapter-label:`, which Asciidoctor 2 ignores in favour of `:chapter-signifier:`, and nobody set `:version-label:`. Chapter headings, their TOC entries and the cover revision line now follow the document language ("Capítulo 1.", "Versão 1.0", "Versión 1.0"). en_US PDFs do not change; in the AsciiDoc of every language the attribute is renamed and the cover gains the `:version-label:` line.
- A square or tall client logo ran into the cover title. The cover gives the logo half the content width, so a square one stood 88 mm tall from 30% of the page and reached the title at 171 mm. The width now stops where the logo is 60 mm tall, and never goes under 5 mm. Wide logos, the usual case and every sample in `images/`, keep half the page and come out byte for byte as before, and so does a logo whose ratio is not a finite number, such as an SVG with a viewBox of 1e400.
- A document generated without a client name printed the raw key `templates.preface.default_client` in the preface. The key exists now ("Client", "Cliente").
- pt_BR and es_ES strings that had lost their accents get them back. The install and engagement descriptions, which reach the document title, `:description-short:`, the footer and the executive summary ("Instalação de cluster OpenShift", "gerenciamento através de", "automatización con"), and the labels of the OpenShift Virtualization, GitOps and Quay chapters ("Máquinas Virtuais", "Versão do Operator", "Canal de Actualización").

### Removed

- The `success.pdf_conversion` and `success.pdf_command` strings, which still promised the Red Hat theme, in three languages, for a message nothing printed.

## [1.16.1] - 2026-10-05

### Fixed

- Client-supplied and web-fetched strings now go inert before they reach the AsciiDoc, instead of the old pass that only touched `|` and `=`. That covers the client name and description, the custom title, the participant rows, the company website, the industry, and the company blurb SSDG pulls from Wikipedia and search. asciidoctor-pdf runs in safe mode, but safe mode still embeds absolute image paths, still honours `include::` inside its base-dir (which for a server run is the shared output directory, where other clients' documents live), and still expands attribute references, so one of those strings could reach into the PDF for a file or a document nobody meant to ship. The fetched blurb is the one nobody typed and nobody read, so it was the worst of the lot. Each field goes through the escaping that fits where it lands: body text and table cells get `pass:c[]`, while the title and the `:customer:` / `:description-short:` header attributes get numeric character references, because the theme re-expands those three in the running header and footer on every page and `pass:c` does not survive that second pass. The shared `pass:c` transform the topology and MTV tables already used moved into one helper instead of three copies. Ordinary names render exactly as before, byte for byte; the awkward-but-real ones (brackets, braces, accents, a stray `&`) print literally instead of turning into formatting.
- The client logo is validated before it lands in the cover's `image:` macro: it has to be a real image by content (magic bytes, not the extension), and a logo handed to the web API has to be the caller's own processed upload or one of the bundled logos, named one by one. Nothing else under the project or `output/` qualifies, since that is where other clients' documents and diagrams sit under names anyone can guess. A `data:` URI is refused outright, the gem we ship cannot render it anyway. Before this, a web caller could point the logo at any readable file on the pod and have it embedded in the PDF. The CLI `--logo` still takes any local file, with the same content check.
- The `ssdg` launcher no longer puts the dashboard auth token in `podman run`'s argv, where it showed up in host `ps` and `/proc/<pid>/cmdline`. It passes `-e SSDG_AUTH_TOKEN` by name and hands the value through the container engine's environment instead.

## [1.16.0] - 2026-10-04

### Changed

- The Node Network Design got a new look, and it finally reads like a network diagram instead of a stack of grey boxes. Every hop is a white card with an icon tile, a bold name and its details in grey under it. The node box carries its name in its top-left corner, the bond and the OVN-Kubernetes box are containers with a header card, VLANs and tagged OVS patch ports are the purple cards, the data path is a red line, cabling grey, the default route blue dashed, and a one-row legend at the bottom explains only what that page shows. Same hops, same words, same wiring as before: a test reads the old and the new drawing back and pins every fact, repeats included, so the restyle could not quietly lose a VLAN or a DNS server on the way. The tiles are built from the icon sets SSDG already vendors, which means the PDF credits chapter now lists Bootstrap and Tabler too whenever the network diagram is embedded. Without icons (a document name d2 cannot take in a path, say) the cards are plain text and the layout holds. Every case we measure prints larger on A4 than before: the alfa lab drawing at 7.96 pt (was 7.48), the Linux bond node at 8.66 pt (8.25), three node groups on one page at 6.85 pt (6.32).

## [1.15.0] - 2026-10-04

### Added

- The Node Network Design diagram draws OVS bonds. A balance-slb bond on br-phy used to show the bridge floating on its own and the NICs wired to nothing. Now the NICs sit in a bond box with mode and MTU, the box wires to its bridge, and OVS bridges wire to each other along their patch links. A patch link that carries a VLAN gets a box of its own between the two bridges (`patch-phy-to-ex`, `VLAN 100 · access`), the same way the Linux `bond0.100` box sits between the bond and br-ex, because that is how `ovs-vsctl show` lists it. Tagged on both ends, it is still one box with both ports, physical side first. An untagged patch link stays a plain wire, and a tag on any other OVS port is a line on its bond or bridge. The lab drawing prints at 7.48 pt on A4, over the 7 pt floor. Nodes without an OVS bond or patch link draw byte for byte as before, apart from the DNS wrap under Changed.

### Changed

- The default gateway oval in the Node Network Design breaks a list of two or more DNS servers one per line. On one line the list set the width of the oval, and on the OVS lab drawing that alone was worth 0.7 pt on A4 (6.79 pt against 7.48 pt). The list is per gateway, merged across the node groups behind it, so it is the oval that has to show a single server to draw exactly as before: two groups with one different server each get the wrap too. In the D2 source only the gateway line changes, but a taller, narrower oval reflows the page, and it prints larger for it (the live Linux bond lab node goes from 7.43 pt to 8.25 pt).

## [1.14.2] - 2026-09-30

### Fixed

- The bare metal fencing column said a host "has no BMC" when its BareMetalHost simply has no BMC address set. SSDG only sees the object, not the server, and plenty of those servers have an iDRAC or iLO nobody registered. It now says no BMC is configured on the BareMetalHost.
- asciidoctor-pdf got 120 s per document, and a big hub document in a client's ACM batch run needed more, so the batch shipped the AsciiDoc without the PDF. The cap is 300 s now. The OpenShift Route timeout goes from 120 s to 330 s to match, because `/api/convert-pdf` renders inside the request and the router would otherwise cut it first.

### Changed

- The "Detailed NodeNetworkState report" setting now says it needs an active NMState instance. Without the Kubernetes NMState operator and an NMState CR there is no NodeNetworkState, so the flag has nothing to print and the Node Network Design diagram never shows up, which looked like a bug on clusters that set up their bonds at install time.

## [1.14.1] - 2026-09-30

### Changed

- The ForkliftController settings in the MTV chapter are a plain two-column table, setting and value, under one line that says what it is. The comparison with the MTV 2.11.7 defaults and the paragraphs explaining when it could or could not run are gone from the page: a reader rebuilding MTV needs the values, not a lecture on z-streams. Keys SSDG does not know still print by name with the value marked as not copied. The defaults keep feeding the findings.

### Fixed

- List titles in the Storage and Bare Metal chapters (CSIDriver settings, CDI settings, Ceph health checks, LVMS disks, findings) rendered as italic centered captions, which read like stray figure labels. They are bold lines now.
- Bare Metal Hosts and MTV showed up unchecked on the Generate page after the upgrade. The per-tab draft stored the modules that were on and restored exactly that list, so every collector added since the draft was saved came back off. The draft now stores what was switched off, and a draft in the old format leaves the module defaults alone.

## [1.14.0] - 2026-09-29

### Added

- The Storage section now says what the storage does, not just what it is called. Each CSI driver gets its vendor (the same table the topology diagram uses), the StorageClasses on it, whether a VolumeSnapshotClass exists for it, and its CSIDriver settings: attachRequired, fsGroupPolicy, volumeLifecycleModes, storageCapacity, and on how many nodes the node plugin registered. Provisioners with no CSIDriver object, the NFS provisioner pods and in-tree plugins, get their own table instead of passing for CSI. Object bucket provisioners (NooBaa, the Rook/ODF RGW one) get a table of their own that says they hand out buckets, not volumes. The StorageClasses get a second table with volume expansion, binding mode and reclaim policy, and the Default column tells the cluster default from the default for VMs. With OpenShift Virtualization installed, the storage collector also reads the CDI StorageProfiles, and a Virtualization Storage part lists per StorageClass the claim property sets in CDI's order, the one a VM disk gets when it asks for nothing (CDI takes the first one, see `getDefaultVolumeAndAccessMode`), whether RWX is on offer at all, whether that default disk can live-migrate, the clone strategy, and whether an admin pinned the list in the StorageProfile spec. A class that offers RWX but hands VM disks RWO by default gets a line of its own, because nobody notices that one until the first node drain. The same part closes with the CDIConfig: the scratch space StorageClass (and the one the spec asked for, when CDI could not use it), the filesystem overhead with what it does to sizing (a Filesystem-mode VM disk gets a PVC that much larger, 106 GiB for a 100 GiB disk at the default 6%, Block-mode disks do not pay it) plus any class that overrides it, and whether an importer proxy is configured. Yes or no only: the proxy URL can carry a password, so the collector masks it before anything else sees it. CDI keeps an empty StorageProfile for the object bucket classes too; they stay out of the VM tables with one line saying why, instead of advice on which modes to set for a disk that can never live there. Clusters without CDI print none of it. Under Persistent Volumes, a table per StorageClass gives the PV count, the allocated capacity (GiB or TiB, one decimal, from the PV sizes whatever unit they were written in) and the access / volume mode mix. It says allocated on purpose: that is what the cluster reserved for the PVCs, not what the backend stores, and the line under the table says so, because an external array never reports usage to the cluster and thin provisioning makes the real number smaller. The Kubernetes quantity parser moved from the topology synth to `processors/quantities.py` so both can use it. On A4 the ODF names (`openshift-storage.cephfs.csi.ceph.com`, `ocs-storagecluster-ceph-rbd-virtualization`) fit their columns instead of breaking mid-name, the class, driver, provisioner and VM disk tables come out sorted whatever order the API used, and an intro and its table go to the next page together instead of leaving the intro alone at the bottom.
- LVM Storage gets a part of its own in the Storage section. Each device class with its StorageClasses, default flag, filesystem, the disks its deviceSelector picks and the ones each node really uses (with the node state), and the thin pool config: share of the volume group and overprovision ratio. Per device class and node it prints the free capacity the scheduler sees (CSIStorageCapacity), marked virtual on a thin class, because there it is thin pool size times the overprovision ratio minus what the volumes already reserved, and next to it the real thin pool size and its data and metadata usage from the TopoLVM metrics in the cluster Prometheus. No Prometheus (a must-gather, a query that got no answer, a namespace cluster monitoring does not scrape) means no usage number, and the document says which one it was instead of guessing. Findings: overprovisioning above 1 (the thin pool can fill before the StorageClass looks full, and then every volume in that device class stops taking writes), volumes that already reserve more than the pool holds, data or metadata past the 75% and 85% where LVMS alerts, and a node that is not Ready. At an overprovision ratio of 10 you can end up with 1.7 TiB reserved on a 1.6 TiB thin pool that is 1.4% full, which is fine right up until it is not. A StorageClass with no device-class parameter maps to the default device class, or to the only one when there is just one. The legacy `topolvm.cybozu.com` parameter and node label count too. A TopoLVM series for a device class the LVMCluster no longer defines is left out instead of turning into a row and an alert. The ACM batch reader ClusterRole gets `lvm.topolvm.io` for it.
- Community Rook shows up. The ODF collector only looked in openshift-storage, so a CephCluster from the upstream Helm chart never made it into the document. With no ODF StorageCluster it now looks for CephClusters in every namespace, and the Storage section prints each one: phase, Ceph health with the health checks behind it, Ceph version and image, monitors, OSDs, the raw capacity Ceph reports, and every CephBlockPool, CephFilesystem and CephObjectStore pool with its replica size or EC k+m and failure domain. It says plainly that upstream Rook is outside Red Hat support, flags health that is not HEALTH_OK, and flags every pool that keeps a single copy, since a lost disk takes that data with it. The pool table holds the pools Rook CRs define, so Ceph's own `.mgr` is not in it while POOL_NO_REDUNDANCY still counts it, and the table says so. With ODF installed nothing changes. The pool rows come from `processors/ceph_pools.py`, which the ODF section uses too now.
- Bare metal hosts get a chapter of their own, right after Nodes, on clusters that have BareMetalHosts or a Provisioning; everyone else gets nothing new. Per host: the node and Machine it backs, the BMC type read from the address scheme alone (redfish, idrac-virtualmedia, ilo5, ipmi and friends), whether metal3 verified the BMC credentials, provisioning state, operational status, power, boot mode, automated cleaning, inspection, RAID and firmware knobs, the last error, and the hardware inspection found: system, CPU, RAM, NICs and their speeds, disks, BIOS. The question virtualization people ask first gets an answer per node: can the cluster fence it through its BMC? Yes only with verified BMC credentials and a MachineHealthCheck that remediates through a Metal3RemediationTemplate; the machine-api-termination-handler every cluster ships does not count. Findings: hosts in error, credentials not verified, no BMC, registered but never reconciled because no Provisioning exists (said as such, not as an error), metadata cleaning that wipes the disks on deprovisioning, BMC TLS not verified. BMC and NIC addresses need `detailed_network_state`. MAC addresses, serial numbers and credentials Secret names never make it into the collected data: the collector keeps an allowlist, and cuts them out of error messages too. No real server with a BMC has been through this yet; it is built on the metal3 CRD schemas and one unreconciled host from a lab, so expect a follow-up when one shows up.
- MTV gets a chapter of its own, right after OpenShift Virtualization, on clusters that run a ForkliftController, and it says how MTV is set up rather than how the migrations went: the operator version and the Subscription that installed it, the ForkliftController settings next to the MTV 2.11.7 defaults, providers with readiness and their vSphere VDDK settings, ESXi Host objects, network and storage mappings grouped by destination, hooks, the plan option conventions and the active plans with their state. Critical and warning findings sit in one box at the top. Secret references, playbooks, TLS fingerprints and AAP settings never reach the collected data, and addresses print only with detailed_network_state. With the operator installed and no ForkliftController to show (none, unreadable, or a must-gather that holds no MTV objects), the chapter says why in one paragraph instead of vanishing. The cover names MTV next to OpenShift Virtualization.

### Changed

- detailed_network_state now says what it covers: besides the NodeNetworkState detail, it prints the BMC, provisioning and NIC addresses in the bare metal chapter and the MTV provider endpoints, ESXi Host addresses and addresses in MTV error messages.

### Fixed

- The CCLM provider table no longer reports "no condition reported" for a provider whose Secret, URL or settings are invalid. The reader only looked at conditions ending in Failed, and SecretNotValid does not.

## [1.13.0] - 2026-09-27

### Added

- Topology diagram, redrawn and actually delivered (Alfa, off by default). `--diagram`, the Settings toggle, `diagram_d2_enabled` in the config or on `/api/jobs` draw the cluster the way consultants kept drawing it by hand: one card per node with what runs there, the network lanes under the cards, and the users, load balancer, storage drivers and fleet members on the side. With `detailed_network_state` on there is a second diagram, the Node Network Design, and `detailed_virtual_machines` names up to 6 VMs per node. The container bundles d2 v0.9.0, so both render offline to SVG: nothing is uploaded, no icon is fetched, and the play.d2lang.com link is gone from the document. d2 renders in a private temp dir and the result is copied in atomically, so the SVG follows the umask like the `.d2` next to it (d2 on its own writes 0600).
- The diagram files are named after the document: `<doc>.topology.d2` and `.svg`, `<doc>.network.d2` and `.svg`, the icons in `<doc>.diagram-icons/`, and `<doc>.diagrams.zip` with the sources, the SVGs, the icons, a generated ATTRIBUTION.txt and the license text of everything inside. Unzip it anywhere and `d2 --layout=elk <doc>.topology.d2` renders again. The GUI, the ACM batch list and `/api/jobs` serve them (`format=topology-d2`, `topology-svg`, `network-d2`, `network-svg` or `diagrams`, and a finished job's status lists the formats that exist); the CLI prints them.
- Built-in stencils from the Kubernetes community icons, IBM Carbon, Tabler and Bootstrap Icons, rebuilt reproducibly from vendored upstream files pinned by commit and sha256. Vendor and project logos are trademarks, so they only come from your own override directory (`diagram.icons_override_dir` or `SSDG_DIAGRAM_ICONS_DIR`), used byte for byte after an inert-SVG check. Keep that directory apart from the output: pointed at `<doc>.diagram-icons`, the folder SSDG writes the diagram icons to, it is left alone and that diagram is drawn without icons, with a warning that says why. See `docs/diagram-icons.md`.
- `--diagram-embed` (also `diagram_d2_embed` in Settings, the config and `/api/jobs`) puts the diagrams in the PDF: each one as a PNG on its own A4 landscape page at the end of the topology section, plus an icon credits chapter at the end of the document with a credit line and the full license text of every icon set in the picture. That chapter ignores `include_metadata`, because it is a license obligation, not metadata. The flag turns the diagram on by itself. The `ssdg` launcher does not forward the diagram flags yet; use the container directly or the Settings page.
- A PDF whose diagram did not make it in is not shipped. asciidoctor-pdf exits 0 when it cannot embed an image and prints the alt text plus the absolute server path in its place, which is its idea of success. SSDG now checks the PNGs before converting, reads the converter's warnings, and looks for the image in the PDF; any miss deletes the PDF and says which file and why. The same check runs on `/api/convert-pdf`, so an uploaded document that embeds a diagram without its PNG gets a clear refusal instead of a PDF with a temp path in it.
- The Generate page points at the diagram toggles: under Document Configuration a "Visual topology diagrams (Alfa)" link opens the Alfa card in Settings, and next to it the page says whether the diagrams are off, on, or on and embedded in the PDF. The toggles stay in Settings; this just keeps the feature from hiding there.
- `diagram.render_timeout` (config only, 5 to 600 seconds, default 60) caps each d2 render. A render that runs out of time is skipped with a warning and the document is still written.

### Changed

- `cluster-topology.d2` is no longer written. The source follows the document name now, so two documents in one directory stop overwriting each other's diagram. Old `cluster-topology.d2` files are not cleaned up, delete them by hand.
- Every run (a `--dry-run` aside) deletes the diagram files an earlier run left for the same document name, right before collection and whatever the flags say. A stale SVG from a run with the VM names on would otherwise sit next to a document that no longer prints them, and the GUI lists whatever exists. Only the exact names SSDG writes are touched, and anything else found at one of them is left alone with a warning. If a stale file cannot be removed, the run fails right there, before minutes of collecting, with the path in the message. On Windows the usual suspect is an SVG viewer holding the file open.
- The sanitizer loads its rules from the project directory and fails closed. Before, a CLI run from another working directory did not find `config/sanitization.yaml`, sanitized nothing and said nothing. Missing, empty or broken rules now stop the run before `oc` or `omc` is ever invoked.
- asciidoctor-pdf runs from one place (`utils/pdf_render.py`) for the CLI, the GUI, `/api/convert-pdf`, `/api/jobs` and the ACM batch: safe mode everywhere, jailed to the document's own directory with `--base-dir` (the jail covers `include::` and the output path; an image referenced by absolute path is still read, see docs/SECURITY.md). The Go launcher still runs its own asciidoctor-pdf pass on the host; it does not go through this runner yet. The PDF command the CLI prints is the exact one SSDG runs. After a refused diagram embed it prints none, because asciidoctor-pdf run by hand skips that check and puts the PNG's absolute path where the diagram goes.
- `/api/jobs/<id>/report` answers 400 on an unknown `format` instead of quietly sending the AsciiDoc, and reports now go out with `nosniff` and `no-store`, so a browser neither sniffs an SVG into a page nor keeps a customer document in its cache. The format is checked before readiness, so an unknown format on a job that is not finished is a 400 too (it was a 404 `report not ready`). Downloads carry `Content-Length`, and `Content-Disposition` comes from Flask's `send_file`, which leaves the quotes off a plain file name. `/api/generate/download` sends `nosniff` and `no-store` as well (it sent `no-cache`).
- The PDF error texts come from `utils/pdf_render.py`, with the same status codes as before. `/api/convert-pdf` and `format=pdf` on `/api/jobs` now say `asciidoctor-pdf is not on PATH` (was `asciidoctor-pdf is not installed`), `asciidoctor-pdf timed out after 120s` (was `PDF conversion timed out`), `asciidoctor-pdf failed (exit N)` followed by the first 20 lines of stderr (was the raw stderr, or `PDF conversion failed` when there was none) and `asciidoctor-pdf exited 0 but wrote no PDF`. The GUI log says `PDF not generated: ...` where it said `PDF generation failed: ...` or `PDF generation error: ...`, and the CLI `[ERROR]` output stops at 20 lines of stderr.
- `/api/jobs` names job documents through `secure_filename`, like the GUI always did. A client name with accents now maps to an ASCII file name, and a dot in the name survives (`Acme.Corp` gives `acme.corp-...`, not `acme-corp-...`).

### Fixed

- `--output /elsewhere/doc.adoc --pdf` and `--acm-batch --output-dir /elsewhere --pdf` died with "outside of jail". Without `--base-dir`, asciidoctor-pdf jails to the working directory, not the document's. The code comment that blamed the source directory was wrong too.
- A relative `--logo` in `--acm-batch` resolved under `output/` and quietly vanished from the PDF. The batch passes the project root as `imagesdir` now, like every other path.
- A JSON `/api/generate` turned a feature on when it got the string `"false"` (or `"0"`, `"off"`), since the flags went by truthiness: `"detailed_virtual_machines": "false"` put the VM names in the document and the diagram. The feature flags in a JSON body now read like the form fields: a real boolean, or `true`, `1`, `yes` or `on`, and anything else is off. A batch run through `/api/generate` reads them the same way.
- A PDF that went out without an image said nothing about it. asciidoctor-pdf exits 0 when it cannot read the client logo, and its warning was dropped. The warning now shows up in the CLI output, the GUI log, the ACM batch log and, for `/api/jobs`, the server log.
- The facts behind the old Alfa diagram were wrong in the usual places. A hosted cluster was drawn with a local etcd and API, a compact 3-node cluster counted every node twice, worker pools split on a few KiB of kernel-reserved memory, any CSI driver that was not ODF showed up as `external/unknown`, a cluster was called hosting because the HyperShift CRD existed, `local-cluster` counted as a managed cluster, and an IngressController with no `readyReplicas` reported the desired count as ready. The graph now trusts `controlPlaneTopology`, groups pools by MachineConfigPool and real size, names storage by provisioner, counts hosted and managed clusters that actually exist, and reads a missing ready count as zero.
- `--acm-batch` dropped `--tme` and the `--detailed-*` flags on the floor. They reach every cluster now, and so does `--diagram`.
- The lazy PDF on `/api/jobs` converted whichever `.adoc` a glob found first in the job directory, not the recorded report, and two concurrent `format=pdf` requests ran two converters onto the same file. It builds from the recorded document now, once, under a lock, and a job whose `.adoc` is gone gets a 404 instead of a 500.

## [1.12.4] - 2026-09-25

### Collectors

- Curated NodeNetworkState detail (opt-in). The NMState section shows the NNS count by default; with `detailed_network_state` on (config, `--detailed-network-state`, or Settings) it renders the per-node config you need to rebuild a cluster: bonds (mode, ports, options, MTU), VLANs, bridges, real addresses, default gateway, custom routes, DNS, and the physical NICs in use. Drops the OVN internals, APIPA, loopback, and ethtool noise NNS reports for every link. Grounded on a live single-node cluster.

### Added

- Project Participants front matter (opt-in, GUI form). A checkbox on the Generate page reveals a form for Red Hat and client contacts (name, role, email) with add/remove rows; the document then renders the standard CER "Additional Copies" and "Project Participants" sections, a table per group, with the client table titled by the client name. Data is entered through the form only; fields are escaped for AsciiDoc table safety.
- The Generate form keeps what you typed when you leave the page and come back. Each screen is its own server-rendered page, so a hop to Settings used to wipe the form. The draft now lives in `sessionStorage` (per tab, gone when you close it), stays entirely in the browser, and never touches the generation path. The logo is the one field it cannot restore, since browsers forbid setting a file input's value.

### Fixed

- The async job API (`/api/jobs`) ignored every per-run feature toggle (D2, TME, detailed VM / DataVolume / NodeNetworkState) and the participants data, so a programmatic run produced a different document than the GUI. All of them now flow through the job path too. The toggle list is a single shared source (`utils/features.py`) so the GUI, batch, and job paths cannot drift again, and the OpenAPI `GenerateRequest` schema now documents them.

## [1.12.3] - 2026-09-21

### Collectors

- Technical Supportability Review basic checks (`tsr_basic`): a native re-implementation of the 10 minimum-hardware checks from Red Hat's internal TSR checklist (community contribution, #39).

### Added

- `imgtoadoc.sh` ships as a release asset on the public `elastocera/releases`, so the image-to-inline-AsciiDoc helper is one download away.

### Fixed

- The Convert to PDF tool (`/api/convert-pdf`) failed on every file with `to_dir ... is outside of jail (disallowed in safe mode)`. asciidoctor-pdf writes the PDF into a temp dir, but the run passed no `--base-dir`, so the safe-mode jail fell back to the working directory and refused to write outside it. Now the run is jailed to the temp dir, which also tightens what an uploaded doc can `include::`. A real end-to-end conversion test guards it.

## [1.12.2] - 2026-07-31

### Fixed

- The ingress default certificate's secret name showed as `***REDACTED*** (length: N)` in the doc because the collector keyed it as `secret`, which the sanitizer masks. Renamed to the whitelisted `secretName` so the name shows, like the API section. Only the name is ever read; the secret contents are never touched.

## [1.12.1] - 2026-07-31

### Fixed

- The certificates section reported a custom ingress certificate as the cluster default. It read `ingress.config/cluster`, which does not carry the router serving cert; that lives on the IngressController as `spec.defaultCertificate.name`, so a cluster with only a custom default cert always looked default. Now reads the IngressControllers. On HyperShift hosted clusters the default cert secret is platform-provisioned and carries `hypershift.openshift.io/managed`, so it is classified as the default rather than misreported as custom.

## [1.12.0] - 2026-06-25

### Collectors

- VM hugepages in the OpenShift Virtualization section: per-VM page size and reserved memory, plus a per-node utilization table. Cross-checked against node `status.allocatable` (the applied reality), not PerformanceProfile, which hosted clusters often lack. Flags full/over-committed pools, a VM whose node serves none of its page size, and a stopped VM too big to schedule. First lens of the tuning collector; pinning/passthrough/NUMA follow.
- VMs with RDM (raw LUN / shared disks) get an always-on table (ignores the count-only toggle, like hugepages, because these are notable VMs). Disk-level markers: `disk.lun`, `lun.reservation` (SCSI3 PR, the failover-cluster tell), `shareable`. Static-PV and Forklift-origin markers land once a real RDM VM grounds them.
- Memory overcommit posture: the cluster overcommit percentage (HyperConverged `higherWorkloadDensity`), the KSM state (off / scoped / all-nodes footgun), and whether the wasp-agent swap path is deployed. Flags the headline trap, a Guaranteed (`dedicatedCpuPlacement`) VM under cluster overcommit whose memory ceiling is scaled below the guest size and can be OOM-killed (set `requests.memory` equal to `memory.guest` to opt out), plus the empty-KSM-selector and overcommit-without-swap footguns. Rendered when overcommit is on. Grounded on the live lab (150%, wasp deployed, a pinned VM at risk).
- VM CPU model (passthrough): per-VM `cpu.model`, the node CPU models, and the cluster `cpuModel` baseline. Flags `host-passthrough` (migrates only to an identical CPU, stranded on a mixed-CPU fleet) and generic models (`qemu64`/`kvm64`, which never schedule). Only VMs with an explicit model are listed; the rest use the migratable host-model default. Grounded on a live host-passthrough VM.
- VM CPU pinning and NUMA (intent): per-VM `dedicatedCpuPlacement`, `isolateEmulatorThread`, NUMA passthrough, and vCPU topology, with the article's spec rules as findings (NUMA needs pinning and hugepages; `isolateEmulatorThread` needs pinning; mixing `spec.domain.cpu` with `resources.requests.cpu` un-pins the VM). The node-side checks (cpumanager label, density) and runtime placement land once a live pinned VM grounds them.

### Changed

- VM, running-instance (VMI) and DataVolume inventories show counts by default; the full tables are opt-in via `detailed_virtual_machines` / `detailed_data_volumes` (config, `--detailed-vms` / `--detailed-datavolumes`, or Settings). The VMI table folds under the VM toggle. On big clusters the DataVolume table alone added hundreds of pages. Counts, the omitted-list notes, and the VM Hugepages cross-check render either way. Flips the prior always-on behavior.

### Fixed

- The virtualization collector listed VMs, VMIs and DataVolumes from the context namespace only. The calls passed `namespace=""`, falsy in `OCClient.get`, so it added neither `-n` nor `-A` and scoped to `default`; anything elsewhere was dropped. Now `all_namespaces=True`. Caught when the hugepages table came up empty on a cluster whose VMs live in a `vm-tuning-lab` namespace.
- The VM table showed `N/A` for memory on every modern VM. It read only `domain.resources.requests.memory`, but current KubeVirt carries the size in `domain.memory.guest`. Now prefers `memory.guest` and falls back to the legacy request.

## [1.11.0] - 2026-06-13

### Collectors

- OVS bonds (balance-slb and friends) are documented in the NMState section, read from NodeNetworkState observed state. Since NNS reports the applied config, the mode, members, rebalance interval, and bridge VLAN (access/trunk) come through however the bond was set up (MachineConfig, manual script, or both), with no node access. Per-node table. No NMState operator, no signal (a MachineConfig scan is the planned fallback).
- CAPI MachineSets (`machinesets.cluster.x-k8s.io`) are documented when present: on an MCE hosting cluster these are the hosted clusters' node pools (name, hosted cluster, replicas, version). Read group-qualified alongside the host's own `machinesets.machine.openshift.io`, so a hosting cluster shows both instead of one. Absent on plain clusters. The batch read-only role gains `cluster.x-k8s.io` to match.

### Fixed

- Company-info lookup fails fast when the bastion has no public internet. It used to walk every source (Wikipedia, DuckDuckGo) with no early exit, up to 13 requests each hanging to the timeout: ~130s of dead wait ending in an empty section and a misleading "not found" (the company was there; the internet was not). A 2s reachability probe now decides up front, and no egress means one clear warning pointing at `--company-description`, no lookup traffic. Unchanged when the internet is reachable.

## [1.10.4] - 2026-06-13

### Fixed

- The nodes collector queries `machinesets.machine.openshift.io` explicitly. On an ACM/MCE hosting cluster the bare `machinesets` is ambiguous (CAPI adds `machinesets.cluster.x-k8s.io` for the hosted clusters), so the cluster's own worker MachineSets were missed from its document; a standalone cluster without MCE was unaffected.
- ACM batch mode selects a hosted cluster's admin-kubeconfig by exact name (`<hosted-cluster-name>-admin-kubeconfig`) in the hosting namespace, so each hosted cluster is documented against its own cluster. When several hosted clusters share a hosting namespace, the previous lookup could select a sibling's kubeconfig; it now resolves the exact secret and raises rather than guessing if it is absent.
- ACM batch mode provisioned a read-only ClusterRole on each managed cluster whose enumerated group list had fallen behind the 1.10 telco collectors: `performanceprofiles`, the SR-IOV CRDs, MetalLB, NMState, Tuned, Quay and Argo all returned Forbidden on managed clusters (cluster-admin on the hub does not help; the reads run as the provisioned `ssdg-batch-reader` SA). The role is now a complete enumerated group list (no `apiGroups: [*]`, so the grant stays auditable), verified against `oc api-resources` on a fully-loaded cluster, with `resources: [*]` per group to sidestep the singular/plural RBAC footgun. A new gate, `tests/test_acm_batch_rbac_coverage.py`, fails the build if a collector reads an operator group the role does not grant, so a new collector can never become a field 403 again. Also fixed a pre-existing group error the audit caught: `machinesets` was under `cluster.x-k8s.io` instead of `machine.openshift.io`.
- ACM batch mode now reaps its own orphans at startup: a run killed before cleanup (SIGKILL, bastion drop, power loss) leaves an MSA + ManifestWork behind, and the next batch run now sweeps any object carrying the `app.kubernetes.io/managed-by: safeshift-doc-gen` label before starting. Label-scoped, so it only ever removes SSDG's own objects; validated end-to-end against a live ACM hub (bait ManifestWork created, reaped, ACM garbage-collected its payload). The MSA token already self-expired in 1h, so this closes the leftover-object gap, not a credential-exposure one.
- An RBAC denial (restricted ServiceAccount lacking read on some resource, e.g. an ACM batch run that cannot list `performanceprofiles`) logged a scary `Error executing command` and dropped the section with no explanation. The oc client now recognizes Forbidden, logs a plain `No access to '<resource>'; skipping` warning pointing at the reference ClusterRole, and never escalates it to an error. The fix for the cause is RBAC, not code: use the broad read-only role in `deploy/openshift/01-rbac.yaml` rather than a hand-rolled allowlist, which turns every new collector into a field Forbidden.

## [1.10.3] - 2026-06-12

### Added

- `build-multi-arch.sh` refuses to build a version whose git tag already exists at a different commit: that situation always means the bump was skipped, and pushing would silently overwrite a released image. RELEASE.md now leads with "step 1 is the bump, always".

### Changed

- `release-binaries.sh` now attaches the SBOM that `build-multi-arch.sh` writes to `output/`, ending the manual upload step. RELEASE.md gains the post-release check: an old dashboard must show the update arrow and `ssdg --pull --web` must bring the new image, the loop users actually depend on.

### Fixed

- Three collectors queried `subscription` unqualified, which on an ACM hub can resolve to `subscriptions.apps.open-cluster-management.io` instead of OLM, hitting RBAC walls for restricted service accounts (seen live: a read-only batch SA got Forbidden at cluster scope). All OLM subscription queries now use the fully qualified `subscriptions.operators.coreos.com`, like the two collectors that already knew better.

## [1.10.2] - 2026-06-12

### Added

- The launcher gains an integration test that runs the real binary against a stub podman and asserts the pull happens before the web container starts, pinning the exact wiring this release fixes. go tests now also run as a pre-commit gate on go/ changes and as a hard gate in release-binaries.sh, because until today no local gate executed them at all.

### Fixed

- `ssdg --pull --web` silently ignored the --pull flag: the pull only existed in the generate flow, so web users (everyone) served the locally cached image forever and no update ever arrived. The pull now runs before mode dispatch and works in every mode. Found by a user insisting "the image never updates" through three wrong diagnoses; the fourth one was the code.

## [1.10.1] - 2026-06-12

### Added

- The update tooltip now says how to update, not just that you should, and the instruction depends on the jump: same-major updates say "Refresh with: ssdg --pull" (the floating :1 tag makes that one command the whole upgrade), while a new MAJOR says so explicitly and points at the new binary, because ssdg --pull does not cross majors by design and would otherwise be a lie.

### Fixed

- The update check trusted the order of the public releases feed, but GitHub sorts that list by target-commit date and the umbrella repo has a single commit, so every release ties and the order is arbitrary. The check now parses every `ssdg-v*` tag and picks the highest semver. Found minutes after v1.10.0 shipped, when a v1.9.0 dashboard proudly reported "Up to date".

## [1.10.0] - 2026-06-12

### Collectors

- New `sriov` collector (36th), closing the telco suite: node policies (VF layout, driver, MTU, PF selectors), SriovNetworks (resource, target namespace, trust/spoofChk), per-node sync state with VF counts, operator config. 3 drift kinds: node sync failed (critical), network requesting a resource no policy provides (the Pending-pods classic), carved-but-unconsumed resources. Validated against a real telco dataset (8 vfio-pci policies, 10 nodes, 128-CPU hosts): zero false positives on a healthy cluster.
- GitOps goes audit-grade, grounded in a live ACM hub. Instance posture from the ArgoCD CR with unset fields rendered as posture (SSO, local admin state, RBAC default policy and the groups holding role:admin, TLS, HA); Git sources from the repository secrets (URL with userinfo stripped by construction, credential presence as a boolean, values never decoded); registered destination clusters; 7 drift kinds, including the AppProject wildcard grant, local admin alive despite SSO, and role:admin as default policy.
- Custom ClusterRoles go from a useless count to a classified audit. Non-system roles are bucketed by the fingerprints automation leaves (labels, ownerReferences, field managers): stock, operator/platform-managed, human-applied, unattributed. Names listed only for the last two; a danger roll-up flags wildcard, escalate/bind/impersonate, and cluster-wide secrets-read, with bound subjects. The shared classifier (`utils/origin.py`) adds an origin column to the custom-SCC audit for free. Calibrated live against 869 roles: managedFields distinguishes a kubectl-created role from one delivered by an ACM governance Policy. The doc is honest about the limit: buckets are evidence, not proof.
- Quay goes audit-grade. The collector reads the config bundle secret through a strict allowlist (a key not on the list never enters the collected data, so credentials are unreadable by construction) and documents the posture: authentication type, SUPER_USERS, tag expiration, quota, mirror flags, storage backends without access keys. 4 drift kinds: user creation still open after setup, storage without TLS, Quay route missing from additionalTrustedCA (the classic x509 pull failure), no SUPER_USERS.

### Added

- Always-visible version pill in the masthead (rvtma's idiom), consolidating what was spread across three places. One element, three states: neutral pill = could not verify (air-gap, dev build), green halo = verified newest, pulsing halo + arrow = update available, click opens the public release. Green means proof; silence stays ambiguous on purpose.

### Fixed

- The custom-CronJobs section printed every container env var as NAME=VALUE into the document, and the collector dragged the full raw CronJob object along. Env values on customer CronJobs are where hardcoded credentials live; the collector now keeps env names only and drops the raw object.
- The update check polled a releases API that answers 404 to anonymous browser calls, so it could never light up. It now reads the public `elastocera/releases` feed (filtering `ssdg-v*` tags).

### Changed

- Binary releases also publish from the maintainer's machine: `release-binaries.sh` cross-compiles the launcher and creates the release plus the `ssdg-v*` mirror on the public `elastocera/releases`. The binaries workflow drops to `workflow_dispatch`; a `v*` tag is now a pure version marker and the entire release runs locally.

## [1.9.0] - 2026-06-11

### Collectors

- New `node_tuning` collector (35th): PerformanceProfile and per-node Tuned posture. CPU partition, hugepages, RT kernel, NUMA, and whether each node actually applied its profile. 3 drift kinds; validated live down to `isolcpus` in the kernel cmdline.
- `etcd` backup goes from "found a CronJob" to a real audit: snapshot destination (PVC->PV or inline NFS mount), retention signal, and failure alerting. 3 new drift kinds. Both real-world shapes covered (adfinis chart and the oc-debug recipe). The native automated backup stays out: Tech Preview in 4.21.
- NMState: NNCP conditions and NNCE per-state summary with 5 drift kinds. Caught live: a policy Progressing for 9 days with all enactments Pending, invisible before.
- NADs are parsed and rendered as an "Additional Networks (Multus)" table; system NADs counted, not listed.
- MetalLB BGP: BGPPeers table and Communities count, with `bgppeer_cleartext_password` and `advertisement_pool_missing` drift. The BGP password value never enters the collected data.
- Custom SCC audit: permissiveness per SCC (privileged, host access, capabilities, subjects) plus an info roll-up of the dangerous ones.

### Added

- Discreet update badge in the dashboard masthead when a newer release exists. The check runs in the browser (anonymous GitHub API call, 6h localStorage cache), never in the server, so the no-phone-home posture holds and air-gapped deployments just never show it. Dev builds skip the check.

### Changed

- The release image is now built, smoke-tested, pushed and verified locally via a versioned `build-multi-arch.sh` (rvtma's release model): version cross-check, both arches under QEMU, CLI + web smoke before any push, GHCR push as one manifest list with no per-arch scaffold tags, registry read-back, and a skopeo mirror to `quay.io/elastocera/ssdg` (skippable with `--no-quay`). A local trivy/grype scan and syft SBOM replace the CI scan step, non-blocking. The container workflow is demoted to a `workflow_dispatch` fallback; a `v*` tag push now only releases the Go binaries. New `--check-versions` flag runs just the pyproject/CHANGELOG cross-check and is the first step of `make release-check` (closes #74). See `docs/RELEASE.md`. The script also pushes a floating major tag (`:1`) to both registries, and the `ssdg` binary now pins that tag instead of its own version: new collectors (minor/patch releases) arrive without redistributing the binary, and a command-contract change is by convention a major bump that ships with its own launcher. `OCP_DOC_IMAGE` still overrides everything.
- `no_periodic_backup` raised from info to warning. No etcd backup means no rollback and no quorum-loss recovery; that is not an info-grade observation.

### Fixed

- `--title` (and the GUI custom title) reached the cover page but not the main doctitle, so the PDF footer's {document-title} kept the i18n default no matter what the operator set. The main template now honors it like the cover does. Footer recap, since this confused a real user: the center footer is `{document-title}` over `{description-short}` (the company description truncated at 70 chars); editing body text in the .adoc changes neither, they are doc attributes. Test in `tests/test_document_title.py`.
- The custom-SCC filter missed the `-v2` stock SCCs (4.11+), so five default SCCs appeared as customer-created in every report.
- NADs, NetworkPolicies, and EgressFirewalls were queried with `namespace=""`, which scoped them to the session project (usually `default`, empty). The report saw zero NADs on clusters that had them. All three now query cluster-wide.

## [1.8.0] - 2026-06-08

### Added

- `collectors/compliance.py`: Compliance Operator posture, audit-grade, second member of the `security` engagement category after RHACS. Reads the operator's own CRDs (ScanSettingBinding, ComplianceSuite, ComplianceScan, ComplianceCheckResult, ComplianceRemediation, ProfileBundle); no XCCDF parsing. Aggregates the check list into counts by status and FAIL-by-severity instead of dumping every row, names high-severity failures (capped at 25), and tracks the remediation backlog. 13 drift kinds with severity mapped to auditor action: high failures and broken scans are critical, NON-COMPLIANT is info because every honest cluster fails CIS on day one. Live-validated on the lab hosting cluster across five bound frameworks (CIS, BSI, PCI-DSS, STIG). Design doc in `docs/COMPLIANCE_DESIGN.md`.
- `collectors/cluster_observability.py`: Cluster Observability Operator (COO) posture, mature tier. Separate from the platform monitoring stack: inventories console UIPlugins (Logging cross-refs the LokiStack, plus Monitoring, Tracing, TroubleshootingPanel, Dashboards) and standalone MonitoringStacks. 6 drift kinds (degraded plugin or stack, no retention, single replica on HA, empty resourceSelector). Live-validated on the lab Hosting cluster (UIPlugin path); the MonitoringStack drift kinds are fixture-tested until a cluster runs one. Design doc in `docs/OBSERVABILITY_OPERATOR_DESIGN.md`.
- Stop button on the dashboard generate page (issue #27). Appears only while a run is in flight; `POST /api/generate/cancel` sets a cancel flag the pipeline checks at safe points (between collectors, before the doc-render phase, between clusters in batch). A collector already running finishes its current work; the cancel lands at the next checkpoint. Frees the single-job lock so the operator can fix a parameter and re-run without waiting for the whole thing. The CLI is unaffected: it passes no cancel event, so the checks are no-ops.
- REST API for async must-gather report generation. `POST /api/jobs` streams a `.tar.gz` archive to disk and enqueues a job; `GET /api/jobs/<uuid>` polls status; `GET /api/jobs/<uuid>/report` downloads the `.adoc` or `.pdf` result; `GET /api/jobs/<uuid>/logs` streams per-job log events via SSE; `DELETE /api/jobs/<uuid>` removes the job and its output directory. Jobs are identified by a UUID4 that doubles as a per-job access token. An in-process thread pool (`InProcessJobQueue`, configurable via `SSDG_JOB_WORKERS`) processes jobs concurrently. A TTL sweep daemon auto-deletes jobs after `SSDG_JOB_TTL_HOURS` (default 24h). API jobs are fully isolated from the existing single-job UI model. Partially closes #27 (cancel endpoint; UI stop button is a follow-up).
- `POST /api/jobs/<uuid>/cancel` requests cancellation of a queued or running job. Worker checks a `threading.Event` before extraction and before calling the generator. Jobs already inside `OCPDocGenerator.run()` complete normally. Returns 409 for terminal jobs.
- `docs/API-SERVER.md`: design rationale, API contract reference, and extension guide for the async job API.
- `/api/jobs/*` paths and `JobStatus`, `JobAccepted`, `JobCancelResponse`, `JobErrorResponse` schemas added to `docs/api-v1.openapi.yaml`.
- `utils/offline.py`: `OfflineGap` sentinel type. Returned by `exec_in_pod`, `adm_top_nodes`, and `query_instant` when the client is in offline (must-gather) mode. Distinguishes "resource absent from cluster" (`None`) from "mechanism unavailable offline" (`OfflineGap`) so templates can render actionable notes with remediation hints rather than silently omitting sections.
- `nodes` section: **Resource Usage subsection** (CPU/memory from `oc adm top nodes`). Renders an offline note with remediation hint when the must-gather is the source. Previously the data was collected but not rendered.
- Offline gap summary in the preface: when running against a must-gather, the existing warning admonition now includes a document-specific list of every data point that was unavailable and what must-gather plugin or command would capture it next time. Previously the warning was generic text only.
- Toggle for the document metadata footer. The `Metadata` section at the end of the document (generation date and tool version) is on by default; a Settings checkbox, the `--no-metadata` CLI flag, and `output.include_metadata` in the config each turn it off. This finally wires the long-dormant `output.include_metadata` flag, which was in the config but read nowhere. Tests in `tests/test_metadata_toggle.py`.

### Changed

- Collectors are now discovered automatically. `collectors/__init__.py` walks the package with `pkgutil` and registers every `BaseCollector` subclass at import time, so dropping a `collectors/<name>.py` is enough; the hand-maintained registry in `main.py` is gone. A contract test (`tests/test_collectors_discovery.py`) pins the discovered set, so a missing or duplicate key breaks the suite, not a customer run. From @ammachado's #34, with follow-up tests. The contributor and architecture docs were rewritten to match (no more "register in main.py").
- `make release-check` (local container build plus the full suite) is now mandatory before tagging a release. A build that only fails in CI can no longer reach a pushed tag. See `docs/RELEASE.md`.
- `monitoring` firing-alerts section: instead of silently omitting the section when Alertmanager is unreachable (including in offline mode), the template now renders a NOTE admonition explaining what was missing and how to access live firing alerts.
- `etcd` disk IO section: adds a specific offline note (with the Prometheus `gather_prom_db` hint) when Prometheus metrics are unavailable. The existing "Prometheus not reachable" fallback still covers live-cluster cases.
- `etcd` quota table: marks the quota value as `(assumed)` and adds a NOTE admonition when the tool fell back to the 8 GiB operator default because Prometheus was unavailable. Previously the assumed value appeared as measured data.
- `etcd` leader stability: inline note now includes the Prometheus remediation hint when the gap is specifically an offline gap (vs. a live-cluster Prometheus outage).
- `.containerignore` and `.gitignore` exclude extracted must-gather directories (`mustgather*`, `must-gather*`). A local offline-test extraction in the repo root no longer bloats the build context or breaks `make build` on xattr reads.

### Fixed

- Dashboard modules metric card showed a hardcoded `24` while the Generate page counted the real number. As collectors landed the two screens drifted apart. The card now renders `len(load_modules())`, the same source the Generate page uses, so they cannot disagree again. Regression test in `tests/test_dashboard_page.py`.
- Company-description lookup ignored the document language and always searched Portuguese Wikipedia first (Spanish Wikipedia was never searched at all), so an EN or ES engagement got a Portuguese result. The lookup now hits the configured language first, English next (broadest coverage), then the rest. The scorer learned Spanish disambiguation cues (`(empresa)` variants, `es una empresa`, `con sede en`). `ClientInfoCollector.collect()` takes the language from the generator. Tests in `tests/test_client_info_lang.py`.
- Dashboard interface defaulted to the browser's language. An incognito window on a pt-BR browser opened in Portuguese because `detect_lang` consulted `Accept-Language` before the English default. The UI is English-first now: `?lang=` and the saved cookie still switch it and persist the choice, but with no explicit signal the interface opens in English regardless of browser locale. `DEFAULT_LANG` was already `en_US`; the fix stops honoring `Accept-Language`. Tests in `tests/test_ui_language.py`.
- ACM batch mode produced a near-empty document for any cluster carrying Velero Backups (the ACM hub shows up as `local-cluster`). A Backup that has not started yet has no `status.startTimestamp`, and `sort(attribute='status.startTimestamp')` in `backup.adoc.j2` raised `UndefinedError` on it, which dropped the *entire* document to the bare fallback template (a 681-byte stub instead of the full report). The section now sorts the timestamped backups and appends the rest, so nothing is lost and one un-started backup no longer tanks the document. Regression test in `tests/test_backup_template.py`.
- Front-end assets are vendored for offline use. The dashboard pulled PatternFly, Font Awesome, and the Inter / JetBrains Mono web fonts from CDNs, which broke the UI on an air-gapped bastion and phoned home on every page load. They now live under `gui/static/vendor/` and are served locally; `layout.html` has no external `<link>` left. The container already ships `gui/static`, so the offline image needs nothing extra. The vendor tree is exempt from the large-file pre-commit hook, and a regression test in `tests/test_offline_assets.py` fails if a CDN link sneaks back.
- Company "About" source label was a hardcoded English `User provided` on one fallback path (lookup found nothing, user supplied only a website), so a PT or ES document carried one stray English line. It now uses `t("sources.user_provided")` like every other path. Test in `tests/test_client_info_lang.py`.
- About page rendered the company sector with hardcoded Portuguese (`Não identificado` and the matched industry names), so an EN or ES document carried a Portuguese label. The not-identified line also refused to hide, because the template gate compares the value against `t('industries.not_identified')` and a Portuguese literal never matched the translated string. `_extract_industry()` now returns `industries.*` values through `t()`. Test in `tests/test_client_info_lang.py`.
- `operators` and `upgrade_readiness` fetched every ClusterServiceVersion with `csv -A -o json`. OLM copies each AllNamespaces CSV into every target namespace, so on a large cluster that payload is N operators x M namespaces of JSON, big enough for the OOM killer to SIGKILL `oc` inside a memory-capped container. Both queries now drop the copies server-side with `-l '!olm.copiedFrom'` (live only; omc's negated selectors return nothing, so it is skipped offline). The operator list was already deduplicated by name, so the rendered output is unchanged. `get()`/`safe_get()` gained a `label_selector` parameter. Tests in `tests/test_oc_client.py`.

### Security

- Bumped Pillow to `>=12.2.0` (from `<12.0`) across `requirements.txt`, `pyproject.toml`, and `uv.lock`. Closes six advisories that land on reachable surface: we decode untrusted client logos through `Image.open`, which sniffs the format from magic bytes and ignores the MIME we validated first. The fixed CVEs cover an OOB write on invalid PSD tiles (GHSA-pwv6-vv43-88gr), a FITS decompression bomb (GHSA-whj4-6x5x-4v2j), an OOB write loading PSD (GHSA-cfh3-3jmp-rvhc), a PDF-parsing infinite loop (GHSA-r73j-pqj5-w3x7), a font integer overflow (GHSA-wjx4-4jcj-g98j), and a heap overflow on nested list coordinates (GHSA-5xmw-vc9v-4wf2). The 11 to 12 major bump is safe here: `utils/logo.py` only uses stable API (open, thumbnail, convert, save), no constants removed in 12.
- Bumped pytest to `>=9.0.3` and pytest-cov to `>=6.0` (dev-only) across `requirements-dev.txt`, `pyproject.toml`, and `uv.lock`. Closes the predictable-tmpdir advisory (GHSA-6w46-j5rx-g56g). The 7 to 9 jump (two majors) needed zero test or config changes: the 920-test suite was already on `tmp_path` fixtures and `--strict-markers`, and the local `tmpdir` variables are `tempfile.mkdtemp()`, not the pytest fixture.

## [1.7.3] - 2026-06-03

### Upgrade notes

SSDG-as-pod deployments: reapply `deploy/openshift/01-rbac.yaml` after the image bump. The new collectors call `oc exec`, which needs `pods/exec` with the `create` verb. The wildcard rule only grants `get/list/watch`. ACM batch mode self-heals the ClusterRole on each managed cluster.

### Added

- `collectors/etcd.py`: etcd posture, audit-grade. Member topology, fsync and commit p99 vs the 10ms / 25ms SLOs, quota headroom, leader stability, backup checks. 21 drift kinds. Cross-refs ACM Hub Backup so `no_periodic_backup` stays silent when that one is configured. Talks to etcd via `oc exec etcdctl` and to in-cluster Prometheus via a curl-in-pod helper.
- `collectors/upgrade_readiness.py`: pre-upgrade audit, the kind a customer pays for. ClusterVersion conditions, deprecated APIs from `APIRequestCount` with named consumers, operator hygiene, ClusterOperators, MCPs, nodes. 23 drift kinds. The output table is the punch list for the maintenance window.
- `collectors/internal_registry.py`: in-cluster image registry posture (mature). 19 drift kinds covering the documented anti-patterns: emptyDir on HA, missing/stuck pruner, PVC near full, default route exposure, ImageStream count blowout. Audit-grade promotion after 3 customer-cluster validations.
- `collectors/acm_hub_backup.py`: ACM Hub Backup audit-grade, grounded in the Linux Elite five-part series. 19 drift kinds mapped to the documented findings.
- `collectors/monitoring.py`: firing alerts via `amtool`. Watchdog and friends bucketed as heartbeat (their absence is the actual signal); the rest goes to the actionable list. Silenced and inhibited dropped.
- `collectors/rhacs.py`: RHACS audit-grade. Central and SecuredCluster sides plus a fleet view via the `rhacs:telemetry:*` ServiceMonitor metrics. 14 drift kinds.
- `collectors/topology.py` + `generators/d2_topology.py`: cluster topology as a D2 diagram source written next to the doc (Alfa, opt-in via `features.diagram_d2_enabled` or the GUI checkbox). Renders locally or via play.d2lang.com.
- `discovery/`: Phase 1.7 Tell Me Everything. Opt-in sidecar dir with one markdown file per topic (overview, OLM subscriptions, system NS, user NS index, per-NS detail, anomalies). 8 anomaly heuristics. Secret values never shipped, only names and types.
- `main.OCPDocGenerator._apply_cross_refs`: orchestrator hook that runs after every collector returns. Collectors implementing `apply_cross_refs(all_data)` get the full data dict and can emit extra drift. Fixes a silent bug where cross-ref drift was always empty because the parallel orchestrator never populated `self.data`.
- `utils/oc_exec.py` + `utils/prometheus.py`: shared helpers for "exec a command in a pod and parse JSON" and "query in-cluster Prometheus". monitoring.py amtool migrated to use them.
- `security` engagement category in `generators/engagement_description.py`. RHACS is the first member; future security products reuse the shape.
- Design docs for the four new collectors: `docs/ACM_HUB_BACKUP_DESIGN.md`, `docs/ETCD_DESIGN.md`, `docs/UPGRADE_READINESS_DESIGN.md`, `docs/INTERNAL_REGISTRY_DESIGN.md`. Each spec lays out the drift catalog, gates, data shape, and test plan before the code.

### Fixed

- `batch/acm_discovery.py` + `deploy/openshift/01-rbac.yaml`: the ClusterRoles for batch mode and for SSDG-as-pod gained `pods/exec`, `apirequestcounts`, and `imagepruners`. Without these the new collectors 403 on every managed cluster. Test pins the rules so the next collector that needs RBAC breaks the test, not production.
- `generators/client_info.py`: Wikipedia search no longer takes the first hit blindly. "Vale" used to return the geological feature, "Três Corações" the city, "Itaú" an unrelated subsidiary. New scorer ranks `(empresa)` titles, S.A. / Inc. legal suffixes, and "é uma empresa" / "is a corporation" snippets. Negative cues use whole-word match so `rio` stops matching `majoritário`. Wikimedia User-Agent now follows the documented policy. Validated on the usual suspects (Vale, Petrobras, 3 Corações, Itaú, Embraer, Banco do Brasil, TIM).
- `collectors/etcd.py`: `_collect_members` now requires the pod to carry a container named `etcd`, excluding the `etcd-quorum-guard-*` helpers. Lab smoke had counted 6 members on a 3-master cluster and flagged a false `member_count_anomaly`. Ask me how I know.
- `collectors/backup.py`: the hardcoded `openshift-adp` namespace meant every ACM hub running cluster-backup (which lives in `open-cluster-management-backup`) silently reported "OADP not installed". Walks cluster-wide now.

## [1.7.2] - 2026-05-23

New Kube Descheduler collector. Cover-page engagement description finally mentions ODF, Descheduler, and CCLM (the 1.7.x collectors that landed without being represented there). One security-audit batch (M2 + H2) ships; M3 and H1 deferred with documented rationale. Plus a sweep of trim_blocks rendering bugs found by hand-reading actual ACM deliverables.

### Added

- `collectors/descheduler.py`: Kube Descheduler audit collector, hosted-cluster focused. KubeVirtRelieveAndMigrate profile, HCO coordination, soft taints, PSI proxies via Prometheus, 11 drift kinds. 24 unit tests. Sections in en_US, pt_BR, es_ES.
- Cover-page engagement description gained ODF (platform), CCLM (management, only when the collector's own gate already passed), and Kube Descheduler (platform). Priorities renumbered to leave room for future additions. 8 new tests pin the trigger conditions.
- `docs/PRODUCT_DETECTION.md`: spells out how the cover-page whitelist works, the two detection patterns (collector-installed flag vs operator-name match), the category meanings, and a checklist for adding a new product.
- Pre-commit hook (`tools/templates/check_jinja_in_tables.py`) blocks `{% endif %}` at end of a table row; use `{% endif +%}` to preserve the newline under `trim_blocks=True`.
- `images/ssdg-logo.svg` shipped as default client logo and used by the dashboard masthead (32px) and About modal (with dark-mode invert).
- Hosted-cluster NOTE in the Identity Providers section explaining where OAuth config actually lives in HyperShift.
- `make clean-output` wipes `output/*.{adoc,pdf,svg}`, `output/batch/*.{adoc,pdf}`, uploaded logos, and the stale `.last_batch` pointer. Use before each test cycle so the PDF you open is the one your last commit produced.
- `make multiarch` family restored: `multiarch`, `multiarch-local`, `multiarch-clean`, `multiarch-no-minify`, `multiarch-release`. Rewritten as standalone Makefile blocks, no external script. The old wrappers pointed at `scripts/build_multiarch.sh` which got deleted in the OSS cleanup and left `make help` lying.
- `make test-minification` restored, points at the new `hack/test_minification.sh`. Runs the same minifier stack as the Containerfile (pyminify, rjsmin, rcssmin, then `compileall -OO`) on a representative sample in ~5 seconds. SKIPs cleanly when deps absent.

### Changed

- Default UI and Document Language switched to `en_US` (was `pt_BR`). The CLI launcher's `--help` lead example also moved to `--lang en_US`.
- ACM observability consolidates the status and flags a stale `Installing` condition as drift.
- `docs/CONTAINER.md` documents the full multiarch family plus `make test-minification`. `docs/CONTRIBUTING.md` pointer added.

### Fixed

- `--pdf` actually generates a PDF in CLI single-cluster paths. Was wired only into ACM batch; single-cluster printed "here is how to make a PDF" and exited, and `ssdg --pdf` printed `PDF: <path>` in the banner without passing the flag to the container. Now both the Python CLI and the Go launcher honor it in any mode. 5 new tests pin the new behavior plus the graceful-degradation cases (tool missing, non-zero exit, timeout, macOS `/tmp -> /private/tmp` symlink resolution).
- ACM Metrics Retention rows no longer glue together (`{% endif +%}` fix).
- MTV Providers `Reason` column shows the real failure message: Forklift uses `*Failed=True` conditions, not `Ready=False`. Same root fix surfaces the drift detail for `provider_not_ready`.
- Governance Policies `Per-cluster` cell shows `(no clusters bound)` when the Placement matches zero clusters, instead of an ambiguous `-`.
- MCE Managed Cluster Add-ons read `status.namespace` for Install Namespace (ACM 2.10+ stopped populating `spec.installNamespace`).
- MCE per-cluster table no longer renders a phantom cluster for `ManagedClusterAddOn` CRs that live in non-cluster namespaces (`open-cluster-management-observability` is a hub-side namespace, not a ManagedCluster).
- MultiClusterHub Components table grew a `Component / State` header.
- Forklift Providers fleet-wide collection (was scoped to the operator's namespace, missed per-cluster providers).
- Image Registry storage type now picks the actual backend.
- `trim_blocks` list-rendering sweep across 9 spots in 5 templates: MachineConfig (Configured Files, Systemd Units, KubeletConfig MCP Selector, ContainerRuntimeConfig MCP Selector), certificates (Component Routes), cronjobs (Labels), feature_operators (NMState Instances, MetalLB Instances), logging (Schemas, Retention Streams), auth (LDAP Attributes), hosted_control_planes (Status, Networking). All were `**Label:**` immediately followed by `{% for %}` or `{% if %}` with no blank line, so AsciiDoc treated the bullets as paragraph continuation and rendered "3 - /a - /b - /c" inline. Fix is uniform: blank line before the loop or conditional.
- Hosted Cluster Status condition bullets rendered inline because the inner `{% endif %}` on the condition-message check sat at end of line, eating the bullet's terminating newline. Fix: `{% endif +%}` on the inner endif.
- NMState Instances no longer renders `(namespace: )` with empty parentheses. NMState is a cluster-scoped CR so the namespace field is always empty; the template now omits the namespace info when blank. MetalLB stays unchanged (still namespaced).

### Security

- `SSDG_AUTH_TOKEN` minimum length enforced at boot (32 chars). Breaking change for hand-rolled Secrets shorter than that. `install.sh` and the Go launcher both produce 64-char tokens. With this minimum in place, brute-force is no longer in scope, so the audit's sibling proposal for a `/api/auth/login` rate limiter (which has a known auto-DoS footgun behind an OpenShift Route) was dropped in favor of the failed-auth log below.
- Failed-auth log line with pseudonymized client IP. Modes via `SSDG_LOG_FAILED_AUTH`: `hash` (default, SHA256 first 8 hex chars), `full` (raw IP, opt-in), `off`. Successful-auth path does not log the IP. See `docs/PRIVACY.md` for the LGPD-aware rationale (legítimo interesse under Art. 7 IX).
- `asciidoctor-pdf` invocations run with `--safe-mode safe`. Blocks `include::/abs/path[]` from reading pod-local files like the SA token.

## [1.7.1] - 2026-05-21

### Added

- `collectors/cclm.py`: Cross-Cluster Live Migration audit collector. Renders when CCLM is active on the hub. 11 drift kinds. 20 unit tests.
- `templates/sections/cclm.adoc.j2` plus i18n keys in en_US, pt_BR, es_ES.
- ACM observability: `enableDownsampling` row plus WARNING when disabled.
- ACM observability: `spec.capabilities.platform.analytics` sub-section (ACM 2.13+).
- ACM managed clusters: version prefers `clusterClaims[version.openshift.io]` over the k8s version.

### Fixed

- ACM Managed Clusters table shows the OpenShift release for managed OCP clusters, not the underlying k8s version.

## [1.7.0] - 2026-05-20

### Added

- `collectors/odf.py`: OpenShift Data Foundation collector. StorageCluster, CephCluster, pools, NooBaa, capacity with per-replica derivation, OSD layout and node distribution, CRUSH topology, image SHA pinning.
- `collectors/prometheus_ceph.py`: PrometheusCephSource. Discovers thanos-querier, authenticates via `oc whoami -t`, honors kubeconfig TLS. No toolbox required.
- `collectors/toolbox_ceph.py`: ToolboxCephSource. Shells `ceph -f json` via `oc rsh` to `rook-ceph-tools` when Prometheus is unreachable. Never auto-enables the toolbox.
- Composite Prom-first, toolbox-fallback dispatch in `_collect_ceph_metrics`, with per-method source tracking.
- Confidence tier system: `verified` (toolbox runtime), `declared` (k8s spec), `measured` (Prometheus), `assumed` (Ceph default). Rendered inline via `_confidence_badge` filter.
- `_resolve_ratios`: walks runtime > spec > default for nearfull/backfillfull/full, attaches provenance per value, flags drift when runtime and spec disagree.
- `hack/validate_ceph_sources.py`: dev-only harness comparing Prom and toolbox outputs side-by-side.
- LokiStack per-tenant and per-stream retention in `logging`.
- MultiClusterObservability retention in `acm`.
- Prometheus and Alertmanager retention plus storage posture in `monitoring`.
- `docs/PRIVACY.md`: data-handling posture.
- Layout-invariant regression test ensuring every `===` heading is preceded by a blank line.
- 36 unit tests across `test_odf.py`, `test_toolbox_ceph.py`, `test_asciidoc.py`. Suite now 343 tests.

### Changed

- Toolbox detection honors both `managedResources.cephToolbox.enable` (modern) and `spec.enableCephTools` (legacy).
- Storage Backends and Container Image References tables restructured for `trim_blocks=True` safety and long-SHA wrapping.

### Fixed

- ODF sub-headings rendered as paragraph continuations because preceding lines ended with `{% endif %}`. Switched to `{% endif +%}`.

## [1.6.15] - 2026-05-20

### Added

- `tests/test_acm_batch.py`: 13 fixture tests for `ACMBatchRunner`. Coverage 24% to 90%.
- `go/main_test.go`: 19 table tests. CI gains `go-test` on Ubuntu and macOS with `go vet` plus `go test -race`.
- `tests/test_batch_artifacts.py`: regression tests for the dashboard download list.
- `tests/test_openapi_contract.py`: validates live `/api/*` responses against `docs/api-v1.openapi.yaml`.
- `docs/api-v1.openapi.yaml`: current surface plus Phase 2 `/api/v1/jobs` contract.
- `.coveragerc` plus CI gate at 65% (measured 67%).
- `.gitleaks.toml` plus pre-commit hook.
- SPDX-License-Identifier on every tracked .py, .go, .sh file (67 files).
- macOS to the CI Python matrix.
- `CODE_OF_CONDUCT.md`, `THIRD_PARTY_LICENSES.md`.

### Changed

- `gui/app.py` split into seven blueprints. 1157 lines to 103.
- `requirements.txt` split into runtime and `requirements-dev.txt`.
- `cli.py --version` reads `importlib.metadata` instead of the hardcoded `1.0.0`.
- README badges plus issue chooser routing security reports to GHSA.

### Fixed

- Dashboard download list dedupes when cluster names share a prefix.
- CI installs `requirements-dev.txt` after the split.
- `entrypoint.sh` exports `PORT`.

### Removed

- `utils/cache.py`: dead, zero callers.

## [1.6.13] - 2026-05-18

### Changed

- Go launcher `--help` lead example now uses `--lang en_US` instead of `--lang pt_BR`. Defaults unchanged.

## [1.6.12] - 2026-05-18

### Fixed

- 1.6.11 pre-flight auth check ran before the `dry_run` early-return, breaking the Container Build smoke step. Moved pre-flight to after the dry-run check.

## [1.6.11] - 2026-05-18

### Added

- Pre-flight `oc whoami` in `OCPDocGenerator.generate()` with a structured error block listing the three most common auth failures. Skipped in offline mode.

## [1.6.10] - 2026-05-18

### Fixed

- `ssdg` launcher failed inside the container with `permission denied` on rootless podman because uid 1001 inside could not read a mode-0600 kubeconfig owned by the host user. Launcher now stages a copy in `os.MkdirTemp` at mode 0600 and bind-mounts only that single file.

### Changed

- Kubeconfig resolution matches `oc`: first existing entry in `$KUBECONFIG`, then `~/.kube/config`.
- Bind-mount surface shrank from the whole `~/.kube/` to one staged file.

## [1.6.9] - 2026-05-07

### Fixed

- Republish `:1.6.9` to recover from a corrupted `:1.6.8` multi-arch image. The auto-prune workflow deleted untagged sub-manifests that the tagged index still pointed at.

### Changed

- Auto-prune workflow disabled (only `workflow_dispatch` remains) until replaced with a multi-arch-aware action. Tracked in `project_open_questions.md`.

## [1.6.8] - 2026-05-07

### Security

- Republish to ship a clean image. The 1.6.7 image included `/app/.claude/worktrees/`, scratch files, `*.bkp` backups, `diagnose_*.sh`, and `/app/go/build/*` cross-platform launcher binaries (~18 MB). Net effect: 613 MB to 523 MB.

## [1.6.7] - 2026-05-07

### Changed

- Example domains in CLI help text replaced with `example.com` (three spots in `cli.py` plus the Go binary).
- OCI label `org.opencontainers.image.vendor` is now `elastocera`; `authors` stays `Andre Rocha`.
- ACM batch annotations migrated to `ssdg.elastocera.com/...`.

### Security

- `.gitignore` defense-in-depth block for secret-shaped filenames (`.env`, `*.pem`, `*.key`, `*.crt`, `kubeconfig*`, `id_rsa`, etc).

## [1.6.6] - 2026-05-06

### Fixed

- System Console toggle returns the bar to its minimum height after a user drag-resize (inline `style.height` was winning over the CSS class).

## [1.6.5] - 2026-05-06

### Changed

- Dashboard footer tightened: `margin-top` 2rem to 0.5rem, `padding-top` 1rem to 0.75rem.

## [1.6.4] - 2026-05-06

### Changed

- Dashboard "Cluster Connection" card collapsed. The SA button moved to the card header; API URL, Bearer Token, and Connect share one horizontal row.

## [1.6.3] - 2026-05-06

### Changed

- Client logo picker on Generate is now a single labelled button instead of label-plus-generic.

## [1.6.2] - 2026-05-06

### Changed

- Modules list height 240px to 160px so the Generate button fits on a laptop viewport.
- Em-dashes purged project-wide; repo grep for the character returns zero.

## [1.6.1] - 2026-05-06

### Fixed

- Progress bar moves during a run. `QueueLogHandler` bumps `gen_state.progress` by 1 (capped at 95) per collector activity log line.

### Changed

- Modules list shows a permanent scrollbar gutter and tinted thumb so "more below" is visible.
- Document Configuration toggles laid out horizontally.
- `beforeunload` warns when the user tries to close the tab during a running generation.

## [1.6.0] - 2026-05-06

### Added

- ACM Hub badge in the masthead. Backend exposes `is_acm_hub` from `/api/cluster/status` via an `oc get multiclusterhub -A` probe.
- Generate page restores in-flight state on navigation by polling `/api/generate/status` on `DOMContentLoaded`.

### Changed

- ACM Batch Mode card hidden until the connected cluster is a hub.
- 3 new tests cover hub probe true, false, and disconnected response shape.

## [1.5.5] - 2026-05-06

### Fixed

- ACM batch mode called `asciidoctor-pd`, wrote `.pd`, pointed at `styles/pd/`, and ran `oc apply - -` instead of `-f -`. Four trailing `f` truncations in `batch/acm_discovery.py` from an editing pass after the 2026-05-05 history reset.

## [1.5.4] - 2026-05-06

### Fixed

- Dashboard "Version" field showed `-` when the token was a namespaced SA lacking RBAC on `clusterversions.config.openshift.io`. `/api/cluster/status` now uses `oc version -o json`; cluster-admin sees the OCP release, namespaced SAs see `Kubernetes v1.34.6`.

## [1.5.3] - 2026-05-06

### Fixed

- Dashboard "Version" field showed `-` for namespaced SAs (first attempt, superseded by 1.5.4).

## [1.5.2] - 2026-05-06

### Changed

- In-cluster ServiceAccount login is opt-in. The dashboard now starts disconnected in pod mode; a "Use this cluster's ServiceAccount" button shows up when `incluster_available: true` and `POST /api/cluster/login-incluster` is the explicit route.
- Removed the implicit import-time SA login at `gui/app.py`.

### Fixed

- The 1.5.1 logout sentinel was an empty kubeconfig, which client-go treats as "no usable config" and falls back to the mounted SA token, reattaching to the home cluster. The new sentinel is a valid kubeconfig pointing at `https://127.0.0.1:1` with `insecure-skip-tls-verify`; `oc whoami` fails with connection refused and stays disconnected.

## [1.5.1] - 2026-05-06

### Fixed

- Disconnect had no effect in pod mode: `oc whoami` fell back to the SA token at `/var/run/secrets/...` and the next status poll silently reattached. Logout now adopts a no-context placeholder (refined in 1.5.2). 3 regression tests in `tests/test_cluster_logout.py`.

## [1.5.0] - 2026-05-06

### Added

- Browser sign-in flow. Unauthenticated visits redirect to `/login`; the page POSTs to `/api/auth/login` and drops the same `ssdg_auth` HttpOnly SameSite=Strict cookie (8h TTL) as the `?token=` handoff. `Authorization: Bearer` keeps working.
- `gui/templates/pages/login.html` plus `.ssdg-login*` styles. Strings under `login.*` in all three locales.
- 13 end-to-end tests in `tests/test_auth_login.py`.

### Changed

- OpenShift deployment switched from 1Gi PVC to `emptyDir` (1Gi sizeLimit). `gen_state` is process-local memory; PVC files could not be listed for download anyway.
- `install.sh` no longer applies `02-pvc.yaml`.

### Removed

- `deploy/openshift/02-pvc.yaml`.

## [1.4.3] - 2026-05-06

### Fixed

- Generate page file picker showed OS-locale strings even with the dashboard in English or Spanish. Native control is now visually hidden behind a translated button; strings live in `generate.choose_file` and `generate.no_file_chosen`.

## [1.4.2] - 2026-05-06

### Fixed

- Cluster Connection form never sent `insecure_skip_tls_verify`, so labs with self-signed certs always returned 401. Added checkbox to the card, default checked.

## [1.4.1] - 2026-05-06

### Fixed

- `ssdg --client X --logo /abs/path.png` no longer prefixes `/workspace/` onto absolute paths. Launcher checks whether the logo lives inside `pwd` and, if not, mounts that single file at `/tmp/uploaded-logo.<ext>`.

### Changed

- README rewritten with three entry paths ordered easiest first: binary, container, source. Examples section added.

## [1.4.0] - 2026-05-06

### Changed

- Logo upload reworked end-to-end. The Generate page sends `multipart/form-data`; backend processes bytes via `utils.logo`. Raster goes through Pillow (thumbnail to 600px, EXIF stripped, re-encoded PNG); SVG through `defusedxml` plus an allowlist dropping `<script>`, `<foreignObject>`, `<iframe>`, `animate-*`, `<style>`, event handlers, and any non-fragment `href`/`src`.
- `ssdg --web` Go launcher no longer bind-mounts `pwd` at `/workspace:ro`. CLI mode keeps the mount because the binary still passes the path through.
- New runtime deps: `Pillow>=10.0,<12.0`, `defusedxml>=0.7.1,<0.8`.
- 22 new tests in `tests/test_logo.py`.

## [1.3.3] - 2026-05-06

### Fixed

- Client logo no longer disappears from the PDF cover when added through the dashboard. Go launcher bind-mounts `pwd` at `/workspace:ro` in `--web` mode; backend resolves relative paths against `/workspace/` then `<PROJECT_ROOT>/`. Absolute paths pass through if they exist.
- `imagesdir` set to `<PROJECT_ROOT>` on every `asciidoctor-pdf` invocation.

## [1.3.2] - 2026-05-06

### Changed

- Dashboard always binds `0.0.0.0` plus a warning when `SSDG_AUTH_TOKEN` is unset (was: refuse to bind, fall back to 127.0.0.1, made `podman run -p 5050:5000` silently unreachable). Operators wanting localhost-only restrict via host port (`-p 127.0.0.1:5050:5000`).
- When the token is set, `/api/*` still requires Bearer or cookie. Production manifest sets it from a Secret, so pod mode is authenticated by default.

## [1.3.1] - 2026-05-06

### Added

- `ssdg --web` mints a per-run `SSDG_AUTH_TOKEN`, passes it to the container, opens the browser with `?token=<token>`. First visit converts the query into an HttpOnly SameSite=Strict cookie (8h TTL).
- `/api/*` accepts either `Authorization: Bearer` (curl, AAP, automation) or the `ssdg_auth` cookie.

## [1.3.0] - 2026-05-05

### Added

- Bearer-token auth on every `/api/*` via `SSDG_AUTH_TOKEN`. `/api/health` and `/api/about` stay public.
- `pre-commit` with black, flake8, standard hygiene hooks. pytest runs on push.
- `docs/SECURITY.md` Reporting a Vulnerability section.
- `fonts/AUTHORS.txt`, `fonts/OFL.txt`, `fonts/LICENSE.txt` next to the Red Hat font files.

### Changed

- Container registry moved from `quay.io/safeshift-doc-gen/ssdg` to `ghcr.io/elastocera/safeshift-doc-gen`.
- Project rebrand: `OCP Doc Generator` to `SafeShift Doc Gen`. Org `linuxelitebr` to `elastocera`.
- `oc login` no longer puts the bearer token in argv. Both SA login and `/api/cluster/login` build a kubeconfig at `0o600` in tmpfs and adopt via `KUBECONFIG`.
- `SSDG_DEBUG` defaults false. `--insecure-skip-tls-verify` opt-in per request.
- License metadata is `Apache-2.0` across README, Containerfile, `/api/about`, `pyproject.toml`.
- Markdown uses soft-wrap.
- Black 25.1.0 across all 54 tracked Python files.

### Removed

- Streamlit interface (`web/app.py`, the dependency, the `WEB_MODE=streamlit` switch, the 8501 EXPOSE, Makefile target, validation hook).
- Real-looking names from examples and i18n.

### Fixed

- Path traversal in `/api/generate/download/<filename>`, `/api/convert-pdf` upload, `/images/<path>`. All go through `secure_filename` plus `safe_join` plus containment check.
- `output_dir`, `config_file`, `must_gather_path` no longer escape configured roots.
- AWS `accessKeyID` is now actually redacted (was a no-op `if 'accessKeyID' in aws: pass`).
- `OCClient.run_command` redacts `--token`, `--password`, `--client-secret`, `--bearer-token` before logging argv.
- `OCClient.clear_cache` takes the cache lock; `describe` honors `self.command` instead of hardcoding `oc`.
- `gen_state` check-then-mutate in `/api/generate` is lock-protected.
- ACM batch MSA cleanup logs a warning instead of silently swallowing the exception.

### Security

- Default `FLASK_SECRET` literal removed. App generates a per-process random key when env is unset.
- `requests.get` in `generators/client_info.py` sets `allow_redirects=False`.

## [1.2.0] - 2026-04-15

### Added

- Web interface built with Flask + PatternFly 6, replacing Streamlit as the default.
- Multi-page layout: Dashboard, Generate, Convert to PDF, Settings.
- Dark/light theme toggle with localStorage persistence.
- Real-time log console via Server-Sent Events.
- Sidebar collapse/expand animation.
- Cluster connection status badge in the masthead.
- About modal with version, author, GitHub link, license.
- Auto-detection of `asciidoctor-pdf`; PDF options disabled when unavailable.
- Settings page persists config, output, must-gather, verbose, language.
- Full UI i18n in pt_BR, en_US, es_ES (~130 keys per language). New `ui:` section in `i18n/*.yaml`. `gui/i18n_helper.py` resolves dot keys; `POST /api/lang` persists in a 1-year cookie.
- `deploy/openshift/` manifests numbered for ordered `oc apply`.
- `GET /api/health` for kube probes and the Docker HEALTHCHECK.
- ServiceAccount auto-login in pod mode (made opt-in in 1.5.2).
- Read-only ClusterRole plus narrowly-scoped write on `ManagedServiceAccount` and `ManifestWork` for ACM Batch Mode.

### Changed

- Default web port 8501 to 5000.
- `--web` launches Flask; Streamlit available via `WEB_MODE=streamlit`.
- Containerfile exposes 5000 plus 8501 (legacy).
- `entrypoint.sh` traps SIGTERM/SIGINT and forwards to Python so pod termination completes in ~1s.
- `HEALTHCHECK` probes `/api/health` via `curl-minimal` instead of a no-op `python3 -c "import sys; sys.exit(0)"`.

### Fixed

- Light mode masthead no longer hardcoded dark.
- Brand text no longer white-on-white in light mode.
- Sidebar collapse expands main content to full width.
- HTML template minification disabled (`htmlmin` rewrote Jinja `{% if x == 'y' %}` inside attributes, breaking Settings). JS/CSS minification unaffected.
- `deploy/openshift/` files renamed with numeric prefixes so `oc apply -f .` applies Namespace before Deployment.

### Deprecated

- Streamlit interface (`web/app.py`). Removed in 1.3.0.

## [1.1.8] - 2026-03-31

### Added

- ACM Discovery Batch Mode (`--acm-batch`): documents all managed clusters from one ACM Hub command.
- `--include-hub` for optional Hub inclusion.
- `--pdf` in batch mode.
- Custom ClusterRole for read-only access on imported clusters (ManagedServiceAccount + ManifestWork with auto-cleanup).
- ACM Batch toggle in Streamlit GUI.
- CronJobs and Quay modules.
- `docs/ACM-BATCH-MODE.md`.
- Go CLI flags: `--acm-batch`, `--include-hub`, `--output-dir`, `-V`.
- GitHub Actions workflow for Go binary releases.

### Changed

- tmpfs output size to 512MB for batch mode.
- Go CLI detects language suffix in output filenames for PDF generation.

### Fixed

- Single mode output detection with language suffix (`.pt_BR.adoc`).
- Marker file cleanup between batch and standalone modes.
- Signal handler compatibility with Streamlit threads.

## [1.1.7] - 2026-03-29

### Added

- Loki AlertingRules and RecordingRules collector.
- AlertmanagerConfigs collector.
- Custom CronJobs collector.
- ACM Observability details (Thanos storage, addon spec).
- ACM Policies table (remediation action, compliance).
- Dynamic tool version from git tag.

### Fixed

- Operators section empty (rewrote collector with OLM deduplication).
- ACM policies, PrometheusRules, ServiceMonitors not collected (`namespace=''` bug).
- MCE template shows capacity for all cluster types.
- HCP platform inherits from HostedCluster when HCP reports `None`.
- Certificates section shows default/custom status instead of blank.

## [1.1.6] - 2026-03-27

### Added

- GitOps collector captures full ArgoCD details (Applications, AppProjects, health, sync).

### Fixed

- Duplicate widget ID on download buttons in Streamlit.

## [1.1.5] - 2026-03-27

### Changed

- Container image tag pinned to match binary version.

## [1.1.4] - 2026-03-27

### Changed

- PDF generation always uses the container (no local `asciidoctor-pdf` dependency).
- Added `rouge` gem for syntax highlighting in PDF.

### Fixed

- CLI mode permission denied on Linux volume mounts (tmpfs plus `podman cp`).
- Container kubeconfig access for non-root uid 1001.
- SELinux label conflicts (`--security-opt label=disable`).
- PDF container file ownership (`--user` flag).

## [1.1.3] - 2026-03-24

### Fixed

- LimitRanges, ResourceQuotas, NetworkPolicies collected across all namespaces.

## [1.1.2] - 2026-03-24

### Added

- LimitRanges and ResourceQuotas display in policies template.

### Changed

- QUICKSTART rewritten for `ssdg` binary-first workflow.

## [1.1.1] - 2026-03-24

### Changed

- Container image renamed to `ssdg` on quay.io.

### Fixed

- Skip `oc login` check in web and shell modes.

## [1.1.0] - 2026-03-24

### Added

- Streamlit web interface with Red Hat Consulting dark theme.
- Cluster connection via Bearer Token (login/disconnect from browser).
- Real-time progress bar.
- Download buttons for AsciiDoc and PDF.
- AsciiDoc to PDF converter in sidebar.
- Red Hat Quay Registry collector (23 collectors total).
- OpenShift Virtualization section.
- SafeShift Doc Gen logo and Red Hat favicon.
- Go CLI renamed to `ssdg`.
- `--port`/`-p` flag for custom web port.
- tmpfs-based container execution (no permission issues, zero data retention).
- `QUICKSTART.md`.

### Changed

- `--web` mode uses tmpfs instead of volume mounts.
- Engagement description translates per language (PT/EN/ES).
- Product detection verifies actual installation.
- Python comments and docstrings translated to English.
- Emojis replaced: checkmark to `[OK]`, cross to `[ERROR]`.
- Container image includes Ruby plus asciidoctor-pdf.

### Fixed

- Container file write permissions (tmpfs).
- Jinja2 whitespace breaking the PDF title page.
- Template rendering regression (`ChainableUndefined` plus `is mapping` guards).
- Chapter-label and toc-title for PDF.
- Entrypoint exec pipe that broke thread execution.

### Removed

- Deprecated Dockerfile (`Containerfile` is the standard).
- VERSION file, obsolete scripts, 21 redundant docs consolidated into 8.

## [1.0.1] - 2026-03-22

### Added

- Full i18n for all 11 remaining templates.
- Multi-language output (pt_BR, en_US, es_ES).
- Security hardening (input sanitization, safe defaults).

### Fixed

- CI test for must-gather path validation.
- Node.js 24 compatibility for GitHub Actions.

## [1.0.0] - 2025-12-27

### Added

- Initial release.
- 22 data collectors for OpenShift cluster documentation.
- AsciiDoc output with Red Hat Consulting theme.
- Live cluster and must-gather (offline) modes.
- Data sanitization for sensitive information.
- Container support with multi-architecture builds.
- PDF generation with custom theme and fonts.

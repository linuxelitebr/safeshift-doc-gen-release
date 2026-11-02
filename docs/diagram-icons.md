# Diagram icons

The topology diagram draws each component as a stencil: the Kubernetes heptagons for the control plane and core resources, a colored heptagon per category for operators and platform services (monitoring, GitOps, virtualization, security and so on), and plain glyphs for hosts, load balancers, disks and network gear. The Node Network Design gives every card a small icon tile (NIC, bond, bridge, VLAN, gateway and the rest) from the same sets, recolored and put on a rounded square. Those built-in stencils come from license-clean sources (Kubernetes community icons, IBM Carbon, Tabler, Bootstrap Icons) and ship with SSDG. The provenance of every file is in `assets/topology-icons/ATTRIBUTION.txt`.

What SSDG does not ship is logos. Prometheus, Argo CD, KubeVirt, Loki, Ceph, Quay, F5, Hitachi and the Red Hat marks are trademarks, and their projects publish them under trademark guidelines, not a license you can redistribute in a public repo or a container image. So the diagram uses a generic stencil for them unless you point SSDG at your own icons.

## Using your own icons

Put the files in a directory, named after the key they replace, as `<key>.svg` or `<key>.png`. A `.svg` wins over a `.png` for the same key. Then set `diagram.icons_override_dir` in your config, or the `SSDG_DIAGRAM_ICONS_DIR` environment variable, which wins over the config value.

For a local run:

```bash
SSDG_DIAGRAM_ICONS_DIR=~/stencils/ssdg python3 cli.py --client "Acme Corp" --output output/acme.adoc
```

In the container, mount the directory read-only and point the variable at the mount. The web interface, with the two extra lines for the icons:

```bash
podman run --rm -p 5050:5000 \
  -v $(pwd)/output:/app/output \
  -v ~/stencils/ssdg:/icons:ro,Z \
  -e SSDG_DIAGRAM_ICONS_DIR=/icons \
  ghcr.io/elastocera/safeshift-doc-gen:latest --web
```

Keep the directory apart from the document output. Pointed at `<doc>.diagram-icons`, the folder SSDG writes the diagram icons to, it is never swept, and the diagram for that document is drawn without icons, because exporting the stencils there would overwrite your files. Your files are used byte for byte. SSDG never recolors, crops or edits an override, which is also what most logo guidelines ask for. Copy the files into the directory: symlinks are not followed, not even ones that point back into the same directory.

Overriding a built-in also covers the logo slots that fall back to it: drop your own `monitoring.svg` and the `prometheus` and `alertmanager` slots use it too, unless they have a file of their own.

## Keys

Built-in stencils, any of which you can override:

| Group | Keys |
|-------|------|
| Control plane | `etcd`, `api`, `scheduler`, `controller-manager`, `cloud-controller-manager` |
| Kubernetes resources | `pod`, `node`, `ingress`, `service`, `pv`, `storageclass` |
| Platform services | `monitoring`, `alerting`, `logging`, `gitops`, `pipelines`, `serverless`, `servicemesh`, `registry`, `backup`, `certificates`, `security`, `compliance`, `operator`, `fleet`, `odf`, `nmstate`, `metallb`, `vm` |
| Hosts and gear | `server`, `user`, `lb`, `switch`, `router`, `disk`, `nic`, `hba`, `san` |
| Node Network Design tiles | `nnd-nic`, `nnd-bond`, `nnd-bridge`, `nnd-vlan`, `nnd-switch` (the upstream switch), `nnd-gateway` (also the custom routes card), `nnd-dns`, `nnd-cni`, `nnd-servicenet`, `nnd-podnet` |

Logo slots, with no built-in of their own. Without an override they fall back to the stencil in the second column:

| Key | Falls back to |
|-----|---------------|
| `prometheus` | `monitoring` |
| `alertmanager` | `alerting` |
| `loki` | `logging` |
| `argocd` | `gitops` |
| `tekton` | `pipelines` |
| `knative` | `serverless` |
| `istio` | `servicemesh` |
| `velero`, `oadp` | `backup` |
| `ceph`, `rook` | `odf` |
| `cert-manager` | `certificates` |
| `kubevirt` | `vm` |
| `rhacs`, `stackrox` | `security` |
| `quay` | `registry` |
| `acm`, `mce` | `fleet` |
| `coreos` | `server` |
| `hitachi`, `netapp`, `dell`, `hpe`, `pure`, `ibm`, `vsphere`, `aws`, `azure`, `gcp`, `openstack`, `lvms`, `nfs`, `hostpath`, `kubevirt-csi`, `generic` (a CSI driver SSDG does not recognize) | `disk` |
| `f5` | `lb` |
| `firewall`, `waf`, `proxy` | `router` |
| `switch-vendor` | `switch` |
| `openshift` | nothing, it only shows up when you provide it |

## What gets rejected

An override that fails any of these checks is skipped with a warning in the log, and the built-in stencil is drawn instead. Nothing is ever fixed up.

- A symlink, anything that is not a regular file, an unreadable file, or a file larger than 1 MiB.
- A PNG that does not start with the PNG signature.
- An SVG that is not strictly inert. Only drawing elements get through (shapes, groups, gradients, clip paths, masks, styles, titles, editor metadata). Rejected: a DOCTYPE, processing instructions such as `<?xml-stylesheet?>`, scripts, event handlers, `foreignObject`, `<a>`, `<image>`, animation elements, `xml:base`, `src`, CSS at-rules such as `@import`, and any link or `url()` that points outside the file.
- With the PDF embed on (`--diagram-embed`), an SVG that d2's PNG renderer cannot draw. The PDF gets the diagram as a PNG, and that renderer does not do gradients, masks or text inside icons, so SSDG asks d2 about each override before using it. Plenty of vendor logos use gradients, so if yours gets rejected for this, a PNG of the same logo works. Without the embed nothing is drawn as a PNG, and the check is skipped.

## Credits and licenses

The built-in stencils are modified versions of upstream icons, so they carry the upstream licenses along. SSDG credits exactly the icon sets a diagram uses, in two places.

The PDF, when the diagram is embedded, ends with a "Diagram icon credits" chapter. It has one line per icon set (name, copyright holder, SPDX id and license URL) and then the full license texts, printed as the icon sets publish them. Apache-2.0 prints once for IBM Carbon and the Kubernetes icons, since both ship the same terms and the credit lines already carry each copyright. Each MIT text prints on its own, because the copyright line is part of it. The chapter prints whether or not the metadata footer is on: it is a license obligation, not metadata. Each embedded diagram owes the sets behind its own icons: the Node Network Design tiles bring in Bootstrap (the NIC) and Tabler (the gateway and DNS cards) next to Carbon and the Kubernetes heptagons, so a PDF with that diagram prints both MIT texts. A diagram drawn with none of the built-ins gets no credit lines, and a diagram that did not make it into the PDF credits nothing.

`<doc>.diagrams.zip` carries a generated `ATTRIBUTION.txt` with the same credits and a `LICENSES/` directory with the license text of every icon set inside, plus `OFL-1.1.txt` whenever an icon or an SVG is in the zip: d2 embeds a subset of the Red Hat Text font in every SVG it draws, and the Kubernetes stencil labels are outlines of the same font. The `assets/topology-icons/ATTRIBUTION.txt` in the repo is the per-stencil provenance for maintainers, not what ships to a customer.

When one of your own logos is drawn, the zip and the chapter (when the PDF has one) add a line saying project and vendor logos are trademarks of their owners and appear for identification only. Your logos are yours to license, so SSDG says nothing else about them.

## Rebuilding the built-in stencils

The stencils under `assets/topology-icons/stencils/` are generated from the upstream files in `vendor/`, which are pinned by commit and sha256 in `sources.json`. Nobody edits them by hand. After changing `sources.json`, rebuild them:

```bash
python3 tools/icons/build_topology_icons.py
```

Check that the committed stencils match what the script produces (the test suite runs the same check):

```bash
python3 tools/icons/build_topology_icons.py --check
```

The small labels inside the Kubernetes heptagons (`api`, `sched`, `c-m`, `etcd` and the rest) are drawn as outlines, because d2's PNG renderer cannot draw text, and without them the four control-plane icons are the same gear. The outlines come from Red Hat Text Bold, which ships in `fonts/` under the SIL Open Font License, and live in `labels.json`, so the build itself needs nothing beyond the standard library. Regenerating them is a maintainer job that needs fontTools, and only matters when a labeled upstream icon or the font changes:

```bash
python3 tools/icons/make_label_paths.py
```

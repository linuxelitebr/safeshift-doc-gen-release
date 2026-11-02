# Third-party licenses

SafeShift Doc Gen ships under the Apache License 2.0 (see `LICENSE`). The libraries and assets listed below are bundled or pulled in at install time and carry their own license terms. Attribution lives here so we stay honest about what we depend on.

## Python runtime dependencies

These are installed from PyPI via `requirements.txt` and ship inside the container image. All are compatible with Apache-2.0.

| Package | License | Upstream |
|---------|---------|----------|
| PyYAML | MIT | https://github.com/yaml/pyyaml/blob/main/LICENSE |
| Jinja2 | BSD-3-Clause | https://github.com/pallets/jinja/blob/main/LICENSE.txt |
| requests | Apache-2.0 | https://github.com/psf/requests/blob/main/LICENSE |
| Flask | BSD-3-Clause | https://github.com/pallets/flask/blob/main/LICENSE.txt |
| Pillow | MIT-CMU (HPND-like) | https://github.com/python-pillow/Pillow/blob/main/LICENSE |
| defusedxml | PSF-2.0 | https://github.com/tiran/defusedxml/blob/main/LICENSE |

## Python development dependencies

Installed via `requirements-dev.txt` for contributors and CI. Not present in the production container.

| Package | License | Upstream |
|---------|---------|----------|
| python-minifier | BSD-3-Clause | https://github.com/dflook/python-minifier/blob/master/LICENSE |
| black | MIT | https://github.com/psf/black/blob/main/LICENSE |
| flake8 | MIT | https://github.com/PyCQA/flake8/blob/main/LICENSE |
| mypy | MIT | https://github.com/python/mypy/blob/master/LICENSE |
| pytest | MIT | https://github.com/pytest-dev/pytest/blob/main/LICENSE |
| pytest-cov | MIT | https://github.com/pytest-dev/pytest-cov/blob/master/LICENSE |

## Container base image and tools

| Component | License | Notes |
|-----------|---------|-------|
| UBI9 (`registry.access.redhat.com/ubi9/python-312`, `ubi-minimal`) | UBI EULA (free redistribution) | https://access.redhat.com/articles/4238681 |
| `oc` (OpenShift CLI) | Apache-2.0 | Pinned via `OC_VERSION` build arg |
| `omc` | Apache-2.0 | Third-party, https://github.com/gmeghnag/omc |
| `d2` (diagram renderer) | MPL-2.0 | Pinned via `D2_VERSION` build arg, unmodified upstream binary from https://github.com/d2lang/d2. License, third-party notices and a source pointer ship at `/usr/share/licenses/d2/` in the image. |
| asciidoctor-pdf | MIT | https://github.com/asciidoctor/asciidoctor-pdf/blob/main/LICENSE.adoc |
| rouge (syntax highlighting) | MIT | https://github.com/rouge-ruby/rouge/blob/master/LICENSE |

## Fonts

| Font | License | Source |
|------|---------|--------|
| Red Hat Text | SIL Open Font License 1.1 | `fonts/OFL.txt` (in this repo) |
| Red Hat Mono | SIL Open Font License 1.1 | `fonts/OFL.txt` (in this repo) |

## Diagram icons

The topology diagram stencils live under `assets/topology-icons/`. The upstream SVGs are vendored verbatim at pinned commits (`sources.json` carries the commit and sha256 of each file), and `tools/icons/build_topology_icons.py` generates `stencils/` from them.

| Source | License | Pinned at |
|--------|---------|-----------|
| Kubernetes community icons (kubernetes/community) | Apache-2.0, taking the Apache side of their Apache-2.0 OR CC-BY-4.0 dual license | `a222663ef579` |
| IBM Carbon icons (carbon-design-system/carbon), generic glyphs only | Apache-2.0 | `c0e901686e5c` |
| Tabler Icons (tabler/tabler-icons), outline, no brand icons | MIT | v3.48.0 |
| Bootstrap Icons (twbs/icons), no brand icons | MIT | v1.13.1 |
| SSDG derived stencils (Kubernetes heptagon plus a Carbon glyph) | Apache-2.0, as derivative works | built from the above |
| Label outlines inside the Kubernetes icons (`labels.json`) | Drawn from Red Hat Text Bold, SIL OFL 1.1 (see Fonts above) | `tools/icons/make_label_paths.py` |

This file does not ship in the container image (the build drops `*.md`), so the image carries the same information in `assets/topology-icons/ATTRIBUTION.txt` and the license texts in `assets/topology-icons/LICENSES/`. Project and vendor logos (Prometheus, Argo CD, KubeVirt, Loki, Ceph, Red Hat and the rest) are not bundled; they are trademarks and only come from a local override directory.

## Front-end (PatternFly 6 + assets served from CDN)

The Flask UI loads PatternFly 6 stylesheets and Font Awesome icons from a CDN at runtime (`gui/templates/layout.html`). PatternFly is MIT-licensed (https://github.com/patternfly/patternfly/blob/main/LICENSE). Font Awesome Free is licensed under SIL OFL 1.1 (fonts), MIT (code), and CC-BY 4.0 (icons). See https://fontawesome.com/license/free.

## Versions and updates

When you bump a vendored dependency or container component, update the corresponding row here in the same commit. Drift between this file and what actually ships erodes the only piece of attribution we owe upstream.

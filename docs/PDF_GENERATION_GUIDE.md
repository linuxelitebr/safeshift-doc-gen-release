# PDF Generation with Red Hat Consulting Theme

> **Heads-up:** the Red Hat Text fonts and Red Hat Consulting logos are already vendored under `fonts/` and `images/` in this repo. You usually do not need to download anything to generate a PDF with the default theme. The "Obtaining" section below is only useful when the bundled assets need to be refreshed or replaced.

## Directory Structure

```
safeshift-doc-gen/
├── styles/
│   └── pdf/
│       └── redhat-theme.yml    # Red Hat PDF theme (included)
├── fonts/
│   ├── RedHatText-Regular.ttf
│   ├── RedHatText-Bold.ttf
│   ├── RedHatText-Italic.ttf
│   └── RedHatText-BoldItalic.ttf
└── images/
    ├── Logo-Red_Hat-Consulting-A-Standard-RGB.png   # Red Hat logo
    ├── redhatConsulting.png                         # Cover page background
    └── customer-logo.png                            # Client logo (variable)
```

## Obtaining Red Hat Resources

### Red Hat Text Fonts

**Official download**:
```bash
curl -L https://github.com/RedHatOfficial/RedHatFont/raw/master/fonts/proportional/static/ttf/RedHatText-Regular.ttf \
  -o fonts/RedHatText-Regular.ttf

curl -L https://github.com/RedHatOfficial/RedHatFont/raw/master/fonts/proportional/static/ttf/RedHatText-Bold.ttf \
  -o fonts/RedHatText-Bold.ttf

curl -L https://github.com/RedHatOfficial/RedHatFont/raw/master/fonts/proportional/static/ttf/RedHatText-Italic.ttf \
  -o fonts/RedHatText-Italic.ttf

curl -L https://github.com/RedHatOfficial/RedHatFont/raw/master/fonts/proportional/static/ttf/RedHatText-BoldItalic.ttf \
  -o fonts/RedHatText-BoldItalic.ttf
```

### Red Hat Logos

**Sources**:
1. **Brand Central** (Red Hat access): https://brandcentral.redhat.com
2. **Your internal repository** of Red Hat assets
3. **Previous engagements** (reuse logos)

**Required files**:
- `Logo-Red_Hat-Consulting-A-Standard-RGB.png` - Header/footer
- `redhatConsulting.png` - Cover page background

### Client Logo

**Via CLI**:
```bash
./cli.py \
  --include-cover \
  --include-preface \
  --client "Example" \
  --client-logo images/example-logo.png \
  --output example-doc.adoc
```

**Automatic lookup** (future):
- Clearbit Logo API
- Google Custom Search
- Client website scraping

## Generating the PDF

### Full Command

Generate documentation with cover and preface:

```bash
./cli.py \
  --include-cover \
  --include-preface \
  --client "Example" \
  --client-logo images/example-logo.png \
  --document-title "Technical Documentation - Production Cluster" \
  --output cluster-doc.adoc
```

The easy way to the PDF is `--pdf` on the same command. It runs asciidoctor-pdf the way every SSDG path does (CLI, web UI, `/api/jobs`, ACM batch, the `ssdg` launcher): safe mode, jailed to the document's own directory (the jail covers `include::` and the output path; an image referenced by absolute path is still read, see docs/SECURITY.md), with the checks that keep a broken diagram embed out of the PDF. Without `--pdf`, the CLI prints that exact command at the end of the run, and `--pdf-only FILE` runs it for you on a document that already exists, in the look of the pack `--brand` picks.

To convert by hand from the repo root, with the document under `output/`:

```bash
asciidoctor-pdf --safe-mode safe --base-dir "$PWD/output" \
  -a pdf-theme="$PWD/styles/pdf/redhat-theme.yml" \
  -a pdf-fontsdir="$PWD/fonts" \
  -a imagesdir="$PWD" \
  "$PWD/output/cluster-doc.pt_BR.adoc" \
  -o "$PWD/output/cluster-doc.pt_BR.pdf"
```

Keep the paths absolute. With `--base-dir` set, asciidoctor-pdf resolves a relative `-o` against the jail, so `-o output/x.pdf` lands in `output/output/x.pdf`. Ask me how I know. Leave `--base-dir` out and safe mode jails to the working directory instead, which refuses any document outside it with "outside of jail". `imagesdir` is the repo root because that is where a relative `--client-logo images/x.png` resolves.

### Diagrams in the PDF (Alfa)

With `--diagram-embed` (or "Put the diagrams in the PDF" under Settings, Experimental features), the PDF gets the topology diagram, and the Node Network Design when it is drawn, each as a PNG on its own A4 landscape page at the end of the topology section. The document also closes with an icon credits chapter: one credit line per icon set in the picture and the full text of each license, printed whether or not the metadata footer is on. The flag turns the diagram on by itself; d2 renders the PNGs offline, and without d2 the PDF carries no diagram and the log says so.

For the PDF, the document embeds the PNGs as `image::{docdir}/<doc>.topology.png[...]` inside `ifdef::backend-pdf[]`, so they have to sit next to the `.adoc` when it converts. Any other backend, the `asciidoctor <doc>.adoc` HTML the CLI suggests included, gets the bare file name instead, so the HTML points at the PNG next to it and not at a path on the server. SSDG writes the PNGs next to the document, and every SSDG PDF conversion checks before and after:

- A PNG that is missing, empty or not a PNG: no conversion, and the message names the file.
- A PNG asciidoctor-pdf could not embed, or an image that is not in the finished PDF: the PDF is deleted, and the message names the file.

The reason is the fallback. asciidoctor-pdf exits 0 when an image does not embed and prints the alt text plus the absolute server path where the diagram should be, which is not something to hand a customer. Run by hand, asciidoctor-pdf skips these checks, so after a refusal the CLI does not print the manual command.

A copied or edited `.adoc` converts fine as long as its PNGs travel with it. `/api/convert-pdf` (the Convert to PDF page) takes a single file, so a document that embeds a diagram is refused there; convert it where SSDG wrote it, or delete its `image::{docdir}/...` blocks first. The SVGs and the diagram zip are the downloads. The PNGs are in no download list and `/api/jobs` has no format for them, but the GUI's download route serves any file in the output directory by its exact name, a PNG included, so do not count on them staying private.

### PDF Theme Variables

The Red Hat theme uses the following variables (defined in cover.adoc.j2):

- `:customer:` - Client name (appears in the footer)
- `:confidentiality:` - Classification (e.g., "Confidential")
- `:description:` - Engagement description (auto-generated)
- `:revnumber:` - Document version
- `:docstatus:` - Status (e.g., "in-progress", "final")

## Full Example

### 1. Prepare the Directory Structure

Create directories:

```bash
mkdir -p fonts images styles/pdf
```

Download fonts if they are not already present (commands above).

Copy Red Hat logos:

```bash
cp /path/to/redhat-logos/*.png images/
```

Copy the client logo:

```bash
cp /path/to/customer-logo.png images/example-logo.png
```

### 2. Generate Documentation

```bash
./cli.py \
  --include-cover \
  --include-preface \
  --client "Example" \
  --client-logo images/example-logo.png \
  --output docs/example-cluster-prod.adoc
```

**Auto-generated description**:
```
"Example - OpenShift cluster installation with support for
OpenShift Virtualization and Hosted Control Planes, management
through Red Hat Advanced Cluster Management (RHACM), and
orchestration via OpenShift GitOps (ArgoCD)"
```

### 3. Generate the PDF

```bash
asciidoctor-pdf \
  -a pdf-theme=styles/pdf/redhat-theme.yml \
  -a pdf-fontsdir=fonts \
  docs/example-cluster-prod.adoc \
  -o docs/example-cluster-prod.pdf
```

## Result

### Cover Page
```
+-----------------------------------------+
|   [Red Hat Consulting Logo]             |
|                                         |
|                                         |
|      [Example Logo]                     |
|                                         |
|                                         |
|  Consulting Engagement Report           |
|                                         |
|  Example - OpenShift cluster            |
|  installation with support for Hosted   |
|  Clusters and OpenShift Virtualization  |
|                                         |
|  Version 2025-12-26-14-30-00            |
+-----------------------------------------+
```

### Headers/Footers

**Header**: Red Hat Consulting Logo | [status: in-progress]

**Footer**:
- Left: Example | Confidential
- Center: Technical Documentation | [description]
- Right: Page X | v2025-12-26

## Troubleshooting

### Fonts Not Found

Verify fonts are present:

```bash
ls -la fonts/RedHatText*
```

If any of those files are missing, restore them with the curl commands from the **Obtaining Red Hat Resources > Red Hat Text Fonts** section above. There is no helper script. The four `curl -L` lines are the whole flow.

### Logo Not Appearing

Verify the path:

```bash
ls -la images/Logo-Red_Hat-Consulting-A-Standard-RGB.png
```

Test manually:

```bash
asciidoctor-pdf test.adoc -a imagesdir=images
```

### `the document embeds <doc>.topology.png, which is not next to it as a PNG`

The document was moved, copied or uploaded without its diagram PNGs. Convert it in the directory SSDG wrote it to, copy the `.topology.png` and `.network.png` files next to it, or remove the `image::{docdir}/...` blocks from the `.adoc`.

### Theme Not Applied

Verify the theme:

```bash
cat styles/pdf/redhat-theme.yml
```

Force a rebuild:

```bash
asciidoctor-pdf --trace cluster-doc.adoc
```

## Resources

- **AsciiDoc PDF**: https://docs.asciidoctor.org/pdf-converter/
- **Red Hat Fonts**: https://github.com/RedHatOfficial/RedHatFont
- **Red Hat Brand**: https://www.redhat.com/en/about/brand/standards

## Deployment Checklist

- [ ] Red Hat Text fonts downloaded
- [ ] Red Hat Consulting logo obtained
- [ ] Cover page background obtained
- [ ] Client logo copied
- [ ] PDF theme validated
- [ ] Test generation completed successfully
- [ ] PDF rendered correctly

# Brand packs

A brand pack is who issues the document: the PDF cover and page header, the issuer lines in the front matter (author, originator, owner, confidentiality text, executive summary), the provider side of the participants table, and an optional methodology chapter. The technical chapters never see it. SSDG ships three. `redhat` is the document every version before brand packs produced, and still the default; what differs from 1.16.0 are fixes every pack gets (chapter and version labels in the document language, a client logo that can no longer reach the title, the preface of a document without a client name). `linuxelite` is the worked example below, and `ibm` is the redhat document issued by IBM Consulting.

## Picking a pack

The choice for one document goes, strongest first: the per-run choice (the Document identity select in the GUI Settings, `--brand` on the CLI and on the `ssdg` launcher, the `brand` parameter on `/api/generate`, `/api/jobs` and `/api/convert-pdf`), then the `SSDG_BRAND` environment variable, then `branding.pack` in the config, then `redhat`. An id no pack has is an error that lists the packs that exist, before anything runs. The ACM batch resolves the pack once and uses it for every cluster.

Which config: the CLI reads `branding.pack` from its own `--config`. The GUI and the HTTP API always read it from `config/default.yaml`, whatever the config file field in Settings says, so the "Issued as" line and the "Server default" option name the pack the document really gets.

On the CLI:

```bash
python3 cli.py --client "Acme Corp" --brand linuxelite --pdf -o output/acme.adoc
```

## Where packs come from

Built-in packs live in `brands/<id>/` in the repo. Extra packs come from a read-only directory you name with `SSDG_BRAND_DIR`, one subdirectory per pack. SSDG reads both once at startup. A pack that fails a check is skipped with a warning in the log, and a built-in id always wins over an extra pack with the same id. There is no upload: a pack is something the operator mounts, not something a user sends.

What passes the checks gets copied, theme and images, into a private snapshot (a mode 0700 temporary directory, removed when the process exits), and asciidoctor-pdf only ever reads that copy. Editing a pack on disk changes nothing until the next start, which is the point: nobody gets to swap a file in after it was checked.

In the container, mount the directory and point the variable at it, plus `SSDG_BRAND` if the pack should be the default:

```bash
podman run --rm -p 5050:5000 \
  -v $(pwd)/output:/app/output \
  -v ~/ssdg-brands:/brands:ro,Z \
  -e SSDG_BRAND_DIR=/brands \
  -e SSDG_BRAND=acme \
  ghcr.io/elastocera/safeshift-doc-gen:latest --web
```

## On OpenShift

Four ways to get a pack into the pod. Whichever you pick, set `SSDG_BRAND_DIR` to the directory that holds the pack directories, and restart the pod after changing a pack.

**ConfigMap.** One ConfigMap per pack, mounted at `/brands/<id>`. kubelet turns every entry into a symlink into a `..data` directory; that is fine, symlinks that stay inside the pack are followed. A ConfigMap key cannot contain `/`, so the language files go in under flat keys and the volume's `items` puts them back in `i18n/`. `oc create configmap --from-file` stores the images in `binaryData` on its own. The whole ConfigMap has to fit in 1 MiB, so a big cover image wants one of the options below.

Create the ConfigMap from the pack directory:

```bash
oc create configmap ssdg-brand-acme --from-file=acme/brand.yaml --from-file=acme/theme.yml --from-file=acme/NOTICE --from-file=acme/cover.png --from-file=acme/logo.png --from-file=i18n-en_US.yaml=acme/i18n/en_US.yaml --from-file=i18n-pt_BR.yaml=acme/i18n/pt_BR.yaml --from-file=i18n-es_ES.yaml=acme/i18n/es_ES.yaml
```

Then mount it in the Deployment, with every key listed under `items` (a key left out of the list is not mounted) and `SSDG_BRAND_DIR=/brands` in the container env:

```yaml
volumes:
  - name: brand-acme
    configMap:
      name: ssdg-brand-acme
      items:
        - {key: brand.yaml, path: brand.yaml}
        - {key: theme.yml, path: theme.yml}
        - {key: NOTICE, path: NOTICE}
        - {key: cover.png, path: cover.png}
        - {key: logo.png, path: logo.png}
        - {key: i18n-en_US.yaml, path: i18n/en_US.yaml}
        - {key: i18n-pt_BR.yaml, path: i18n/pt_BR.yaml}
        - {key: i18n-es_ES.yaml, path: i18n/es_ES.yaml}
containers:
  - name: safeshift-doc-gen
    volumeMounts:
      - {name: brand-acme, mountPath: /brands/acme, readOnly: true}
```

**Secret.** The same layout with `oc create secret generic` and a `secret:` volume, for a pack whose logo is not public yet. Same 1 MiB limit.

**PVC.** A volume mounted read-only at `/brands`, one directory per pack. No size limit, and the only option where somebody can write to the files while the pod runs, which the snapshot makes harmless.

**Image layer.** Build your own image on top of SSDG with the packs copied in, for example with these Containerfile lines:

```dockerfile
FROM ghcr.io/elastocera/safeshift-doc-gen:latest
COPY --chown=1001:0 brands/ /opt/ssdg-brands/
ENV SSDG_BRAND_DIR=/opt/ssdg-brands
```

## What a pack holds

```
acme/
├── brand.yaml          # id, display name, company, methodology on or off, the images it uses
├── theme.yml           # the brand part of the PDF theme: cover, header, footer, colors
├── cover.png           # whatever images brand.yaml lists
├── logo.png
├── i18n/
│   ├── en_US.yaml      # the identity strings, one file per document language
│   ├── pt_BR.yaml
│   └── es_ES.yaml
└── NOTICE              # who owns the marks in this pack
```

`brand.yaml` takes exactly these keys:

```yaml
id: acme                 # same as the directory name: a-z, 0-9 and '-', 2 to 32 characters
name: Acme Consulting    # display name, the GUI's "Issued as"
company: Acme            # titles the provider side of the participants table
methodology: true        # false drops the methodology chapter
images:                  # letters, digits, '.', '_' and '-', with '/' between parts
  - cover.png
  - logo.png
```

`theme.yml` carries only the brand, from a short list of keys; anything else is refused. SSDG loads `styles/pdf/ssdg-base-theme.yml` first (fonts, tables, headings, code, footer) and your theme on top. The list:

- the cover: `title-page` background color and image, logo image and position, and the color, size, style, alignment and position of the title, subtitle, authors and revision;
- the page: `page` background color and image (`recto` and `verso` too);
- header and footer: height, border color, width and style, background color and image, padding, vertical alignment, font color, and the `recto`/`verso` `left`/`center`/`right` content;
- font colors of `base`, `link`, `heading` and `h1` to `h6`, `toc` and the table head, plus the font style of headings and links.

An image value is `none`, a name `brand.yaml` lists, or `image:<listed name>[attributes]`. Header and footer content is plain text, images `brand.yaml` lists, and the page attributes `page-number`, `page-count`, `document-title`, `document-subtitle`, `part-title`, `chapter-title`, `section-title`, `section-or-chapter-title`, `docstatus`, `customer`, `confidentiality`, `description-short`, `revnumber`, `revdate`, `author`, `nbsp`, `sp`, `zwsp` and `empty`. No `$variables` anywhere. `brands/redhat/theme.yml` is the reference. Every pack keeps the bundled Red Hat Text fonts, because table widths and print sizes elsewhere in SSDG were measured with them.

The strings use the same keys in every language file. Copy `brands/redhat/i18n/en_US.yaml` and rewrite it: `cover.author`, the five `preface.confidentiality_*` paragraphs, `main.originator_text`, `main.owner_text`, `main.engagement_intro`, `main.additional_copies_text`, `main.executive_summary_p1` to `p4`, and with `methodology: true` also `methodology.title` and `methodology.p1` to `p4`. `methodology.link_text` with `methodology.link_url` is optional, both or neither; the chapter ends on that link, and the URL has to be plain https.

The strings are plain text with inline formatting. `*bold*`, `_italic_`, `` `mono` ``, bare URLs and a line starting with `* ` for a list item all work. What does not: brackets, `{{` and `}}`, `+++`, a line break other than one at the very end, a string that starts with `:` or is a block delimiter (`////`, `----`, `++++` and friends), and a trailing backslash. Every AsciiDoc construct that can pull a file into the document or swallow the rest of it needs one of those, so a pack can word the document but cannot reach past its own text. The `company` in `brand.yaml` follows the same rules, braces included.

Placeholders are the ones the template passes for that key: `{client_name}` in the confidentiality intro, `{year}` in the copyright line, `{client_label}` and `{client_name}` in the engagement intro, `{client_name}` and `{description}` in the first summary paragraph. A pack may use fewer, never others, and every language uses the same ones.

## A worked example: linuxelite

`brands/linuxelite/` is the second built-in pack, and the one to copy: it changes everything a pack can change and nothing else.

```
linuxelite/
├── brand.yaml
├── theme.yml
├── cover.svg           # the light "Prompt" cover, full page
├── logo-header.png     # the wordmark in the page header, 1400x269
├── logo.svg            # vector master of the wordmark, not listed, never reaches a PDF
├── i18n/
│   ├── en_US.yaml
│   ├── pt_BR.yaml
│   └── es_ES.yaml
└── NOTICE
```

`brand.yaml` lists the two images the PDF uses. `logo.svg` lives in the directory without being listed, which is fine: the snapshot takes only what `brand.yaml` lists, so an unlisted file just rides along for whoever edits the art next.

```yaml
id: linuxelite
name: Linux Elite
company: Linux Elite
methodology: true
images:
  - cover.svg
  - logo-header.png
```

`theme.yml` is short because the base theme does the heavy lifting. The cover is `cover.svg` as the full-page background, the title left-aligned in charcoal at 60% of the page, and the client name, which is the subtitle, in blue. The header carries the wordmark at 30 mm on the left and the document status on the right, over a grey rule. `verso` repeats `recto`:

```yaml
title-page:
  text-align: left
  background-image: image:cover.svg[]
  title:
    top: 60%
    font-color: '#202020'
  subtitle:
    font-color: '#1480d8'
  logo:
    top: 30vh

header:
  height: 19mm
  border-color: #B7B7B7
  recto:
    left:
       content: image:logo-header.png[pdfwidth=30mm]
    center:
       content:
    right:
       content: |
                 {docstatus}
```

Both SVGs are paths and shapes only. The wordmark is drawn as outlines, so the PDF needs no font for it, and the font the design started from, a demo font that is not ours to ship, stays out of the repo. It also keeps both files inside the inert SVG allowlist: no `<text>`, no external references, no script. If a designer hands you an SVG with live text, convert the text to outlines before it goes in. Loosening the checker is not on the menu.

The client logo belongs to the document, not to the pack. It sits centred at 30% of the page height, half the content width wide but never more than 60 mm tall, so on A4 it is done by 150 mm. The one exception is a logo more than twelve times taller than wide: its width stops at 5 mm and it runs longer, because a hairline at pdfwidth=0.0mm helps nobody. Cover art meant to sit by the title starts below that: the linuxelite bar starts at 165.5 mm, the title at 171 mm.

The strings were written for Linux Elite in all three languages, not copied from `redhat` with the name swapped: the confidentiality text, the originator and owner lines, the engagement intro, the executive summary and the methodology chapter, Ground Truth (observe, map, close, hand over), which ends on a link to https://linuxelite.com.br/. `tests/test_brand_linuxelite.py` checks that no string makes a Red Hat claim and that the art carries no font files and no text elements, and pins the pt_BR front matter in a golden.

Render a document with it:

```bash
python3 cli.py --client "Acme Corp" --brand linuxelite --pdf -o output/acme.adoc
```

## The ibm pack

`brands/ibm/` is the redhat pack with IBM Consulting as the issuer, for people delivering IBM Consulting engagements. The NOTICE says the marks belong to International Business Machines Corporation, so the Apache-2.0 license does not cover them.

The strings are the redhat ones with one rule applied: where Red Hat issues or owns the document, IBM Consulting does. That is the author, the confidentiality paragraphs, the originator and owner lines, the engagement intro, the additional copies line, the first executive summary paragraph and, through `company` in `brand.yaml`, the provider side of the participants table. Where Red Hat is the product vendor ("best practices recommended by Red Hat") it stays. The Navigate chapter is the redhat one word for word, still credited to Red Hat Consulting, because IBM delivers it as a Red Hat service, and so is the summary line that ties the engagement to it. `tests/test_brand_ibm.py` pins both halves of that rule.

The art is the official 8-bar logo, cleaned up for the SVG checks (no comment, no `enable-background`, no `xml:space`, plain numbers), used as is in the page header at 16 mm, and a white cover in the linuxelite layout: logo top left, a blue bar over the title, the client name in the logo blue `#1f70c1`, the title in `#161616`, and a block of the logo's stripes running off the right edge with its last bar in blue, level with the `ibm.com/consulting` footer.

Render a document with it:

```bash
python3 cli.py --client "Acme Corp" --brand ibm --pdf -o output/acme.adoc
```

## The checks

A pack comes off a volume somebody else filled, so SSDG checks all of it before using any of it:

- Every name a pack uses is relative, has no `..`, and still lands inside the pack once symlinks resolve. A symlink pointing outside is refused, and so is a symlinked pack directory.
- Image names are plain (see above), images are PNG, JPEG or SVG, the content has to match the extension, and SVGs go through the same inert allowlist as the diagram icon overrides (no script, no external references). Images are capped at 4 MiB, YAML files at 256 KiB.
- YAML goes through `yaml.safe_load`, after a pass that refuses aliases and nesting deeper than 32 levels. A parse error never quotes the file back into the log.
- `theme.yml` sets only keys from the list, each with a value of its kind, and names only images `brand.yaml` lists.
- Every document language is there, with every key, plain text as described, the allowed placeholders and the same ones in each language.
- `NOTICE` is there and not empty.

## The `:pdf-theme:` attribute

The cover carries `:pdf-theme: <pack id>`. It is a label, nothing more: SSDG passes `-a pdf-theme` and `-a pdf-themesdir` to asciidoctor-pdf on every conversion, and those win. Only `redhat` has a file of that name (`styles/pdf/redhat-theme.yml`), so to convert a document by hand use the command the CLI prints after a run without `--pdf`, which points at the pack's own directory, or let `cli.py --pdf-only FILE --brand <id>` run it.

## Through the ssdg launcher

`ssdg --brand linuxelite`, or `brand: linuxelite` in the launcher's `--config` file, picks the pack. With neither, `SSDG_BRAND` in your shell does. The launcher hands the choice to the container as `--brand` and the image's own rules take it from there: an id no pack has stops the run before it collects anything, and with no choice at all the image falls back to `branding.pack` and then `redhat`. With `--web` the choice becomes the server's `SSDG_BRAND`, the pack the pages start on.

The PDF goes through the CLI in the container, `pdf_render` and the pack included. `ssdg ... --pdf` keeps the PDF the CLI made, and `ssdg --pdf-only FILE` runs the CLI's `--pdf-only` on that file. Until this release the launcher converted a second time on its own with the Red Hat theme and wrote over the first PDF, so every launcher PDF came out red whatever the document said.

Convert an existing document in the linuxelite look:

```bash
ssdg --pdf-only output/acme-corp-2026-10-05.adoc --brand linuxelite
```

Two catches. The launcher picks among the packs in the image and does not mount `SSDG_BRAND_DIR`, so for an extra pack run the container directly as shown above. And the launcher floats on the image's major tag, so a cached image older than the launcher turns down `--brand` and `--pdf-only` with an argparse error. `ssdg --pull` once fixes it, and the launcher says so when the container exits with code 2.

## Tests

`tests/test_brand_pack.py` holds a broken pack for each check above, and `tests/test_brand_hostile.py` holds the attacks: strings, themes and image names that try to read a marker image or a neighbour document, edits after the checks, kubelet-style mounts and a pack that makes the XML parser throw. Its canaries render a PDF from anything that loads and check that nothing outside the pack got in. The built-in packs have to pass the same checks, `tests/test_brand_strings.py` reads their strings straight from the files, `tests/test_brand_equivalence.py` pins the `redhat` front matter against what 1.16.0 rendered, bar the label and preface fixes, and `tests/test_brand_linuxelite.py` and `tests/test_brand_ibm.py` cover the other two.

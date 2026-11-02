# SafeShift Doc Gen (ssdg) - Quick Start

Generate OpenShift cluster documentation in 2 steps.

## Prerequisites

- `podman` or `docker` installed
- The `ssdg` binary for your platform

| Platform | Binary |
|----------|--------|
| Linux (x86_64) | `ssdg-linux-amd64` |
| Linux (ARM) | `ssdg-linux-arm64` |
| macOS (Intel) | `ssdg-darwin-amd64` |
| macOS (Apple Silicon) | `ssdg-darwin-arm64` |
| Windows | `ssdg-windows-amd64.exe` |

After downloading, rename it and make it executable:

```bash
mv ssdg-darwin-arm64 ssdg
chmod +x ssdg
```

## Step 1 - Start the web interface

```bash
./ssdg --web
```

Open **http://localhost:5000** in your browser.

> **macOS:** port 5000 is bound by AirPlay Receiver by default. Either turn that off in *System Settings > General > AirDrop & Handoff*, or pick a different port:

```bash
./ssdg --web --port 9090
```

Same flag works on any host where 5000 is busy.

## Step 2 - Connect, generate, and download

1. On the **Dashboard**, enter your API Server URL and Bearer Token in the Cluster Connection card
2. To get the token: OpenShift web console > click your username (top right) > **Copy login command** > **Display Token**
3. Navigate to **Generate**, fill in the client name, choose the language and modules, then click **Generate Documentation**
4. Use the **Download** buttons to save the AsciiDoc and PDF files

> Files are stored in RAM inside the container. Download them before closing the terminal.

> **Already logged in via `oc`?** The Dashboard detects an existing `oc login` session on your machine and shows the cluster as connected without you filling the form. To force a manual login through the form, run `oc logout` first. Inside an OpenShift pod, the same detection picks up the ServiceAccount token automatically.

## Web interface overview

The PatternFly 6 interface has four pages:

| Page | Purpose |
|------|---------|
| **Dashboard** | Cluster connection, status cards, quick actions |
| **Generate** | Configure and generate documentation (single or ACM batch mode) |
| **Convert to PDF** | Upload an existing AsciiDoc file and convert it to PDF |
| **Settings** | Advanced options (config file, output directory, must-gather, verbose), saved to localStorage |

Additional features:

- **Dark/light theme toggle** in the top-right corner
- **Collapsible sidebar** via the hamburger icon
- **Real-time log console** at the bottom (click to expand, drag to resize)
- **Generation timestamp and file size** shown on each generated file

## CLI mode

For scripting or automation, use CLI mode instead of the web interface. Requires `oc login` on the host before running.

Basic:

```bash
./ssdg --client "Acme Corp" --lang en_US --pdf
```

Full options:

```bash
./ssdg --client "Acme Corp" \
  --company-description "Technology consulting" \
  --company-website acme.com \
  --logo images/logo.png \
  --lang pt_BR \
  --pdf
```

Output files are saved to the `./output/` directory.

## Common options

| Option | Description |
|--------|-------------|
| `--web` | Start web interface |
| `--port PORT` | Web interface port (default: 5000) |
| `--client NAME` | Company name (required in CLI mode) |
| `--lang LANG` | Language: `pt_BR`, `en_US`, `es_ES` |
| `--pdf` | Generate PDF along with AsciiDoc |
| `--logo FILE` | Client logo (PNG, JPG, WebP, or SVG) |
| `--company-website URL` | Company website |
| `--company-description TEXT` | Short company description |
| `--output FILE` | Output AsciiDoc filename (default auto-generated from client + date) |
| `--modules LIST` | Comma-separated collectors to run (default: all 24). Example: `cluster,nodes,storage` |
| `--must-gather DIR` | Offline mode from must-gather archive |
| `--acm-batch` | Document every managed cluster on an ACM Hub. See [ACM-BATCH-MODE.md](ACM-BATCH-MODE.md) |
| `--help` | Show all options |

## Offline mode (must-gather)

When you cannot connect to the cluster directly:

On a machine that does have cluster access, collect the must-gather:

```bash
oc adm must-gather --dest-dir=./must-gather
```

Generate documentation from the archive:

```bash
./ssdg --client "Acme Corp" --must-gather ./must-gather --pdf
```

## Troubleshooting

**"neither podman nor docker found"** Install podman or docker. The `ssdg` binary uses containers to run the documentation generator.

**"Not connected to any cluster" (web mode)** Use the login form in the browser with your API URL and Bearer Token.

**"not logged in to OpenShift" (CLI mode)** Run `oc login` before using CLI mode.

**PDF has missing fonts or broken layout** Use the **Convert to PDF** page in the web interface to regenerate the PDF with the Red Hat Consulting theme.

**"PDF generation requires asciidoctor-pdf" warning** This appears when running the Flask UI outside the container (e.g. `python3 gui/app.py`) without the `asciidoctor-pdf` Ruby gem installed. PDF options are disabled in this case. Use `ssdg --web` or `make run-web` to run inside the container where `asciidoctor-pdf` is pre-installed.

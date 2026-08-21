# PDF-OCR-Converter (Fedora)

Right-click a **PDF or image** in your file manager and convert it to an
editable **DOCX** using **Adobe PDF Services** OCR — with a language picker, a
progress window, and desktop notifications.

This is a **Fedora / GNOME** port of the cross-platform
[PDF-OCR-Converter](https://github.com/robitschmatthias-ui/PDF-OCR-Converter).
It keeps the original's Adobe OCR → DOCX pipeline and adapts the desktop
integration and installer to Fedora:

| | Original | This Fedora port |
|---|---|---|
| File manager | Nemo | **GNOME Files (Nautilus)** via `nautilus-python` |
| Package manager | `apt` | **`dnf`** |
| tkinter package | `python3-tk` | **`python3-tkinter`** |
| Notifications | plyer | plyer → **`notify-send`** fallback |
| OCR backend | Adobe PDF Services | Adobe PDF Services *(unchanged)* |
| Output | DOCX | DOCX *(unchanged)* |

## Features

- **PDFs *and* images.** Works on PDFs and on image scans/photos
  (`.jpg .jpeg .png .tif .tiff .bmp .gif .webp`). Images are wrapped into a PDF
  locally (via Pillow) and then run through the same Adobe OCR → DOCX path — so
  the same menu items handle both, and you can even mix PDFs and images in one
  selection.
- **Single / batch OCR → DOCX.** Select one or more files, right-click →
  *OCR to DOCX*. Each is saved next to the original as `<name>_OCR.docx`.
- **Merge & OCR.** Select 2+ files, right-click → *Merge & OCR to DOCX*. They are
  merged (in name order), OCR'd as one document, and saved as
  `<first>_OCR.docx`. The temporary merged file is securely deleted.
- **Language picker.** A dialog lets you choose the OCR language per run.
- **Progress + notifications.** An indeterminate progress window while Adobe
  works, then a desktop notification on success/failure.
- **Credentials kept out of the repo.** Stored at
  `~/.config/pdf-ocr-converter/.env` (`chmod 600`), never committed.

## Requirements

- Fedora Workstation (GNOME Files / Nautilus)
- Python 3.10+
- A free **Adobe PDF Services** account (Client ID + Client Secret) —
  see [`docs/adobe-credentials.md`](docs/adobe-credentials.md)

The installer pulls these system packages via `dnf` if missing:
`python3-tkinter`, `nautilus-python`, `python3-dbus`, `libnotify`.

## Install

**GNOME (Files / Nautilus):**

```bash
git clone https://github.com/lindabroders/pdf_ocr.git
cd pdf_ocr
bash install/fedora/install.sh
```

**KDE Plasma (Dolphin):**

```bash
git clone https://github.com/lindabroders/pdf_ocr.git
cd pdf_ocr
bash install/kde/install.sh
```

Both editions share the same converter and install location — they differ only
in how the right-click menu is registered (a Nautilus extension on GNOME, a
Dolphin service menu on KDE). The KDE installer pulls `python3-tkinter`,
`python3-dbus`, and `libnotify` (it does **not** need `nautilus-python`).

The installer will:

1. install any missing system packages with `dnf` (one sudo prompt),
2. **copy the app into `~/.local/share/pdf-ocr-converter`** (a permanent,
   out-of-the-way location) so the folder you cloned/downloaded is disposable,
3. create a `.venv` there and install the Python dependencies,
4. install the Nautilus right-click extension and restart Nautilus,
5. open the credential setup dialog on first run.

> Because everything is copied into `~/.local/share/pdf-ocr-converter`, you can
> **delete the cloned/downloaded folder afterwards** — the tool keeps working.
> To uninstall later, run `bash install/fedora/uninstall.sh` from that app
> folder (or just remove `~/.local/share/pdf-ocr-converter` and the extension
> file).

> If the right-click entries don't appear right away, log out and back in once
> so GNOME loads the new Nautilus extension.

## Configure Adobe credentials

Right-click any PDF → **OCR Settings**, or run:

```bash
bash install/fedora/setup_credentials.sh          # GUI
./.venv/bin/python src/setup_credentials.py --cli  # terminal
```

Full walkthrough (including how to get free Adobe credentials and the list of
supported OCR languages): [`docs/adobe-credentials.md`](docs/adobe-credentials.md).

## Usage

### From GNOME Files (Nautilus)

Right-click a PDF (or a selection of PDFs):

- **OCR to DOCX** — convert each selected PDF.
- **Merge & OCR to DOCX** — appears when 2+ PDFs are selected.
- **OCR Settings** — edit Adobe credentials / default language.

### From the command line

```bash
# Single or batch (PDFs and/or images)
./.venv/bin/python src/ocr_convert.py file1.pdf scan.jpg photo.png

# Merge several PDFs/images then OCR the combined document
./.venv/bin/python src/merge_and_ocr.py page1.png page2.png cover.pdf
```

Each conversion consumes **two** Adobe transactions (OCR + DOCX export).

## Uninstall

```bash
bash install/fedora/uninstall.sh
```

This removes the Nautilus extension only. Your credentials
(`~/.config/pdf-ocr-converter/`), the project directory, and its `.venv` are
left untouched — delete them manually if you want them gone.

## Project layout

```
.
├── src/
│   ├── config.py             # config dir + credential loading + logging
│   ├── ocr_convert.py        # OCR → DOCX, language dialog, progress, notify
│   ├── merge_and_ocr.py      # merge PDFs, then OCR the result
│   └── setup_credentials.py  # GUI/CLI credential setup + Adobe validation
├── install/fedora/           # GNOME edition
│   ├── install.sh            # dnf + venv + Nautilus extension installer
│   ├── uninstall.sh
│   ├── ocr_convert.sh        # venv wrappers (shared with the KDE edition)
│   ├── merge_and_ocr.sh
│   ├── setup_credentials.sh
│   ├── pdf-ocr-converter.desktop  # app/dock entry (name + icon)
│   └── nautilus-extension/
│       └── pdf_ocr_converter.py   # Nautilus MenuProvider (right-click menu)
├── install/kde/              # KDE Plasma edition
│   ├── install.sh            # dnf + venv + Dolphin service-menu installer
│   ├── uninstall.sh
│   └── pdf-ocr-converter.desktop  # Dolphin service menu (right-click menu)
├── docs/adobe-credentials.md
├── requirements.txt
├── .env.example
├── pdf-ocr-icon.svg
└── LICENSE                   # GPL-3.0
```

## Troubleshooting

- **Right-click menu missing** — confirm `rpm -q nautilus-python` succeeds,
  then `nautilus -q` (or log out/in). The extension lives at
  `~/.local/share/nautilus-python/extensions/pdf_ocr_converter.py`.
- **"OCR setup needed"** — no credentials yet; open *OCR Settings*.
- **Errors / stack traces** — see `~/.config/pdf-ocr-converter/ocr.log`.

## License

GPL-3.0 — see [`LICENSE`](LICENSE). Ported from
[robitschmatthias-ui/PDF-OCR-Converter](https://github.com/robitschmatthias-ui/PDF-OCR-Converter),
which is also GPL-3.0.

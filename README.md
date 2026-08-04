# PDF-OCR-Converter (Fedora)

Right-click a PDF in **GNOME Files (Nautilus)** and convert it to an editable
**DOCX** using **Adobe PDF Services** OCR — with a language picker, a progress
window, and desktop notifications.

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

- **Single / batch OCR → DOCX.** Select one or more PDFs, right-click →
  *OCR to DOCX*. Each file is saved next to the original as `<name>_OCR.docx`.
- **Merge & OCR.** Select 2+ PDFs, right-click → *Merge & OCR to DOCX*. They are
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

```bash
git clone https://github.com/lindabroders/pdf_ocr.git
cd pdf_ocr
bash install/fedora/install.sh
```

The installer will:

1. install any missing system packages with `dnf` (one sudo prompt),
2. create a `.venv` and install the Python dependencies,
3. install the Nautilus right-click extension and restart Nautilus,
4. open the credential setup dialog on first run.

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
# Single or batch
./.venv/bin/python src/ocr_convert.py file1.pdf file2.pdf

# Merge several PDFs then OCR the combined document
./.venv/bin/python src/merge_and_ocr.py chapter1.pdf chapter2.pdf
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
├── install/fedora/
│   ├── install.sh            # dnf + venv + Nautilus extension installer
│   ├── uninstall.sh
│   ├── ocr_convert.sh        # venv wrappers invoked by the extension
│   ├── merge_and_ocr.sh
│   ├── setup_credentials.sh
│   └── nautilus-extension/
│       └── pdf_ocr_converter.py   # Nautilus MenuProvider (right-click menu)
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

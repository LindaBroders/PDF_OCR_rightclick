# Getting Adobe PDF Services API credentials

PDF-OCR-Converter uses **Adobe PDF Services** for OCR and PDF→DOCX export.
Adobe offers a **free tier** (at the time of writing, 500 free document
transactions per month). OCR + DOCX export uses **two** transactions per file.

## 1. Create a project and credentials

1. Go to the Adobe PDF Services API page:
   <https://developer.adobe.com/document-services/apis/pdf-services/>
2. Sign in with (or create) a free Adobe account.
3. Click **Get credentials** / **Create new credentials**.
4. Choose the **Service Principal (OAuth Server-to-Server)** credential type.
5. Adobe generates a **Client ID** and **Client Secret**. Keep these safe.

> You may also receive a `pdfservices-api-credentials.json` / private key
> bundle. This tool only needs the **Client ID** and **Client Secret** — the
> OAuth Server-to-Server flow used by the SDK does not require the private key
> file.

## 2. Enter the credentials in the tool

Run the settings dialog (any of these):

- Right-click a PDF in GNOME Files → **OCR Settings**, or
- `bash install/fedora/setup_credentials.sh`, or
- `./.venv/bin/python src/setup_credentials.py`
- Add `--cli` to the last command for a terminal-only prompt.

Enter the Client ID and Client Secret, pick a default OCR language, and click
**Test** to validate against Adobe (this does **not** consume a transaction),
then **Save**.

Credentials are stored at:

```
~/.config/pdf-ocr-converter/.env   (chmod 600)
```

They are **never** written into the project directory or committed to git.

## 3. Supported OCR locales

The default locale is used unless you change it in the language dialog before
each conversion. Supported values:

```
de-de, de-ch, en-us, en-gb,
fr-fr, it-it, es-es, nl-nl, pt-br,
da-dk, fi-fi, nb-no, sv-se,
cs-cz, pl-pl, hu-hu, ro-ro, sk-sk, sl-si, hr-hr,
bg-bg, el-gr, et-ee, lt-lt, lv-lv, mk-mk, mt-mt,
ru-ru, tr-tr, uk-ua,
ja-jp, ko-kr, zh-cn, zh-hk,
iw-il
```

If a locale is not recognized by the installed SDK, the tool falls back to
`en-us`.

## Troubleshooting

- **"Adobe rejected the credentials"** — double-check the Client ID/Secret and
  that the credential type is *OAuth Server-to-Server*.
- **Nothing happens on right-click** — make sure `nautilus-python` is
  installed and log out/in once so GNOME loads the extension.
- **Logs** — errors are written to `~/.config/pdf-ocr-converter/ocr.log`.

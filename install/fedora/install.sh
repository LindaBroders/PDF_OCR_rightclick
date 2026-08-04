#!/usr/bin/env bash
# Installer for PDF-OCR-Converter (Fedora / GNOME Files).
#
# Fully self-contained:
#   - Checks required system packages and installs any missing ones via dnf
#     (asks for the sudo password once)
#   - Detects and repairs a broken .venv from a previous failed run
#   - Creates a Python venv and installs the Python dependencies
#   - Installs the GNOME Files (Nautilus) right-click extension
#   - Launches the credential setup dialog on first install
#   - Shows a live spinner during long-running steps
#
# Usage: bash install/fedora/install.sh

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "${SCRIPT_DIR}/../.." && pwd )"
EXT_DIR="${HOME}/.local/share/nautilus-python/extensions"
EXT_NAME="pdf_ocr_converter.py"

printf 'PDF-OCR-Converter Installer (Fedora)\n'
printf '=====================================\n'
printf 'Project directory:   %s\n' "${PROJECT_DIR}"
printf 'Nautilus extension:  %s/%s\n' "${EXT_DIR}" "${EXT_NAME}"
printf '\n'

# --- Spinner helper ---
# Usage: _spin "Label text" command [args...]
# Runs the command in the background and animates a Braille spinner until it
# finishes. On failure, prints the captured output and exits the installer.
_spin() {
    local msg="$1"; shift
    local frames=('⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' '⠋' '⠙' '⠹')
    local log_file
    log_file="$(mktemp /tmp/pdf-ocr-install.XXXXXX)"
    local i=0

    "$@" >"$log_file" 2>&1 &
    local pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        printf '\r[%s] %s ...' "${frames[$((i % 10))]}" "$msg"
        i=$((i + 1))
        sleep 0.12
    done

    local rc=0
    wait "$pid" || rc=$?
    if [ $rc -ne 0 ]; then
        printf '\r\033[K[✗] %s\n' "$msg"
        sed 's/^/    /' "$log_file"
        rm -f "$log_file"
        exit 1
    fi
    printf '\r\033[K[✓] %s\n' "$msg"
    rm -f "$log_file"
}

# --- Preflight: required system packages ---
install_system_packages() {
    local missing=()

    if ! command -v python3 >/dev/null 2>&1; then
        missing+=("python3")
    fi

    # tkinter powers the language/settings dialogs
    if ! python3 -c "import tkinter" >/dev/null 2>&1; then
        missing+=("python3-tkinter")
    fi

    # nautilus-python provides the GNOME Files right-click integration
    if ! rpm -q nautilus-python >/dev/null 2>&1; then
        missing+=("nautilus-python")
    fi

    # libnotify (notify-send) is the desktop-notification fallback
    if ! command -v notify-send >/dev/null 2>&1; then
        missing+=("libnotify")
    fi

    # python3-dbus lets plyer post notifications over the session bus
    if ! rpm -q python3-dbus >/dev/null 2>&1; then
        missing+=("python3-dbus")
    fi

    # ensurepip must be present so `python3 -m venv` can bootstrap pip
    if ! python3 -c "import ensurepip" >/dev/null 2>&1; then
        printf '[✗] Python venv support (ensurepip) is missing.\n'
        printf '    Install/repair it with: sudo dnf install python3\n'
        exit 1
    fi

    if [ ${#missing[@]} -eq 0 ]; then
        printf '[✓] System packages present\n'
        return 0
    fi

    printf '[→] Missing packages: %s\n' "${missing[*]}"
    if ! command -v dnf >/dev/null 2>&1; then
        printf '[✗] dnf not found. This installer targets Fedora. Install manually: %s\n' "${missing[*]}"
        exit 1
    fi

    printf '[→] Installing via dnf (you may be prompted for your sudo password)...\n'
    sudo dnf install -y "${missing[@]}"

    # Verify the critical ones actually landed
    python3 -c "import tkinter" >/dev/null 2>&1 \
        || { printf '[✗] tkinter still missing after install\n'; exit 1; }
    rpm -q nautilus-python >/dev/null 2>&1 \
        || { printf '[✗] nautilus-python still missing after install\n'; exit 1; }
    printf '[✓] System packages installed\n'
}
install_system_packages

# --- Python venv ---
VENV_DIR="${PROJECT_DIR}/.venv"
if [ -d "${VENV_DIR}" ] && [ ! -f "${VENV_DIR}/bin/activate" ]; then
    printf '[→] Removing a broken venv from a previous run...\n'
    rm -rf "${VENV_DIR}"
fi

if [ ! -d "${VENV_DIR}" ]; then
    _spin "Creating Python venv" python3 -m venv "${VENV_DIR}"
else
    printf '[✓] Python venv present\n'
fi

_spin "Upgrading pip" \
    "${VENV_DIR}/bin/pip" install --quiet --upgrade pip

_spin "Installing Python dependencies (this can take a moment)" \
    "${VENV_DIR}/bin/pip" install --quiet -r "${PROJECT_DIR}/requirements.txt"

# --- Make wrappers executable ---
chmod +x "${SCRIPT_DIR}"/*.sh

# --- Install the Nautilus extension (with project path substituted) ---
mkdir -p "${EXT_DIR}"
sed "s|__PROJECT_DIR__|${PROJECT_DIR}|g" \
    "${SCRIPT_DIR}/nautilus-extension/${EXT_NAME}" > "${EXT_DIR}/${EXT_NAME}"
printf '[✓] Nautilus extension installed\n'

# --- Restart Nautilus so the extension loads ---
if command -v nautilus >/dev/null 2>&1; then
    nautilus -q >/dev/null 2>&1 || true
    printf '[✓] Nautilus restarted\n'
fi

printf '\n[✓] Installation complete.\n\n'

CONFIG_FILE="${HOME}/.config/pdf-ocr-converter/.env"
if [ ! -f "${CONFIG_FILE}" ]; then
    printf '[→] No credentials configured yet. Launching the setup dialog...\n'
    "${SCRIPT_DIR}/setup_credentials.sh" || true
fi

printf '\nRight-click a PDF file in GNOME Files (Nautilus):\n'
printf '  \xe2\x80\xa2 OCR to DOCX\n'
printf '  \xe2\x80\xa2 Merge & OCR to DOCX  (when 2+ PDFs are selected)\n'
printf '  \xe2\x80\xa2 OCR Settings\n'
printf '\nIf the entries do not appear immediately, log out and back in\n'
printf 'once so GNOME picks up the new Nautilus extension.\n'

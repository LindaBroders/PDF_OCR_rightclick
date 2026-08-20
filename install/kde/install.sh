#!/usr/bin/env bash
# Installer for PDF-OCR-Converter (Fedora / KDE Plasma / Dolphin).
#
# Same converter as the GNOME edition, but integrates with Dolphin via a KDE
# service menu instead of a Nautilus extension. Fully self-contained:
#   - Checks required system packages and installs any missing ones via dnf
#   - Copies the app into ~/.local/share/pdf-ocr-converter (disposable source)
#   - Creates a Python venv and installs the Python dependencies
#   - Installs the Dolphin right-click service menu + app icon + desktop entry
#   - Launches the credential setup dialog on first install
#
# Usage: bash install/kde/install.sh

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "${SCRIPT_DIR}/../.." && pwd )"

printf 'PDF-OCR-Converter Installer (KDE Plasma)\n'
printf '=========================================\n'
printf 'Project directory: %s\n\n' "${PROJECT_DIR}"

_spin() {
    local msg="$1"; shift
    local frames=('⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' '⠋' '⠙' '⠹')
    local log_file; log_file="$(mktemp /tmp/pdf-ocr-install.XXXXXX)"
    local i=0
    "$@" >"$log_file" 2>&1 &
    local pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r[%s] %s ...' "${frames[$((i % 10))]}" "$msg"; i=$((i + 1)); sleep 0.12
    done
    local rc=0; wait "$pid" || rc=$?
    if [ $rc -ne 0 ]; then
        printf '\r\033[K[✗] %s\n' "$msg"; sed 's/^/    /' "$log_file"; rm -f "$log_file"; exit 1
    fi
    printf '\r\033[K[✓] %s\n' "$msg"; rm -f "$log_file"
}

# --- Preflight: required system packages ---
install_system_packages() {
    local missing=()
    command -v python3 >/dev/null 2>&1 || missing+=("python3")
    python3 -c "import tkinter" >/dev/null 2>&1 || missing+=("python3-tkinter")
    command -v notify-send >/dev/null 2>&1 || missing+=("libnotify")
    rpm -q python3-dbus >/dev/null 2>&1 || missing+=("python3-dbus")

    if ! python3 -c "import ensurepip" >/dev/null 2>&1; then
        printf '[✗] Python venv support (ensurepip) is missing. Try: sudo dnf install python3\n'; exit 1
    fi

    if [ ${#missing[@]} -eq 0 ]; then
        printf '[✓] System packages present\n'; return 0
    fi
    printf '[→] Missing packages: %s\n' "${missing[*]}"
    if ! command -v dnf >/dev/null 2>&1; then
        printf '[✗] dnf not found. Install manually: %s\n' "${missing[*]}"; exit 1
    fi
    printf '[→] Installing via dnf (you may be prompted for your sudo password)...\n'
    sudo dnf install -y "${missing[@]}"
    python3 -c "import tkinter" >/dev/null 2>&1 \
        || { printf '[✗] tkinter still missing after install\n'; exit 1; }
    printf '[✓] System packages installed\n'
}
install_system_packages

# --- Relocate to a permanent app directory (source becomes disposable) ---
APP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/pdf-ocr-converter"
if [ "${PROJECT_DIR}" != "${APP_DIR}" ]; then
    printf '[→] Copying app files to %s\n' "${APP_DIR}"
    mkdir -p "${APP_DIR}"
    for item in src install docs requirements.txt .env.example pdf-ocr-icon.svg LICENSE README.md; do
        [ -e "${PROJECT_DIR}/${item}" ] && cp -a "${PROJECT_DIR}/${item}" "${APP_DIR}/"
    done
    find "${APP_DIR}" -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
    PROJECT_DIR="${APP_DIR}"
    SCRIPT_DIR="${APP_DIR}/install/kde"
    printf '[✓] App files installed to %s\n' "${APP_DIR}"
fi

# --- Python venv ---
VENV_DIR="${PROJECT_DIR}/.venv"
if [ -d "${VENV_DIR}" ] && [ ! -f "${VENV_DIR}/bin/activate" ]; then
    printf '[→] Removing a broken venv from a previous run...\n'; rm -rf "${VENV_DIR}"
fi
if [ ! -d "${VENV_DIR}" ]; then
    _spin "Creating Python venv" python3 -m venv "${VENV_DIR}"
else
    printf '[✓] Python venv present\n'
fi
_spin "Upgrading pip" "${VENV_DIR}/bin/pip" install --quiet --upgrade pip
_spin "Installing Python dependencies (this can take a moment)" \
    "${VENV_DIR}/bin/pip" install --quiet -r "${PROJECT_DIR}/requirements.txt"

# --- Make wrappers executable (shared with the GNOME edition) ---
chmod +x "${PROJECT_DIR}"/install/fedora/*.sh

# --- Install Dolphin service menu ---
DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}"
SM_DIR="${DATA_DIR}/kio/servicemenus"
mkdir -p "${SM_DIR}"
sed "s|__PROJECT_DIR__|${PROJECT_DIR}|g" \
    "${SCRIPT_DIR}/pdf-ocr-converter.desktop" > "${SM_DIR}/pdf-ocr-converter.desktop"
chmod +x "${SM_DIR}/pdf-ocr-converter.desktop"
# Older KDE (KF5 < 5.85) reads this location instead
mkdir -p "${DATA_DIR}/kservices5/ServiceMenus"
cp "${SM_DIR}/pdf-ocr-converter.desktop" "${DATA_DIR}/kservices5/ServiceMenus/"
printf '[✓] Dolphin service menu installed\n'

# --- App icon + desktop entry ---
ICON_DIR="${DATA_DIR}/icons/hicolor/scalable/apps"
APPS_DIR="${DATA_DIR}/applications"
mkdir -p "${ICON_DIR}" "${APPS_DIR}"
cp "${PROJECT_DIR}/pdf-ocr-icon.svg" "${ICON_DIR}/pdf-ocr-converter.svg"
sed "s|__PROJECT_DIR__|${PROJECT_DIR}|g" \
    "${PROJECT_DIR}/install/fedora/pdf-ocr-converter.desktop" > "${APPS_DIR}/pdf-ocr-converter.desktop"
printf '[✓] App icon and menu entry installed\n'

# --- Refresh KDE + icon/desktop caches ---
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 >/dev/null 2>&1 || true
fi
command -v gtk-update-icon-cache >/dev/null 2>&1 \
    && gtk-update-icon-cache -f -t "${DATA_DIR}/icons/hicolor" >/dev/null 2>&1 || true
command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "${APPS_DIR}" >/dev/null 2>&1 || true

printf '\n[✓] Installation complete.\n'
printf '    Installed to: %s\n' "${PROJECT_DIR}"
printf '    You can now delete the folder you ran this installer from.\n\n'

CONFIG_FILE="${HOME}/.config/pdf-ocr-converter/.env"
if [ ! -f "${CONFIG_FILE}" ]; then
    printf '[→] No credentials configured yet. Launching the setup dialog...\n'
    "${PROJECT_DIR}/install/fedora/setup_credentials.sh" || true
fi

printf '\nClose ALL Dolphin windows and reopen one, then right-click a PDF:\n'
printf '  \xe2\x80\xa2 OCR to DOCX\n'
printf '  \xe2\x80\xa2 Merge & OCR to DOCX\n'
printf '  \xe2\x80\xa2 OCR Settings\n'
printf '\nIf the entries do not appear, log out and back in once.\n'

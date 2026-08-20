#!/usr/bin/env bash
# Uninstaller: removes the KDE/Dolphin service menu, app icon, and desktop
# entry. Does NOT remove the project dir, the venv, or stored credentials
# (~/.config/pdf-ocr-converter/).
set -euo pipefail

DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}"

rm -fv "${DATA_DIR}/kio/servicemenus/pdf-ocr-converter.desktop"
rm -fv "${DATA_DIR}/kservices5/ServiceMenus/pdf-ocr-converter.desktop"
rm -fv "${DATA_DIR}/applications/pdf-ocr-converter.desktop"
rm -fv "${DATA_DIR}/icons/hicolor/scalable/apps/pdf-ocr-converter.svg"

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 >/dev/null 2>&1 || true
fi
command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "${DATA_DIR}/applications" >/dev/null 2>&1 || true

echo
echo "✓ KDE service menu, icon, and desktop entry removed."
echo "Credentials at ~/.config/pdf-ocr-converter/ were NOT touched."
echo "The project directory and its .venv were NOT removed."

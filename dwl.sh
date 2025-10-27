#!/usr/bin/env bash
# dwl.sh — Minimal & professional downloader.
# Downloads install_vendor.sh into the CURRENT directory, prints size & SHA256.
# Does NOT execute or chmod the file.
# Usage:
#   curl -L "https://raw.githubusercontent.com/okhtaymp/vendpy/main/dwl.sh" | bash

set -euo pipefail

# --- config ---
USER_NAME="okhtaymp"
REPO_NAME="vendpy"
BRANCH="main"
OUT_NAME="vendor.sh"

TARGET_DIR="$PWD"
TARGET_PATH="${TARGET_DIR%/}/${OUT_NAME}"
RAW_URL="https://raw.githubusercontent.com/${USER_NAME}/${REPO_NAME}/${BRANCH}/${OUT_NAME}"

# --- colors (TTY only) ---
if [[ -t 1 ]]; then
  C0=$'\033[0m'      # reset
  B=$'\033[1m'       # bold
  DIM=$'\033[2m'
  C1=$'\033[38;5;39m'   # primary
  C2=$'\033[38;5;213m'  # path
  C3=$'\033[38;5;33m'   # url
  OK=$'\033[38;5;42m'   # green
  WARN=$'\033[38;5;214m'
  ERR=$'\033[38;5;196m'
else
  C0=""; B=""; DIM=""; C1=""; C2=""; C3=""; OK=""; WARN=""; ERR=""
fi

# --- header ---
echo -e "${B}🐍 vendpy downloader${C0}"
echo -e "${DIM}Downloading installer to current folder…${C0}"
echo -e "Source: ${C3}${RAW_URL}${C0}"
echo -e "Target: ${C2}${TARGET_PATH}${C0}"
echo

# --- download (quiet, resilient) ---
mkdir -p -- "$TARGET_DIR"
TMPFILE="$(mktemp "${TARGET_DIR%/}/.dwl.XXXXXXXX.tmp")"
cleanup(){ rm -f -- "$TMPFILE" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

CURL_OPTS=(
  --fail --location --show-error
  --retry 3 --retry-delay 1 --retry-connrefused
  --connect-timeout 10 --max-time 120
  --proto "=https" --tlsv1.2
  --silent
)
# show curl progress bar on stderr if interactive
if [[ -t 2 ]]; then CURL_OPTS+=(--progress-bar); fi

curl "${CURL_OPTS[@]}" "$RAW_URL" -o "$TMPFILE"

# --- basic validation ---
if [[ ! -s "$TMPFILE" ]]; then
  echo -e "${ERR}✖ Download failed: empty file received.${C0}"
  echo "Please check the URL/branch and try again."
  exit 1
fi

# move in place (no chmod / no run)
mv -f -- "$TMPFILE" "$TARGET_PATH"

# compute size & sha256 (if available)
SIZE_BYTES="$(wc -c < "$TARGET_PATH" 2>/dev/null || echo '?')"
if command -v sha256sum >/dev/null 2>&1; then
  SHA256="$(sha256sum "$TARGET_PATH" | awk '{print $1}')"
else
  SHA256=""
fi

# --- final summary & next steps ---
echo
echo -e "${OK}✔ Download complete${C0}"
echo -e "File saved at :  ${C2}${TARGET_PATH}${C0}"
echo -e "File size     :  ${SIZE_BYTES} bytes"
if [[ -n "${SHA256}" ]]; then
  echo -e "SHA256 hash   :  ${B}${SHA256}${C0}"
else
  echo -e "SHA256 hash   :  ${WARN}unavailable (sha256sum not found)${C0}"
fi

echo
echo -e "${C1}Next steps:${C0}"
echo -e "   1  Review the installer (safer):"
echo -e "      ${DIM}cat ./$(basename "$TARGET_PATH")${C0}"
echo
echo -e "   2  Run it directly:"
echo -e "      ${B}bash ./$(basename "$TARGET_PATH")${C0}"
echo
echo -e "   3  (Optional) Make it executable for future runs:"
echo -e "      ${DIM}chmod +x ./$(basename "$TARGET_PATH")${C0}"
echo -e "      ${B}./$(basename "$TARGET_PATH")${C0}"
echo

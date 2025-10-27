#!/usr/bin/env bash
# install_vendor.sh — install deps into ./.third_party/python and ensure __venddeps__.py exists (hidden vendor)
# Usage:
#   ./install_vendor.sh                 # install from ./requirements.txt
#   ./install_vendor.sh click==8.3.0    # install explicit packages
#   ./install_vendor.sh --clear
#   ./install_vendor.sh --vendor path/to/.hidden/vendor --python /usr/bin/python3 pkgA==1.0

set -euo pipefail

# -------------------- paths --------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REQ_FILE="$SCRIPT_DIR/requirements.txt"
VENDOR_DIR="$SCRIPT_DIR/.third_party/python"   # hidden vendor dir by default
PY_BIN="${PY_BIN:-}"
CLEAR=false

# -------------------- args --------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vendor)  VENDOR_DIR="${2:-}"; shift 2 ;;
    --python)  PY_BIN="${2:-}";     shift 2 ;;
    --clear)   CLEAR=true;          shift   ;;
    -h|--help)
      cat <<EOF
install_vendor.sh
Installs Python packages into a local (hidden) vendor dir and creates __venddeps__.py if missing.

Options:
  --vendor DIR     Target directory (default: ./.third_party/python)
  --python PATH    Python interpreter to use (default: auto-detect)
  --clear          Remove target directory before install
  -h, --help       Show this help

Without package args, installs from ./requirements.txt.
With package args, installs those instead of reading requirements.txt.
EOF
      exit 0
      ;;
    *) break ;;
  esac
done

PKGS=("$@")

# -------------------- python pick --------------------
if [[ -z "$PY_BIN" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    PY_BIN=python3
  elif command -v python >/dev/null 2>&1; then
    PY_BIN=python
  else
    echo "ERROR: Python not found (tried python3, python)" >&2
    exit 1
  fi
fi

# -------------------- ensure __venddeps__.py --------------------
VENDFILE="$SCRIPT_DIR/__venddeps__.py"
if [[ ! -f "$VENDFILE" ]]; then
  cat > "$VENDFILE" <<'PY'
# __venddeps__.py
# Auto-run on import: add project root + vendored deps (CWD-agnostic, idempotent).

import os
import sys
from pathlib import Path

# Resolve project root based on this file's location (not CWD)
try:
    _BASE = Path(__file__).resolve().parent
except NameError:  # fallback if __file__ missing
    _BASE = Path(sys.argv[0]).resolve().parent

# 1) Ensure your project root is importable (for local modules)
_base_str = str(_BASE)
if _base_str not in sys.path:
    sys.path.insert(0, _base_str)

# 2) Add vendored deps directory (override with SYNC_VENDOR_PATH if desired)
_env = os.environ.get("SYNC_VENDOR_PATH", "")
if _env:
    vpath = Path(_env)
    if not vpath.is_absolute():
        vpath = (_BASE / vpath).resolve()
else:
    vpath = (_BASE / ".third_party" / "python").resolve()  # hidden vendor

_vstr = str(vpath)
if vpath.is_dir() and _vstr not in sys.path:
    sys.path.insert(0, _vstr)

# Cleanup temp names
del os, sys, Path, _BASE, _base_str, _env, vpath, _vstr
PY
  echo "==> Created $VENDFILE"
fi

# -------------------- sanity --------------------
if [[ ${#PKGS[@]} -eq 0 && ! -f "$REQ_FILE" ]]; then
  echo "ERROR: No packages specified and requirements.txt not found at: $REQ_FILE" >&2
  exit 1
fi

# -------------------- prepare vendor dir --------------------
if $CLEAR && [[ -d "$VENDOR_DIR" ]]; then
  echo "==> Clearing vendor directory: $VENDOR_DIR"
  rm -rf -- "$VENDOR_DIR"
fi
mkdir -p -- "$VENDOR_DIR"

# -------------------- install --------------------
echo "==> Python     : $("$PY_BIN" -V 2>&1)"
echo "==> Vendor dir : $VENDOR_DIR"

if [[ ${#PKGS[@]} -gt 0 ]]; then
  echo "==> Installing packages: ${PKGS[*]}"
  "$PY_BIN" -m pip install \
    --no-cache-dir --disable-pip-version-check \
    --target "$VENDOR_DIR" \
    "${PKGS[@]}"
else
  echo "==> Installing from requirements: $REQ_FILE"
  "$PY_BIN" -m pip install \
    --no-cache-dir --disable-pip-version-check \
    --target "$VENDOR_DIR" \
    -r "$REQ_FILE"
fi

echo "==> Installed distributions in vendor:"
find "$VENDOR_DIR" -maxdepth 1 -type d -name '*.dist-info' -printf '  - %f\n' 2>/dev/null | sed 's/\.dist-info$//' || true

echo
echo "✔ Done. Import this at the top of your entry files:"
echo "    import __venddeps__"

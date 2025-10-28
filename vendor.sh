#!/usr/bin/env bash
# vendor.sh — install deps into ./.third_party/python and ensure __venddeps__.py exists (hidden vendor)
# Usage:
#   ./vendor.sh                       # safe: install only missing deps from ./requirements.txt (no overwrite)
#   ./vendor.sh click==8.3.0          # safe: install only missing explicit packages
#   ./vendor.sh --upgrade             # allow upgrading/overwriting existing packages
#   ./vendor.sh --clear               # remove vendor dir before install
#   ./vendor.sh --vendor path/to/vendor --python /usr/bin/python3 pkgA==1.0

set -euo pipefail

# -------------------- paths --------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REQ_FILE="$SCRIPT_DIR/requirements.txt"
VENDOR_DIR="$SCRIPT_DIR/.third_party/python"   # hidden vendor dir by default
PY_BIN="${PY_BIN:-}"
CLEAR=false
UPGRADE=false

# -------------------- args --------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vendor)  VENDOR_DIR="${2:-}"; shift 2 ;;
    --python)  PY_BIN="${2:-}";     shift 2 ;;
    --clear)   CLEAR=true;          shift   ;;
    --upgrade) UPGRADE=true;        shift   ;;
    -h|--help)
      cat <<EOF
vendor.sh
Installs Python packages into a local (hidden) vendor dir and creates __venddeps__.py if missing.

Options:
  --vendor DIR     Target directory (default: ./.third_party/python)
  --python PATH    Python interpreter to use (default: auto-detect)
  --clear          Remove target directory before install
  --upgrade        Upgrade/overwrite existing packages if present
  -h, --help       Show this help

Behavior:
  - Default: do NOT overwrite existing packages; only install what's missing (pre-check to avoid downloads & warnings).
  - With --upgrade: allow upgrading/replacing installed packages.

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

# -------------------- banner --------------------
echo "==> Python     : $("$PY_BIN" -V 2>&1)"
echo "==> Vendor dir : $VENDOR_DIR"
if $UPGRADE; then
  echo "==> Mode       : upgrade/overwrite enabled"
else
  echo "==> Mode       : safe (no overwrite; install missing only)"
fi

# -------------------- build pip args --------------------
PIP_ARGS=( --disable-pip-version-check --target "$VENDOR_DIR" )
$UPGRADE && PIP_ARGS+=( --upgrade )

# -------------------- resolve what to install --------------------
# در حالت safe، قبل از اجرای pip بررسی می‌کنیم چه چیزهایی واقعاً لازم است نصب شوند.
missing_list=()
if ! $UPGRADE; then
  if [[ ${#PKGS[@]} -gt 0 ]]; then
    mapfile -t missing_list < <(
      "$PY_BIN" - "$VENDOR_DIR" "${PKGS[@]}" <<'PY'
import sys
from pathlib import Path
from packaging.requirements import Requirement
from packaging.utils import canonicalize_name
from packaging.version import Version
from packaging.specifiers import SpecifierSet
import importlib.metadata as md

vendor = Path(sys.argv[1])
reqs = sys.argv[2:]

# فهرست پکیج‌های نصب‌شده داخل vendor
installed = {}
for dist in md.distributions(path=[str(vendor)]):
    installed[canonicalize_name(dist.metadata["Name"])] = dist.version

def need(req_str: str) -> bool:
    r = Requirement(req_str)
    name = canonicalize_name(r.name)
    vers = installed.get(name)
    if vers is None:
        return True
    # اگر قید نسخه‌ای نبود، یعنی همین که هست کفایت می‌کند
    if not r.specifier:
        return False
    try:
        return not Version(vers) in r.specifier
    except Exception:
        # محافظه‌کار: اگر نتوانستیم تفسیر کنیم، بگذار نصب کند
        return True

for s in reqs:
    if need(s):
        print(s)
PY
    )
  else
    # از فایل requirements.txt بخوان و موارد واقعاً لازم را برگردان
    mapfile -t missing_list < <(
      "$PY_BIN" - "$VENDOR_DIR" "$REQ_FILE" <<'PY'
import sys
from pathlib import Path
from packaging.requirements import Requirement
from packaging.utils import canonicalize_name
from packaging.version import Version
from packaging.specifiers import SpecifierSet
import importlib.metadata as md

vendor = Path(sys.argv[1])
req_file = Path(sys.argv[2])

lines = []
for raw in req_file.read_text().splitlines():
    s = raw.strip()
    if not s or s.startswith("#"):
        continue
    # فقط خطوط ساده‌ی پکیج/نسخه را قبول کن (نه -e، نه فایل/URL). بقیه را پاس بده تا pip خودش رسیدگی کند.
    lines.append(s)

installed = {}
for dist in md.distributions(path=[str(vendor)]):
    installed[canonicalize_name(dist.metadata["Name"])] = dist.version

def need(req_str: str) -> bool:
    try:
        r = Requirement(req_str)
    except Exception:
        # ناشناخته: بگذار pip رسیدگی کند
        return True
    name = canonicalize_name(r.name)
    vers = installed.get(name)
    if vers is None:
        return True
    if not r.specifier:
        return False
    try:
        return not Version(vers) in r.specifier
    except Exception:
        return True

for s in lines:
    if need(s):
        print(s)
PY
    )
  fi
fi

# -------------------- install --------------------
if [[ ${#PKGS[@]} -gt 0 ]]; then
  if ! $UPGRADE && [[ ${#missing_list[@]} -eq 0 ]]; then
    echo "==> Nothing to do (all explicit packages already satisfied in vendor)."
  else
    if ! $UPGRADE; then
      echo "==> Installing missing explicit packages: ${missing_list[*]}"
      "$PY_BIN" -m pip install "${PIP_ARGS[@]}" "${missing_list[@]}"
    else
      echo "==> Installing (upgrade mode) packages: ${PKGS[*]}"
      "$PY_BIN" -m pip install "${PIP_ARGS[@]}" "${PKGS[@]}"
    fi
  fi
else
  if ! $UPGRADE && [[ ${#missing_list[@]} -eq 0 ]]; then
    echo "==> Nothing to do (all requirements already satisfied in vendor)."
  else
    if ! $UPGRADE; then
      # بساز یک فایل موقت فقط با اقلامِ لازم
      tmp_req="$(mktemp)"
      printf "%s\n" "${missing_list[@]}" > "$tmp_req"
      echo "==> Installing missing from requirements: $tmp_req"
      "$PY_BIN" -m pip install "${PIP_ARGS[@]}" -r "$tmp_req"
      rm -f -- "$tmp_req"
    else
      echo "==> Installing (upgrade mode) from requirements: $REQ_FILE"
      "$PY_BIN" -m pip install "${PIP_ARGS[@]}" -r "$REQ_FILE"
    fi
  fi
fi

# -------------------- list dists --------------------
echo "==> Installed distributions in vendor:"
if command -v find >/dev/null 2>&1 && find "$VENDOR_DIR" -maxdepth 1 -type d -name '*.dist-info' -printf '' >/dev/null 2>&1; then
  find "$VENDOR_DIR" -maxdepth 1 -type d -name '*.dist-info' -printf '  - %f\n' | sed 's/\.dist-info$//' || true
else
  # در سیستم‌هایی که find با -printf ندارند (مثلاً مک)، از پایتون کمک می‌گیریم
  "$PY_BIN" - "$VENDOR_DIR" <<'PY' || true
import sys, pathlib
p = pathlib.Path(sys.argv[1])
for d in sorted(p.glob('*.dist-info')):
    print('  -', d.name.replace('.dist-info',''))
PY
fi

echo
echo "✔ Done. Import this at the top of your entry files:"
echo "    import __venddeps__"

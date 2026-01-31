#!/usr/bin/env bash
set -euo pipefail

REPO="trancong12102/codex-max"
BIN_DEST_DEFAULT="$HOME/.local/bin/codex-max"
WRAPPER_DEST_DEFAULT="$HOME/.local/bin/cx"
BIN_DEST="${BIN_DEST:-${CODEX_MAX_BIN_DEST:-${DEST:-$BIN_DEST_DEFAULT}}}"
WRAPPER_DEST="${WRAPPER_DEST:-${CODEX_MAX_WRAPPER_DEST:-$WRAPPER_DEST_DEFAULT}}"
ALLOW_PATH_FALLBACK="${ALLOW_PATH_FALLBACK:-1}"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

LATEST_INFO="$(
python3 - <<'PY'
import json
import platform
import sys
import urllib.request
import urllib.error

repo = "trancong12102/codex-max"
releases_api = f"https://api.github.com/repos/{repo}/releases?per_page=100"

def fetch_json(url: str):
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "codex-installer",
            "Accept": "application/vnd.github+json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.load(resp)
    except urllib.error.HTTPError as e:
        return e.code, None

status, data = fetch_json(releases_api)
if status != 200 or not isinstance(data, list) or not data:
    print("\t", end="")
    sys.exit(0)

def sort_key(item):
    return item.get("published_at") or item.get("created_at") or item.get("tag_name") or ""

filtered = []
for item in data:
    tag = str(item.get("tag_name", ""))
    if not tag:
        continue
    if item.get("draft") is False:
        filtered.append(item)

if not filtered:
    print("\t", end="")
    sys.exit(0)

selected = sorted(filtered, key=sort_key)[-1]
tag = str(selected.get("tag_name", ""))
assets = selected.get("assets", [])
if not assets:
    print(f"\t{tag}", end="")
    sys.exit(0)

osname = platform.system().lower()
arch = platform.machine().lower()
if arch in ("x86_64", "amd64"):
    arch = "x86_64"
elif arch in ("arm64", "aarch64"):
    arch = "arm64"

def score(name: str) -> int:
    n = name.lower()
    s = 0
    if "codex" in n:
        s += 1
    os_tokens = [osname]
    if osname == "darwin":
        os_tokens += ["mac", "macos", "osx", "apple"]
    elif osname == "linux":
        os_tokens += ["gnu", "ubuntu", "debian", "alpine"]
    elif osname == "windows":
        os_tokens += ["win"]
    if any(t in n for t in os_tokens):
        s += 2
    if arch in n:
        s += 2
    if n.endswith((".tar.gz", ".tgz", ".tar.xz", ".txz", ".tar", ".zip")):
        s += 1
    return s

candidates = [a for a in assets if a.get("browser_download_url")]
if not candidates:
    print("", end="")
    sys.exit(0)

def is_unwanted(name: str) -> bool:
    n = name.lower()
    if n.endswith((".sha", ".sha256", ".sha512", ".sig", ".asc", ".pem")):
        return True
    if "source code" in n or n.endswith(("-src.tar.gz", "-src.zip")):
        return True
    if "src" in n and "codex" not in n:
        return True
    return False

pool = [a for a in candidates if not is_unwanted(str(a.get("name", "")))] or candidates
best = max(pool, key=lambda a: (score(a.get("name", "")), a.get("size", 0)))
print(f"{best.get('browser_download_url', '')}\t{tag}\t{best.get('name', '')}", end="")
PY
)"

ASSET_URL=""
LATEST_TAG=""
ASSET_NAME=""
IFS=$'\t' read -r ASSET_URL LATEST_TAG ASSET_NAME <<<"$LATEST_INFO"

if [[ -z "$ASSET_URL" ]]; then
  echo "No release assets found for $REPO." >&2
  exit 1
fi

LATEST_VERSION="$(echo "$LATEST_TAG" | sed -E 's/^[^0-9]*//')"
CURRENT_VERSION=""
CURRENT_BIN=""
CURRENT_BIN_IS_DEST=0
if [[ -x "$BIN_DEST" ]]; then
  CURRENT_BIN="$BIN_DEST"
  CURRENT_BIN_IS_DEST=1
elif [[ "$ALLOW_PATH_FALLBACK" == "1" ]] && command -v codex-max >/dev/null 2>&1; then
  CURRENT_BIN="$(command -v codex-max)"
fi
if [[ -n "$CURRENT_BIN" ]]; then
  VERSION_OUTPUT="$("$CURRENT_BIN" --version 2>/dev/null || true)"
  CURRENT_VERSION="$(echo "$VERSION_OUTPUT" | grep -Eo '[0-9]+([.][0-9]+)+([.-][0-9A-Za-z.-]+)?' | head -n 1 || true)"
fi

SKIP_DOWNLOAD=0
if [[ -n "$CURRENT_VERSION" && -n "$LATEST_VERSION" && "$CURRENT_VERSION" == "$LATEST_VERSION" && "$CURRENT_BIN_IS_DEST" == "1" ]]; then
  SKIP_DOWNLOAD=1
fi

if [[ "$SKIP_DOWNLOAD" != "1" ]]; then
  ARCHIVE="$TMP_DIR/${ASSET_NAME:-codex-asset}"
  curl -fL "$ASSET_URL" -o "$ARCHIVE"

  extract_archive() {
    local archive="$1"
    local dest="$2"
    case "$archive" in
      *.tar.gz|*.tgz)
        tar -xzf "$archive" -C "$dest"
        ;;
      *.tar.xz|*.txz)
        tar -xJf "$archive" -C "$dest"
        ;;
      *.tar)
        tar -xf "$archive" -C "$dest"
        ;;
      *.zip)
        python3 - <<'PY' "$archive" "$dest"
import sys, zipfile
archive, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(archive) as zf:
    zf.extractall(dest)
PY
        ;;
      *)
        # Assume direct binary download.
        mkdir -p "$dest"
        cp "$archive" "$dest/"
        ;;
    esac
  }

  extract_archive "$ARCHIVE" "$TMP_DIR"

  BIN_PATH="$(find "$TMP_DIR" -maxdepth 6 -type f -name codex | head -n 1)"
  if [[ -z "$BIN_PATH" ]]; then
    BIN_PATH="$(find "$TMP_DIR" -maxdepth 6 -type f -name 'codex*' ! -name '*.dSYM' | head -n 1)"
  fi
  if [[ -z "$BIN_PATH" ]]; then
    BIN_PATH="$(find "$TMP_DIR" -maxdepth 6 -type f -perm -u+x | head -n 1)"
  fi
  if [[ -z "$BIN_PATH" ]]; then
    echo "codex binary not found in the downloaded archive." >&2
    exit 1
  fi
  if [[ ! -x "$BIN_PATH" ]]; then
    chmod +x "$BIN_PATH"
  fi

  mkdir -p "$(dirname "$BIN_DEST")"
  install -m 0755 "$BIN_PATH" "$BIN_DEST"
fi

hash_file() {
  local file="$1"

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$file" | awk '{print $NF}'
  elif command -v cksum >/dev/null 2>&1; then
    cksum "$file" | awk '{print $1}'
  else
    return 1
  fi
}

install_wrapper() {
  local dest="$1"
  local script_dir=""
  local local_wrapper=""
  local src_hash=""
  local dest_hash=""
  local tmp=""

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local_wrapper="$script_dir/cx"

  mkdir -p "$(dirname "$dest")"
  if [[ -f "$local_wrapper" ]]; then
    src_hash="$(hash_file "$local_wrapper" || true)"
    if [[ -f "$dest" ]]; then
      dest_hash="$(hash_file "$dest" || true)"
      if [[ -n "$src_hash" && "$src_hash" == "$dest_hash" ]]; then
        if [[ ! -x "$dest" ]]; then
          chmod +x "$dest" || return 1
        fi
        return 0
      fi
    fi
    cp "$local_wrapper" "$dest" || return 1
  else
    tmp="$(mktemp)"
    if ! curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/cx" -o "$tmp"; then
      rm -f "$tmp"
      return 1
    fi
    src_hash="$(hash_file "$tmp" || true)"
    if [[ -f "$dest" ]]; then
      dest_hash="$(hash_file "$dest" || true)"
      if [[ -n "$src_hash" && "$src_hash" == "$dest_hash" ]]; then
        rm -f "$tmp"
        if [[ ! -x "$dest" ]]; then
          chmod +x "$dest" || return 1
        fi
        return 0
      fi
    fi
    cp "$tmp" "$dest" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
  fi
  chmod +x "$dest" || return 1
  return 2
}

WRAPPER_UPDATED=0
set +e
install_wrapper "$WRAPPER_DEST"
WRAPPER_STATUS=$?
set -e

if [[ "$WRAPPER_STATUS" -eq 2 ]]; then
  WRAPPER_UPDATED=1
elif [[ "$WRAPPER_STATUS" -ne 0 ]]; then
  if [[ ! -x "$WRAPPER_DEST" ]]; then
    echo "Failed to install wrapper to $WRAPPER_DEST" >&2
    exit 1
  fi
fi

if [[ "$SKIP_DOWNLOAD" != "1" ]]; then
  echo "Installed codex-max binary to $BIN_DEST"
fi
if [[ "$WRAPPER_UPDATED" == "1" ]]; then
  echo "Installed cx wrapper to $WRAPPER_DEST"
fi

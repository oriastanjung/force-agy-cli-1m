#!/usr/bin/env bash
set -euo pipefail

GIST_REVISION="c75138dfd0b750a31f713f478dcdcb7b73d7b4ee"
SCRIPT_URL="https://gist.githubusercontent.com/LiraNuna/4c058aed3f636f5193f920f64284ff26/raw/${GIST_REVISION}/patch_agy.py"
SCRIPT_SHA256="f9115f46d5949afcf6e07a5ace39dfc81f7f891a8d59a88c109ab74fe479731f"

usage() {
  echo "Usage: $0 [--dry-run | --restore] [path/to/agy]"
}

mode="patch"
case "${1:-}" in
  --dry-run) mode="dry-run"; shift ;;
  --restore) mode="restore"; shift ;;
  -h|--help) usage; exit 0 ;;
esac

binary="${1:-$(command -v agy || true)}"
if [[ -z "$binary" || ! -f "$binary" ]]; then
  echo "agy binary not found. Pass its path as an argument." >&2
  exit 1
fi
binary="$(readlink -f "$binary")"

if [[ "$mode" == "restore" ]]; then
  if [[ ! -f "$binary.bak" ]]; then
    echo "No backup at $binary.bak" >&2
    exit 1
  fi
  mv "$binary.bak" "$binary"
  echo "Restored original binary at $binary"
  exit 0
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl -fsSL -o "$workdir/patch_agy.py" "$SCRIPT_URL"
echo "$SCRIPT_SHA256  $workdir/patch_agy.py" | sha256sum -c --quiet

if [[ "$mode" == "dry-run" ]]; then
  python3 -I "$workdir/patch_agy.py" "$binary" --dry-run
  exit 0
fi

python3 -I "$workdir/patch_agy.py" "$binary"
"$binary" --version

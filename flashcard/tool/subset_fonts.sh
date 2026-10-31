#!/usr/bin/env bash
set -euo pipefail

OUT="assets/fonts"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
UA="Mozilla/5.0 (Linux; U; Android 2.2)"

UNICODES="U+0000-024F,U+0370-03FF,U+1D00-1DBF,U+2000-206F,U+2070-209F,U+20AC,U+2122,U+2190-21FF,U+2200-22FF,U+2300-23FF,U+25A0-25FF"

fetch() {
  local url
  url=$(curl -s --max-time 30 --retry 3 -A "$UA" "https://fonts.googleapis.com/css2?family=$1:wght@$3" | grep -oE 'https://fonts.gstatic.com/[^)]+\.ttf' | head -1)
  curl -s --max-time 60 --retry 3 -o "$TMP/$2-$3.ttf" "$url"
}

subset() {
  uvx --from fonttools pyftsubset "$TMP/$1-$2.ttf" \
    --unicodes="$UNICODES" \
    --layout-features='kern,liga,calt,ccmp,locl,mark,mkmk,tnum' \
    --output-file="$OUT/$1-$2.ttf"
}

for w in 500 700; do fetch "Cormorant+Garamond" CormorantGaramond $w; subset CormorantGaramond $w; done
for w in 400 500 600 700; do fetch Inter Inter $w; subset Inter $w; done
fetch "JetBrains+Mono" JetBrainsMono 400; subset JetBrainsMono 400

ls -la "$OUT"/*.ttf

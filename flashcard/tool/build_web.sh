#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${1:?serve l indirizzo della API, es. https://api.tuodominio.it}"

flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL="$API_BASE_URL"

python3 - <<'PY'
import hashlib
import json

manifest_path = "build/web/assets/FontManifest.json"
families = json.load(open(manifest_path))
initial, deferred = [], []
for family in families:
    late_family = "KaTeX" in family["family"] or family["family"] == "JetBrainsMono"
    early_fonts, late_fonts = [], []
    for font in family["fonts"]:
        late = late_family or (family["family"] in {"CormorantGaramond", "Inter"} and font.get("weight") == 700)
        (late_fonts if late else early_fonts).append(font)
    if early_fonts:
        initial.append({**family, "fonts": early_fonts})
    if late_fonts:
        deferred.append({**family, "fonts": late_fonts})

json.dump(initial, open(manifest_path, "w"))
json.dump(deferred, open("build/web/assets/FontManifest.deferred.json", "w"))

bundle = open("build/web/main.dart.js", "rb").read()
build_id = hashlib.sha256(bundle).hexdigest()[:12]
sw_path = "build/web/sw.js"
sw = open(sw_path).read().replace("__BUILD_ID__", build_id)
open(sw_path, "w").write(sw)
print(f"Famiglie/font differiti: {len(deferred)}; cache PWA: {build_id}")
PY

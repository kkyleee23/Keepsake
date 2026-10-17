#!/usr/bin/env bash
# Builds the website and the web app into dist/, ready to upload to
# Netlify or Cloudflare Pages:
#   /       the website (website/)
#   /app/   the Keepsake web app, where share links open
#
# Usage: tool/build_site.sh            (uses dart_defines.json)
#        DEFINES=other.json tool/build_site.sh
set -euo pipefail
cd "$(dirname "$0")/.."

DEFINES="${DEFINES:-dart_defines.json}"
read -r SUPABASE_HOST LINK_BASE < <(python3 - "$DEFINES" <<'PY'
import json, sys
from urllib.parse import urlparse
d = json.load(open(sys.argv[1]))
print(urlparse(d.get('SUPABASE_URL', '')).hostname or '', d.get('KEEPSAKE_LINK_BASE', ''))
PY
)
if [[ -z "$SUPABASE_HOST" ]]; then
  echo "SUPABASE_URL is missing from $DEFINES" >&2; exit 1
fi
if [[ "$LINK_BASE" != */app ]]; then
  echo "Note: KEEPSAKE_LINK_BASE is '$LINK_BASE'. With this layout it should be" >&2
  echo "      https://<your-site>/app so share links open the app." >&2
fi

# --csp: no runtime code generation, so the strict CSP in _headers works.
# --no-web-resources-cdn: the app's engine files are served from this site
# too, instead of a Google CDN.
flutter build web --release --base-href /app/ --csp --no-web-resources-cdn \
  --no-tree-shake-icons --dart-define-from-file="$DEFINES"

rm -rf dist
mkdir -p dist
cp -R website/. dist/
cp -R build/web dist/app
sed -i.bak "s/__SUPABASE_HOST__/$SUPABASE_HOST/g" dist/_headers && rm dist/_headers.bak
echo "Built dist/ ($(du -sh dist | cut -f1)). Upload that folder."

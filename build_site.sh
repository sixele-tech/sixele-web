#!/bin/bash
# Assembles the published site into _site/ from an explicit list of files, so
# nothing else in this repository (the screenshot library, this script, the
# README) is ever served. The deploy workflow runs it; so can you:
#
#   ./build_site.sh && python3 -m http.server 8765 -d _site
#
# It fails if a page asks for a local file that would not be published.

set -e

SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SITE_DIR/_site"

PAGES="index.html myself.html someone-i-love.html donors.html 404.html"
FILES="styles.css site.js CNAME"
DIRS="brand fonts icons"

rm -rf "$OUT"
mkdir -p "$OUT"
for f in $PAGES $FILES; do cp "$SITE_DIR/$f" "$OUT/"; done
for d in $DIRS; do cp -R "$SITE_DIR/$d" "$OUT/"; done
touch "$OUT/.nojekyll"   # serve the files as they are; no Jekyll pass

# Every local src/href/srcset in every page must resolve inside _site.
missing=0
for page in $PAGES; do
  for ref in $(grep -oE '(src|href|srcset)="[^"]+"' "$SITE_DIR/$page" | sed -E 's/^[a-z]+="//; s/"$//'); do
    case "$ref" in
      http://*|https://*|mailto:*|tel:*|\#*|./|/) continue ;;
    esac
    target="${ref#/}"
    target="${target%%#*}"
    if [ ! -f "$OUT/$target" ]; then
      echo "  Missing: $page asks for $ref, which is not in _site"
      missing=1
    fi
  done
done

[ "$missing" = 0 ] && echo "Built _site: $(find "$OUT" -type f | wc -l | tr -d ' ') files, every reference resolves."
exit $missing

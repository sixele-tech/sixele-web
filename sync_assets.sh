#!/bin/bash
# Copies everything the site borrows from the app (a sibling checkout at
# ../sixele-app, or $SIXELE_APP_DIR) into this repo, so the site deploys on its
# own and never drifts from the app.
#
#   screenshots/  <- marketing_screenshots/latest/*.png   (this repo)
#   fonts/        <- assets/fonts        (IBM Plex, with its OFL licence)
#   brand/        <- assets/brand        (light and dark cuts of each mark)
#   icons/        <- assets/icons        (pebble icons, light and dark)
#
# Rerunnable. capture_marketing_shots.sh runs it after every capture, so new
# screenshots reach the site without touching any HTML.
# Usage: ./sync_assets.sh

set -e

SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SIXELE_APP_DIR:-$SITE_DIR/../sixele-app}"

sync_dir() {
  local from="$1" to="$2" pattern="$3"
  mkdir -p "$to"
  # Clear what was copied last time, so a screenshot that was renamed or
  # removed in the library doesn't linger on the site.
  find "$to" -maxdepth 1 -type f -name "$pattern" -delete
  cp "$from"/$pattern "$to/"
  echo "  $(ls -1 "$to"/$pattern | wc -l | tr -d ' ') files -> ${to#$SITE_DIR/}"
}

echo "Syncing website assets from the app..."
sync_dir "$SITE_DIR/marketing_screenshots/latest" "$SITE_DIR/screenshots" "*.png"
sync_dir "$APP_DIR/assets/fonts" "$SITE_DIR/fonts" "*.ttf"
cp "$APP_DIR/assets/fonts/OFL.txt" "$SITE_DIR/fonts/"
sync_dir "$APP_DIR/assets/brand" "$SITE_DIR/brand" "*.jpg"
cp "$APP_DIR/assets/brand/app_icon.png" "$SITE_DIR/brand/"
sync_dir "$APP_DIR/assets/icons" "$SITE_DIR/icons" "*.svg"

# Every screenshot the page asks for should exist in the library.
missing=0
for shot in $(grep -o 'screenshots/[a-z_]*\.png' "$SITE_DIR/index.html" | sort -u); do
  if [ ! -f "$SITE_DIR/$shot" ]; then
    echo "  Missing: index.html uses $shot, but the library has no such file"
    missing=1
  fi
done
[ "$missing" = 0 ] && echo "Done. Every screenshot index.html uses is present."
exit $missing

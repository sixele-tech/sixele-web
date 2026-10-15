#!/bin/bash
# Copies everything the site borrows from the app (a sibling checkout at
# ../sixele-app, or $SIXELE_APP_DIR) into this repo, so the site deploys on its
# own and never drifts from the app.
#
#   fonts/        <- assets/fonts        (IBM Plex, with its OFL licence)
#   brand/        <- assets/brand        (light and dark cuts of each mark)
#   icons/        <- assets/icons        (pebble icons, light and dark)
#
# Rerunnable. The pages show no screenshots; the screenshot library in
# marketing_screenshots/ is for marketing material and is never published.
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
sync_dir "$APP_DIR/assets/fonts" "$SITE_DIR/fonts" "*.ttf"
cp "$APP_DIR/assets/fonts/OFL.txt" "$SITE_DIR/fonts/"
sync_dir "$APP_DIR/assets/brand" "$SITE_DIR/brand" "*.jpg"
cp "$APP_DIR/assets/brand/app_icon.png" "$SITE_DIR/brand/"
sync_dir "$APP_DIR/assets/icons" "$SITE_DIR/icons" "*.svg"

# Every file the pages ask for should still be there after the sync.
"$SITE_DIR/build_site.sh"

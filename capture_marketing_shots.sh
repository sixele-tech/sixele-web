#!/bin/bash
# Rerunnable script to capture marketing screenshots for Sixele
# Usage: ./capture_marketing_shots.sh   (expects the app at ../sixele-app or $SIXELE_APP_DIR)

set -e

SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The app repo, where the screenshot test lives. Override with SIXELE_APP_DIR.
APP_DIR="${SIXELE_APP_DIR:-$SITE_DIR/../sixele-app}"
SHOTS_DIR="$SITE_DIR/marketing_screenshots/latest"
BACKUP_DIR="$SITE_DIR/marketing_screenshots/archive/$(date +%Y%m%d_%H%M%S)"

echo "🎬 Capturing Sixele marketing screenshots..."
echo "📁 Output directory: $SHOTS_DIR"

# Create output directory
mkdir -p "$SHOTS_DIR"

# Backup previous screenshots if they exist
if [ "$(ls -A $SHOTS_DIR 2>/dev/null)" ]; then
  echo "💾 Archiving previous screenshots to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  cp "$SHOTS_DIR"/*.png "$BACKUP_DIR/" 2>/dev/null || true
fi

# Run the Flutter test with screenshot capture
echo "🚀 Running screenshot tests..."
cd "$APP_DIR"

export SIXELE_SHOTS="$SHOTS_DIR"
flutter test test/screenshots_test.dart

echo ""
echo "✅ Screenshots captured successfully!"
echo ""
echo "📸 Available screenshots:"
ls -1 "$SHOTS_DIR"/*.png | xargs -n 1 basename

# Generate an HTML index for easy viewing
generate_index() {
  local html_file="$SHOTS_DIR/../index.html"
  local shots_dir_basename="latest"

  cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sixele Marketing Screenshots</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
      background: #f5f5f5;
    }
    h1 {
      color: #333;
      text-align: center;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
      margin: 30px 0;
    }
    .card {
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      transition: transform 0.2s;
    }
    .card:hover {
      transform: translateY(-4px);
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
    }
    .card img {
      width: 100%;
      height: auto;
      display: block;
    }
    .card-title {
      padding: 12px 16px;
      font-size: 14px;
      font-weight: 600;
      color: #333;
    }
    .meta {
      text-align: center;
      color: #666;
      font-size: 12px;
      margin: 20px 0;
    }
  </style>
</head>
<body>
  <h1>📱 Sixele Marketing Screenshots</h1>
  <div class="meta" id="meta"></div>
  <div class="grid" id="gallery"></div>

  <script>
    const gallery = document.getElementById('gallery');
    const meta = document.getElementById('meta');
    const images = [
      'dashboard.png',
      'dashboard_dark.png',
      'dashboard_timer.png',
      'check_on_me.png',
      'home_safe.png',
      'practice_coach.png',
      'guardians.png',
      'report.png',
      'signup_touch.png',
      'record_flow.png',
      'record_detail.png',
      'guardian_invite.png',
      'guardian_alert.png'
    ];

    const dir = 'latest/';
    images.forEach(img => {
      const card = document.createElement('div');
      card.className = 'card';
      card.innerHTML = `
        <img src="${dir}${img}" alt="${img}" loading="lazy">
        <div class="card-title">${img.replace('.png', '').replace(/_/g, ' ')}</div>
      `;
      gallery.appendChild(card);
    });

    meta.textContent = `Generated on ${new Date().toLocaleString()} • ${images.length} screenshots`;
  </script>
</body>
</html>
EOF
  echo "📄 Generated gallery: $html_file"
}

generate_index

# Pass the fresh screenshots, fonts, brand marks and icons on to the site.
echo ""
"$SITE_DIR/sync_assets.sh"

echo ""
echo "💡 To view the screenshots:"
echo "   Open: marketing_screenshots/index.html in your browser"
echo ""
echo "📋 To export for marketing:"
echo "   Screenshots are in: $SHOTS_DIR"
echo "   Archive available at: $SITE_DIR/marketing_screenshots/archive"

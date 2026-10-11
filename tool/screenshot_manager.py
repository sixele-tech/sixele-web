#!/usr/bin/env python3
"""
Screenshot Manager for Sixele Marketing Screenshots

Helps organize, view, and export marketing screenshots.

Usage:
    python3 tool/screenshot_manager.py list
    python3 tool/screenshot_manager.py view
    python3 tool/screenshot_manager.py export <output_dir>
"""

import os
import sys
import json
import shutil
from pathlib import Path
from datetime import datetime

class ScreenshotManager:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.screenshots_dir = self.project_root / "marketing_screenshots"
        self.latest_dir = self.screenshots_dir / "latest"
        self.archive_dir = self.screenshots_dir / "archive"

    def list_screenshots(self):
        """List all available screenshots."""
        if not self.latest_dir.exists():
            print("No screenshots found. Run './capture_marketing_shots.sh' first.")
            return

        screenshots = sorted(self.latest_dir.glob("*.png"))
        print(f"\n📸 Available Screenshots ({len(screenshots)}):\n")

        for i, shot in enumerate(screenshots, 1):
            size_mb = shot.stat().st_size / (1024 * 1024)
            name = shot.stem.replace("_", " ").title()
            print(f"  {i:2d}. {name:30s} ({size_mb:.1f}MB)")

        print(f"\nLocation: {self.latest_dir}")
        print(f"Total size: {sum(s.stat().st_size for s in screenshots) / (1024*1024):.1f}MB")

    def list_archives(self):
        """List all archived screenshot sets."""
        if not self.archive_dir.exists():
            print("No archived screenshots.")
            return

        archives = sorted(self.archive_dir.iterdir(), reverse=True)
        print(f"\n📦 Archived Screenshot Sets ({len(archives)}):\n")

        for archive in archives[:10]:  # Show last 10
            count = len(list(archive.glob("*.png")))
            print(f"  {archive.name:20s} ({count} screenshots)")

    def export_screenshots(self, output_dir):
        """Export screenshots to an external directory."""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        if not self.latest_dir.exists():
            print("❌ No screenshots found to export.")
            return

        screenshots = list(self.latest_dir.glob("*.png"))
        print(f"\n📤 Exporting {len(screenshots)} screenshots to {output_dir}...")

        for shot in screenshots:
            shutil.copy2(shot, output_path / shot.name)
            print(f"  ✓ {shot.name}")

        print(f"\n✅ Export complete! Screenshots are in: {output_dir}")

    def generate_metadata(self):
        """Generate a JSON metadata file for all screenshots."""
        if not self.latest_dir.exists():
            print("❌ No screenshots found.")
            return

        screenshots = sorted(self.latest_dir.glob("*.png"))
        metadata = {
            "generated": datetime.now().isoformat(),
            "count": len(screenshots),
            "screenshots": []
        }

        for shot in screenshots:
            metadata["screenshots"].append({
                "name": shot.stem,
                "filename": shot.name,
                "size_bytes": shot.stat().st_size,
                "created": datetime.fromtimestamp(shot.stat().st_mtime).isoformat()
            })

        meta_file = self.screenshots_dir / "metadata.json"
        with open(meta_file, "w") as f:
            json.dump(metadata, f, indent=2)

        print(f"✅ Metadata saved to {meta_file}")
        return metadata

    def clean_old_archives(self, keep_count=5):
        """Clean up old archives, keeping only the most recent."""
        if not self.archive_dir.exists():
            print("No archives to clean.")
            return

        archives = sorted(self.archive_dir.iterdir(), reverse=True)
        to_delete = archives[keep_count:]

        if not to_delete:
            print(f"✓ Keeping {len(archives)} archives (no cleanup needed)")
            return

        print(f"\n🗑️  Cleaning up old archives (keeping {keep_count}):\n")
        for archive in to_delete:
            shutil.rmtree(archive)
            print(f"  Deleted: {archive.name}")

        print(f"\n✅ Cleanup complete!")

def main():
    manager = ScreenshotManager()

    if len(sys.argv) < 2:
        print("Screenshot Manager - Manage marketing screenshots\n")
        print("Commands:")
        print("  list       - List all current screenshots")
        print("  archives   - List archived screenshot sets")
        print("  export DIR - Export latest screenshots to a directory")
        print("  metadata   - Generate JSON metadata file")
        print("  clean [N]  - Clean archives, keeping N most recent (default: 5)")
        return

    command = sys.argv[1]

    if command == "list":
        manager.list_screenshots()
    elif command == "archives":
        manager.list_archives()
    elif command == "export":
        if len(sys.argv) < 3:
            print("❌ Please specify an output directory")
            print("Usage: python3 tool/screenshot_manager.py export /path/to/dir")
            return
        manager.export_screenshots(sys.argv[2])
    elif command == "metadata":
        manager.generate_metadata()
    elif command == "clean":
        keep = int(sys.argv[2]) if len(sys.argv) > 2 else 5
        manager.clean_old_archives(keep)
    else:
        print(f"❌ Unknown command: {command}")

if __name__ == "__main__":
    main()

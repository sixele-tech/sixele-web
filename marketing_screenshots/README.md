# Sixele Marketing Screenshots

This directory contains marketing screenshots for Sixele, organized in a rerunnable system that ensures consistency and easy updates.

## Directory Structure

- **latest/** - Current marketing screenshots (always contains the freshest version)
- **archive/** - Timestamped backups of previous screenshot sets
- **index.html** - Gallery viewer to preview all screenshots

## How to Capture Screenshots

The screenshot capture is completely automated and rerunnable:

```bash
./capture_marketing_shots.sh
```

### What This Does

1. ✅ Runs Flutter tests to render all screens with real fonts and styling
2. 💾 Automatically backs up the previous `latest/` folder to `archive/` with a timestamp
3. 📸 Generates fresh PNG screenshots in `latest/`
4. 📄 Generates an interactive HTML gallery at `marketing_screenshots/index.html`
5. 🌐 Copies the fresh screenshots into `screenshots/`, so the site shows them with no HTML edits (see `../README.md`)

### Available Screenshots

The script captures the following marketing-ready screens:

- **dashboard.png** - Main user dashboard (light theme)
- **dashboard_dark.png** - Dashboard in dark theme
- **dashboard_timer.png** - Dashboard with an active Check On Me timer
- **check_on_me.png** - Check On Me setup screen
- **home_safe.png** - "I'm Home Safe" confirmation screen
- **practice_coach.png** - Disguise practice/music player mode
- **guardians.png** - Guardian management screen
- **report.png** - User wellness report
- **signup_touch.png** - Sign-up flow, "staying in touch" prompt
- **record_flow.png** - Record creation flow
- **record_detail.png** - View detailed record
- **guardian_invite.png** - Guardian invitation flow
- **guardian_alert.png** - Guardian alert response flow

## Viewing Screenshots

### In Browser
Open `marketing_screenshots/index.html` in your web browser to see an interactive gallery with all screenshots.

### For Export
All PNG files are in `marketing_screenshots/latest/` and ready to:
- Copy to marketing materials
- Upload to design tools
- Share in presentations
- Include in documentation

## Technical Details

### Why This System?

1. **Rerunnable** - Run the script anytime to get fresh screenshots. Useful when UI changes.
2. **Versioned** - Old screenshots are automatically archived with timestamps.
3. **Consistent** - Uses the same Flutter test rendering that ensures real fonts and styling match production.
4. **Zero Config** - Just run the script; it handles paths and backups automatically.

### Environment Variables

When needed, you can manually run the Flutter test:

```bash
export SIXELE_SHOTS=/path/to/output
flutter test test/screenshots_test.dart --dart-define=dangerouslyDisableSandbox=true
```

### Adding New Screenshots

Edit `test/screenshots_test.dart` to add new `testWidgets` blocks:

```dart
testWidgets('my new screen', (tester) async {
  await shoot(
    tester,
    'my_new_screen',
    MyNewScreen(...),
    height: 1200,
  );
});
```

Then run the capture script again.

## Notes for Marketing

- Screenshots are device-accurate (iPhone resolution, 390x844)
- Real platform fonts render (Google Fonts)
- UI components match production exactly
- Dark and light themes are both captured where relevant
- All screenshots include the Quick Exit widget (safety feature visible)

## Maintenance

- Check `archive/` periodically for old sets to delete if storage is needed
- Re-run the script after any UI changes to keep marketing materials up-to-date
- Update the list above if new screens are added to the capture

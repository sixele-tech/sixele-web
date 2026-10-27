# The Sixele website

This repository holds the public site at [sixele.co.za](https://sixele.co.za) and the marketing screenshot library. It expects the app checked out beside it at `../sixele-app` (or set `SIXELE_APP_DIR`), because the fonts, brand marks and pebble icons are copied from the app.

## Rules that bind everything

Two standing rules (SIX-168) bind every page, every piece of marketing and
every change, here and in the app and the service:

- **The name the app goes by on her phone is never written here.** It lives
  only in the build configuration of a release and in the store accounts:
  not on the site, not in this README, not in a commit message. Here it is
  "the disguise" or "the calm app". These repositories may one day be public,
  and a leaked page or screenshot must not join the two names.
- **The founder is named in public only where the law requires it.** No
  founder story, team page, byline, photo or interview: the site and every
  piece of marketing speak as Sixele, never as a person. The founder's name
  appears only in the documents the law demands (the Information Officer
  registration and the PAIA manual, the CIPC records) and on the store
  listing, where the store prints it itself.

  **One exception, the owner's choice on 27 October 2026:** the donors page
  speaks as a person in two places, the funding section, which is a letter
  from the founder, and the closing invitation to write. Donors should know
  a person is behind Sixele who wants to talk to them and hear from them.
  The letter is signed with initials only, so it adds as little as it can to
  the path from the store listing's name to Sixele; the name itself still
  never appears, and every other page still speaks as Sixele.

`tool/check_names.sh` checks both on every pull request, on every push to
`main`, and in the deploy before anything is published. It reads the names
from the `FOUNDER_NAMES` and `DISGUISE_NAME_CHECK` secrets (separated by
commas or new lines), never from a file, and fails on any tracked file that
holds one in its path or its contents — images included, since their
metadata can carry an author's name, and a name split across a line break.
It names the file and line but never the name; a file whose path holds the
name is given only by its number in `git ls-files`. Strip the metadata from
any picture before it is added. Run without the names it skips each check
and says so; in CI a missing secret fails the build. Each search runs in a
UTF-8 locale and again byte by byte, so a name beyond ASCII folds case and a
name in image metadata is found beside bytes that are not text.
`tool/check_names_test.sh` tests the check with made-up names; CI runs it.

Four static pages built from the same design system as the app, following the
[design canvas](https://claude.ai/artifact/NNCiyxcZAGDj8XjpeZsgF3): a landing
page that asks who you are here for, then one page each for her, for someone
who loves her, and for donors. No build step, no framework, nothing loaded
from anyone else: open it with any static server.

```sh
python3 -m http.server 8765   # then http://localhost:8765
```

| File | What it is |
| --- | --- |
| `index.html` | The landing page: who are you here for, and why this app wishes it did not exist. |
| `myself.html` | 1 · For myself: keep witness. |
| `someone-i-love.html` | 2 · For someone I love: keep safe. |
| `donors.html` | 3 · For donors: tech for GBV, the law, and what funding pays for. |
| `404.html` | What GitHub Pages serves for an address that does not exist. |
| `styles.css` | The design system for the web: the tokens from `lib/theme/` and the rules of `openspec/specs/design-language/spec.md`. |
| `site.js` | **Leave now** only. The pages work without it. |
| `build_site.sh` | Assembles `_site/` from an explicit list of files and checks every local link resolves. The deploy runs it. |
| `tool/check_names.sh` | Fails if a founder's name or the disguise name, supplied by CI secrets, is in any tracked file's path or contents, image metadata included. CI and the deploy run it; `tool/check_names_test.sh` tests it. |
| `sync_assets.sh` | Copies fonts, brand marks and pebble icons in from the app, then runs the build check. |
| `fonts/`, `brand/`, `icons/` | **Copies. Never edit these** — the next sync overwrites them. Change the source in the app and sync. |
| `marketing_screenshots/` | The screenshot library, for marketing material. **Never published**: `build_site.sh` does not copy it. |
| `CNAME` | The custom domain for GitHub Pages. |

## Publishing

Every push to `main` runs `.github/workflows/deploy.yml`, which runs
`build_site.sh` and deploys `_site/` to GitHub Pages at `sixele.co.za`. Pull
requests run the same build check. A page that links to a file that would not
be published fails the build, so a broken link never goes live.

The things only an account owner can set: the Pages source on the repository
(Settings → Pages → Source: GitHub Actions) and the DNS records at the
registrar (four `A` records on `@` to GitHub Pages, a `CNAME` on `www` to
`sixele-tech.github.io`). They are written out in Linear (SIX-144).

## The words

The rules every page follows, from SIX-98 and WC-09:

- **Never describe what the app looks like on her phone.** Not the kind of app,
  not its name, not the word "music". The pages say what it does not show (no
  Sixele name, mark or notification) and what that cannot protect her from.
- **Nothing false about where it stands.** Not in the stores yet; the service
  not yet in production; Sixele-as-guardian not built. Each is said plainly.
- **No placeholder text goes live.** Where the design canvas has a bracketed
  placeholder, the page says what is true today and a Linear issue carries the
  fill-in.
- **The owner approves the words.** Claude drafts.

## The design system on the web

`styles.css` follows the app's rules: square corners, the 6px grid, IBM Plex
with one job per family (serif titles, sans voice, mono facts), the semantic
colours in light and dark from the visitor's own setting, plum for shadows,
48 minimum for anything tappable, notices in the flow, and brand marks only
ever placed directly on the page colour. If a token changes in `lib/theme/`,
change it in the `:root` block at the top of `styles.css`.

Two things differ from an app screen, on purpose: the page is two reading
columns wide (1104) rather than one, and **Leave now** sits in the sticky
header rather than pinned bottom-right, as the design canvas has it.

## Before publishing — what is still open

Each of these is a Linear issue; the pages are honest about them meanwhile.

- The donors page has no figures: no total, no cost per woman, no amount per
  line (SIX-146, waiting on the budget).
- The law and ethics section on the donors page has not been checked by an
  attorney (SIX-147).
- No privacy policy, PAIA manual or store listing to link yet (SIX-148).
- The helpline numbers are the ones in `lib/data/questions.dart` (`helpLines`)
  and need the same practitioner check as the app's (SIX-130).
- **Leave now** goes to a weather search. It can't clear browser history; the
  footer says so.

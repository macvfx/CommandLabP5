# Changelog

## 0.1.0 — 2026-11-04

Initial public release candidate.

- Added labelled REST and nsdchat demonstration recipes for P5 server info,
  volumes, archive indexes, plans, overview, jukeboxes, and archived-file lookup.
- Added local direct, local awfile, and remote awsock CLI connection modes.
- Added saved profiles, macOS Keychain password storage, custom recipes, and
  command transcript export.
- Added redacted previews, custom-command confirmation, JSON syntax colouring,
  newest-result focus, stacked/side-by-side layouts, and detached output.
- Added a custom icon, About panel, topic-based in-app Help, User Guide, privacy
  guidance, and QA checklist.
- Added certificate inspection, endpoint-bound SHA-256 trust for self-signed P5
  certificates, changed-certificate refusal, and explicit no-fallback HTTPS.

Known acceptance limits:

- Built-in command construction is tested, but the complete recipe set has not
  been accepted against multiple live P5 versions.
- Release packaging and notarization evidence are maintained outside source
  control.

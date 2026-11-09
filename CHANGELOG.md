# Changelog

## 0.5.1 (build 8) — 2026-11-08

- Added reviewed import and secret-free export of the shared `P5Servers.json`
  format. Imports accept wrapped or bare lists, string or integer ports, and
  both `useHTTPS` and `scheme`; duplicates are skipped using connection identity.
- Kept passwords, certificate pins, demo profiles, local executable paths, and
  awfile settings out of portable exports. Non-default nsdchat ports round-trip
  through an optional compatible extension.
- Added daily rate-limited and on-demand GitHub release checks using the shared
  `GitHubUpdateChecker` package. The checker opens a release page only after
  confirmation and never downloads or installs an update.

## 0.5.0 (build 7) — 2026-11-06

- Added bounded nsdchat connection, login, command, communication, and hard
  process timeouts so an unavailable CLI endpoint cannot leave Command Lab
  waiting indefinitely.
- Enforced Remote over awsock for every profile host other than `127.0.0.1`.
  Profile selection, host editing, command preview, and execution now agree,
  preventing a stale Local selection from silently running against P5 on the
  Mac.
- Added an in-app remote-profile safety notice, disabled local CLI choices for
  remote profiles, and documented the timeout and connection-selection rules.

## 0.4.0 — 2026-11-04

- Added saved offline demo profiles with Healthy Library, Busy Archive Week,
  Tape Needs Attention, and Archive Index Discovery scenarios.
- Added fictional, deterministic REST and nsdchat results for every built-in
  recipe and every recipe in the supplied read-only comparison pack.
- Kept authentic command construction visible while guaranteeing that an
  offline demo run cannot open a network connection, launch `nsdchat`, read a
  Keychain password, or inspect a certificate.
- Added prominent simulated-command/result markers and a dedicated purple
  offline-demo treatment to prevent demo output from being mistaken for live
  server evidence.
- Added backward-compatible profile decoding and regression coverage for the
  complete demo matrix. Unsupported custom recipes stop explicitly instead of
  inventing a successful response.
- Simplified profile management to one **New** action and an in-editor **Demo
  Mode** checkbox, with the primary **Save Profile** action visually separated
  from destructive **Delete Profile**.

## 0.3.0 — 2026-11-04

- Added **Demo > Install Archiware P5…**, modelled on the dedicated installer
  flow in Eclectic Light Updater. It detects the standard nsdchat path, reads
  the local P5 service version with `srvinfo lexxvers`, and resolves only an
  official HTTPS `awpst*-darwin.dmg` link from Archiware's current download
  page.
- Kept installation operator-controlled: the helper confirms before opening
  the vendor installer and falls back to Archiware's stable download page
  without silently downloading or installing P5.
- Fixed automatic installer lookup for Archiware's live WordPress `&#038;`
  query encoding and added the published P5 version to the lookup status and
  download confirmation.
- Made the blue default action state-dependent: download the detected installer
  on success, or open Archiware's download page when automatic lookup fails;
  **Check Again** remains secondary.
- Added a documentation-only write-command test and verification plan covering
  inventory and backup file writes, guarded volume-mode changes, jukebox jobs,
  ArchiveEntry metadata, proof states, receipts, and destructive exclusions.

## 0.2.0 — 2026-11-04

- Added import and local persistence for versioned JSON command packs.
- Added strict validation that accepts only explicitly read-only commands and
  GET-only REST recipes, rejects unsafe headers and malformed placeholders,
  and replaces an older imported pack sharing the same stable id.
- Added imported-pack grouping, source attribution, removal, and a clear
  read-only badge in the command panel.
- Added a public example pack with REST/nsdchat comparisons for clients,
  volumes, jobs, jukeboxes, and ArchiveEntry status.
- Documented the pack schema, initial candidate matrix, and the deferred safety
  design for mutating commands such as changing a volume mode to Readonly.

## 0.1.1 — 2026-11-04

- Added P5Kit API examples, the official Archiware REST API reference, the
  official nsdchat CLI manual, and the Archiware manuals hub to the README,
  User Guide, Help menu, and a dedicated in-app References topic.
- Clarified which references are authoritative vendor documentation and which
  are independent integration examples.

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
- Release packaging, notarization evidence, and application source are
  maintained privately.

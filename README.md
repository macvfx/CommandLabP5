# P5 Command Lab

P5 Command Lab is a native SwiftUI macOS presentation companion for previewing,
explaining, saving, and running basic Archiware P5 REST API and `nsdchat`
commands.

It is intended for demonstrations, training, and repeatable read-only checks. A
P5 server is not required to preview commands or run the built-in offline demo.

This public repository contains the product documentation, changelog, issue
tracker, and example command-pack data. The application source is maintained
privately.

## Current capabilities

- P5 8 REST `v1` requests with editable HTTP/HTTPS host and port.
- Saved offline demo profiles with four scenarios and deterministic fictional
  REST/CLI results; demo runs perform no network or process activity.
- Explicitly labelled REST and `nsdchat` command recipes.
- Local direct, local `awfile`, and remote `awsock` CLI connection forms.
- Automatic, enforced `awsock` selection for profiles not targeting
  `127.0.0.1`, plus bounded CLI timeouts and process termination.
- A Demo-menu installer helper that detects the standard `nsdchat` path,
  reads the local P5 service version with `srvinfo lexxvers`, resolves the
  current official macOS P5 DMG, and leaves installation to the vendor
  installer.
- Server release and uptime, volumes, archive indexes, plans, archive overview,
  jukeboxes, and ArchiveEntry handle lookup.
- Saved server profiles, Keychain passwords, custom recipes, and transcript
  export.
- Portable `P5Servers.json` import and export compatible with the P5 app suite;
  passwords, certificate trust, demo profiles, and local tool paths are excluded.
- Daily, rate-limited GitHub release checks plus an on-demand **Check for
  Updates…** command. Updates are never downloaded or installed automatically.
- Versioned JSON command-pack import with strict read-only validation and
  replacement by stable pack identifier.
- Reviewable HTTPS certificates with endpoint-bound SHA-256 pinning for P5's
  self-signed certificate and changed-certificate warnings.
- Redacted command previews and a confirmation gate for custom commands.
- Cyan REST previews, amber CLI output, and jq-inspired JSON colouring.
- Stacked, side-by-side, and detachable floating-output presentation layouts.
- Optional newest-result focus that dims earlier output blocks.
- Custom About panel and topic-based in-app Help.

The supplied recipes are read-only. Custom recipes can describe other HTTP
methods or CLI verbs, so inspect the constructed command before running one.
Imported packs in 0.5.1 are deliberately restrictive: every recipe must be explicitly
classified read-only, and REST recipes must use `GET`.

## Requirements

- macOS 13 or later.
- A local `nsdchat` binary for CLI execution. REST preview and execution do not
  require `nsdchat`.
- Network access to a P5 server only when a command is run from a live profile.

## Optional local P5 test server

For disposable live REST and CLI testing on an Apple-silicon Mac, see
[P5 Local Lab Setup](https://github.com/macvfx/P5-local-lab-setup). It builds
the official Intel Linux P5 container locally, restricts P5 to a dedicated
fixture folder and localhost port, and supports multiple isolated instances.
The Apple `container` workflow is tested on macOS 27.2; the included Docker
alternative is untested.

P5 Command Lab does not create, licence, start, stop, or delete these servers.
Add a running lab instance as an ordinary live server profile. Unlicensed P5
instances can answer useful read-only commands; a vendor trial is optional for
tests that create indexes, plans, archives, or restores.

The app permits HTTP because many P5 REST installations use an unencrypted
local endpoint. Prefer HTTPS on networks where it is available. If macOS does
not trust a P5 certificate, **Check Certificate** shows its subject and SHA-256
fingerprint before it can be saved for that exact host and REST port. A changed
certificate is refused, and HTTPS never falls back to HTTP.

## Help and privacy

Choose **Help > P5 Command Lab Help** or press Command-Question Mark for concise
topic-based guidance. Choose **P5 Command Lab > About P5 Command Lab** for the
installed version, privacy summary, User Guide, and
[code.matx.ca](https://code.matx.ca).

Profiles and custom recipes stay in the current user's app preferences.
Passwords are stored separately in macOS Keychain. A certificate fingerprint
explicitly trusted by the operator is stored with its local server profile.
Previewing or copying a command does not contact P5. Checking a certificate or
running a recipe from a live profile contacts only the configured server.
Offline demo runs never contact P5, launch `nsdchat`, read a Keychain
password, or inspect certificate trust. Importing or exporting a server list is
local-only. The app reads public GitHub release metadata at most once per day
and when **Check for Updates…** is selected; it opens a release page only after
operator confirmation. Opening the installer
helper contacts Archiware's official download page to locate the current macOS
DMG; the app does not download or install it silently. P5 Command Lab has no
account, analytics, telemetry, cloud service, or background service.

Server profiles, revealed command previews, responses, screenshots, and
exported transcripts can contain sensitive operational information. Review and
redact them before sharing.

## Documentation

- [User Guide](Docs/USER_GUIDE.md)
- [P5 Connections and Credential Security](Docs/P5_CONNECTIONS_AND_SECURITY.md)
- [QA Checklist](Docs/QA_CHECKLIST.md)
- [Command Pack Format](Docs/COMMAND_PACK_FORMAT.md)
- [Command Catalog and Candidates](Docs/COMMAND_CATALOG.md)
- [Write Command Pack Test and Verification Plan](Docs/WRITE_COMMAND_PACK_PLAN.md)
- [Example Read-only Comparison Pack](CommandPacks/P5-Read-Only-Comparisons.json)
- [Optional local P5 test server](https://github.com/macvfx/P5-local-lab-setup)
- [Changelog](CHANGELOG.md)
- [Releases](https://github.com/macvfx/CommandLabP5/releases)
- [Issue tracker](https://github.com/macvfx/CommandLabP5/issues)
- [code.matx.ca](https://code.matx.ca)

## P5 references

- [P5Kit API examples](https://github.com/macvfx/P5Kit-Docs/blob/main/P5_API_EXAMPLES.md) — independent, curated integration examples using fictional data.
- [Official Archiware P5 REST API](https://www.archiware.com/blog/redoc/p5_rest_api/awp5api.html) — the authoritative REST resource and request reference.
- [Official P5 CLI/nsdchat manual](https://support.archiware.com/downloads/cli.pdf) — connection forms, commands, arguments, and return values.
- [Archiware Manuals & Guides](https://www.archiware.com/manuals/) — documentation appropriate to the installed P5 version.

The Archiware references define the supported P5 contract. P5Kit Docs and P5
Command Lab supplement them with integration and presentation examples.

All sample hosts, users, paths, media, and identifiers in this public
repository are fictional or reserved for documentation.

## License

The documentation and example command-pack data in the current branch are
available under the [MIT License](LICENSE). The application source is
maintained privately.

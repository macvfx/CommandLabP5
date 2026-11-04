# P5 Command Lab

P5 Command Lab is a native SwiftUI macOS presentation companion for previewing,
explaining, saving, and running basic Archiware P5 REST API and `nsdchat`
commands.

It is intended for demonstrations, training, and repeatable read-only checks. A
P5 server is not required to preview commands.

## Current capabilities

- P5 8 REST `v1` requests with editable HTTP/HTTPS host and port.
- Explicitly labelled REST and `nsdchat` command recipes.
- Local direct, local `awfile`, and remote `awsock` CLI connection forms.
- Server release and uptime, volumes, archive indexes, plans, archive overview,
  jukeboxes, and ArchiveEntry handle lookup.
- Saved server profiles, Keychain passwords, custom recipes, and transcript
  export.
- Reviewable HTTPS certificates with endpoint-bound SHA-256 pinning for P5's
  self-signed certificate and changed-certificate warnings.
- Redacted command previews and a confirmation gate for custom commands.
- Cyan REST previews, amber CLI output, and jq-inspired JSON colouring.
- Stacked, side-by-side, and detachable floating-output presentation layouts.
- Optional newest-result focus that dims earlier output blocks.
- Custom About panel and topic-based in-app Help.

The supplied recipes are read-only. Custom recipes can describe other HTTP
methods or CLI verbs, so inspect the constructed command before running one.

## Requirements

- macOS 13 or later.
- Swift 5.10 or later for source builds.
- A local `nsdchat` binary for CLI execution. REST preview and execution do not
  require `nsdchat`.
- Network access to a P5 server only when a command is run.

## Build and test

```sh
swift test
zsh scripts/build_app.sh release
open "Build/P5 Command Lab.app"
```

The build script compiles the icon catalog and prefers
`P5_SIGNING_IDENTITY` or the first available macOS code-signing identity. If no
identity is available, it falls back to ad-hoc signing and prints a warning.
Signing identities, notarization profiles, local credentials, and build outputs
are not stored in this repository.

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
running a recipe contacts only the configured server. P5 Command Lab has no
account, analytics, updater, telemetry, cloud service, or background service.

Server profiles, revealed command previews, responses, screenshots, and
exported transcripts can contain sensitive operational information. Review and
redact them before sharing.

## Documentation

- [User Guide](Docs/USER_GUIDE.md)
- [QA Checklist](Docs/QA_CHECKLIST.md)
- [Changelog](CHANGELOG.md)
- [Issue tracker](https://github.com/macvfx/CommandLabP5/issues)
- [code.matx.ca](https://code.matx.ca)

All sample hosts, users, paths, media, and identifiers in the repository are
fictional or reserved for documentation.

## License

P5 Command Lab is available under the [MIT License](LICENSE).

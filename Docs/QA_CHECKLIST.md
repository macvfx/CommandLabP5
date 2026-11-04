# QA Checklist

## Automated

- [x] Swift package builds in Debug and Release configurations.
- [x] Unit tests pass.
- [x] Command picker labels every recipe REST or nsdchat.
- [x] Local direct, local awfile, and remote awsock command construction is tested.
- [x] REST authentication previews redact passwords by default.
- [x] Certificate pins are bound to the saved host and REST port.
- [x] Fingerprints compare consistently with or without separators.
- [x] A disposable self-signed TLS endpoint accepts the exact pin and refuses a changed pin.
- [x] Documentation validation and privacy scans pass.
- [x] `git diff --check` passes.

## Manual macOS acceptance

- [x] Main window launches with the custom app icon and presentation theme.
- [x] Stacked and Side by Side layouts render without clipped controls.
- [x] Detach Output opens a resizable floating window.
- [x] Focus newest can be enabled and disabled.
- [x] Command picker visibly labels every recipe REST or nsdchat.
- [x] Local direct, local awfile, and remote awsock previews update correctly.
- [x] About shows icon, version/build, privacy summary, Help, User Guide, and website.
- [ ] Help opens from the Help menu and Command-Question Mark.
- [x] Help topic switching and Done work without opening an external page.
- [ ] A password stored from the release build survives quit and relaunch.
- [ ] A disposable self-signed HTTPS endpoint can be inspected and trusted.
- [ ] A trusted endpoint connects without disabling certificate validation.
- [ ] Replacing the disposable certificate refuses the request and offers review.
- [ ] Forget Certificate restores normal macOS certificate verification.
- [ ] Each built-in REST command is accepted by a disposable P5 environment.
- [ ] Each built-in nsdchat command is accepted locally and remotely.
- [ ] Transcript export is reviewed using a disposable fictional fixture.

Automated success is not evidence that a live P5 server accepted a command.
Live acceptance should use a disposable or read-only environment and must not
place real server details in screenshots, issues, fixtures, or this repository.

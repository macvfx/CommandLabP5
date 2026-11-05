# QA Checklist

## Automated

- [x] Swift package builds in Debug and Release configurations.
- [x] Unit tests pass.
- [x] Command picker labels every recipe REST or nsdchat.
- [x] Local direct, local awfile, and remote awsock command construction is tested.
- [x] REST authentication previews redact passwords by default.
- [x] Every built-in and supplied comparison-pack recipe has a fictional demo
  result for all four offline scenarios.
- [x] Legacy saved profiles decode with demo mode disabled, and demo profiles
  round-trip with their selected scenario.
- [x] Unsupported demo recipes fail explicitly; the pure demo runner accepts no
  URL request or executable path.
- [x] Certificate pins are bound to the saved host and REST port.
- [x] Fingerprints compare consistently with or without separators.
- [x] Installer-link parsing accepts the official macOS filename pattern,
  handles HTML-escaped queries, chooses the newest candidate, and rejects
  another host or insecure download page.
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
- [ ] The Demo Mode checkbox hides live credentials and certificate controls;
  clearing it restores the same profile's live fields.
- [ ] Each demo scenario is visibly marked offline and produces a simulated
  command/result without P5 running or `nsdchat` installed.
- [ ] Switching between demo and live profiles never carries a demo credential,
  certificate decision, or simulated result into live execution.
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
- [ ] Demo > Install Archiware P5 opens the helper and accurately reports
  whether `/usr/local/aw/bin/nsdchat` exists.
- [ ] With local P5 running, the helper reports the same installed service
  version as `nsdchat -c srvinfo lexxvers` run independently.
- [ ] With nsdchat present but the local service unavailable, the helper keeps
  the installed result and reports the version probe failure separately.
- [ ] Installer lookup resolves the current official macOS New Install DMG and
  its download confirmation opens only the Archiware URL shown.
- [ ] A changed or missing installer link falls back to the official download
  page without guessing a filename.
- [ ] A detected installer makes Download Installer the blue default action;
  a failed lookup makes Open Archiware Download Page the blue default action.
- [ ] Transcript export is reviewed using a disposable fictional fixture.

Automated success is not evidence that a live P5 server accepted a command.
Live acceptance should use a disposable or read-only environment and must not
place real server details in screenshots, issues, fixtures, or this repository.

## Future write-pack evidence gate

These items apply before any schema version 2 write pack is import-enabled.
They are planning gates, not claims about P5 Command Lab 0.4.0:

- [ ] Every candidate has reached at least **Static-validated** in the
  [Write Command Pack Test and Verification Plan](WRITE_COMMAND_PACK_PLAN.md).
- [ ] File-writing commands use new disposable paths and verify destination
  ownership, file existence, nonzero size, and expected format where the path
  is accessible.
- [ ] REST volume updates preserve `enabled`, `label`, `location`, and `state`
  while changing only the confirmed `mode`.
- [ ] Each mutation records before-state, exact target, redacted request,
  delivery outcome, response, and verified after-state.
- [ ] Ambiguous mutations are not automatically replayed.
- [ ] Job-starting commands capture a job identity and confirm a terminal state;
  disappearance from an active list is not treated as success.
- [ ] ArchiveEntry metadata tests prove that existing clips remain untouched.
- [ ] Excluded destructive operations are rejected by import validation.
- [ ] Receipts, screenshots, fixtures, and documentation pass privacy review
  with only fictional identifiers.

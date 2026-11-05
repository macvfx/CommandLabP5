# P5 Command Lab User Guide

This is the canonical operating guide for P5 Command Lab 0.3.0.

## Purpose and safety boundary

P5 Command Lab demonstrates the shape of Archiware P5 REST API and `nsdchat`
commands before optionally running them. Previewing, copying, editing, or saving
a recipe does not contact a server.

The built-in and validated imported recipes are read-only. Custom recipes can use arbitrary REST
methods or `nsdchat` verbs. The app therefore asks for confirmation before
running a custom recipe, but it cannot prove that the command is safe.

## Configure a server profile

The P5 Server panel contains:

- a local profile name;
- host or IP address;
- REST port, normally `8000`;
- `nsdchat`/`awsock` port, normally `9001`;
- REST API version, normally `v1`;
- HTTP or HTTPS selection;
- username and password;
- local `nsdchat` executable path; and
- local `awfile` connection.

For documentation or rehearsal, use fictional values such as
`p5.example.invalid`, `<username>`, and `<password>`.

Press **New** to create a profile. Edit its fields, then press **Save**. Delete
removes the selected profile and its associated Keychain password. At least one
profile remains available.

### Password and Keychain status

The password is never stored in the profile or exported command history. It is
stored as a generic password item in macOS Keychain, keyed to the profile's
stable identifier.

A status below the profile reports:

- **Password stored in Keychain**;
- **Password changed — not stored yet**;
- **No password stored**; or
- the Keychain error returned by macOS.

Store an entered password by pressing Return in the field, clicking the key
button, saving the profile, or running a command. A newly signed build may ask
for Keychain permission the first time it accesses an older item.

### HTTPS certificate trust

P5 commonly presents a self-signed certificate that macOS cannot verify. When
HTTPS is selected, choose **Check Certificate…** to inspect the certificate's
subject and SHA-256 fingerprint.

- If macOS already trusts the certificate, choose **Use macOS Trust**. Nothing
  is pinned, so a normally renewed certificate can continue to work.
- For a self-signed certificate, compare the fingerprint with one obtained
  from the server administrator through a trusted channel, then choose
  **Trust This Certificate**.
- The accepted fingerprint is saved with the profile and bound to that exact
  host and REST port.
- If the server later presents a different certificate, the request is refused
  and the app shows the trusted and presented fingerprint prefixes. Choose
  **Review Certificate…** only after confirming why it changed.
- **Forget Certificate** removes the saved fingerprint and returns the profile
  to normal macOS verification.

A P5 upgrade, reinstall, or certificate renewal can legitimately replace a
certificate. An intermediary can do the same, so the replacement is never
accepted automatically. HTTPS failures never fall back to HTTP.

## Choose a command recipe

Every picker item is labelled **REST** or **nsdchat**. Built-in recipes cover:

- server release/build and uptime;
- all volumes and volume usage;
- archive indexes and plans;
- archive overview;
- jukeboxes and jukebox volumes; and
- archived-file handle lookup.

Fields required by the selected recipe appear below the picker. The constructed
command updates immediately.

## REST API commands

REST recipes use the selected scheme, host, REST port, API version, and saved
certificate decision. The app sends HTTP Basic authentication and requests
JSON. It pretty-prints valid JSON responses and preserves plain-text error
responses. Redirects are refused so credentials are not silently sent to a
different endpoint.

For example, the fictional profile `p5.example.invalid` constructs a server
information URL ending in:

```text
/rest/v1/general/srvinfo
```

The ArchiveEntry lookup passes client, path, and optional archive database as
request headers. A preview redacts the password unless **Reveal password in
preview** is deliberately enabled.

## nsdchat commands

All CLI modes execute the `nsdchat` binary configured in the profile. They use
direct process arguments; P5 Command Lab does not pass them through a shell.

### Local direct

Local direct mode adds `-c` and the recipe arguments. It is intended for
`nsdchat` running on the P5 server itself.

### Local via awfile

Local awfile mode adds the profile's `awfile` server argument before `-c`. The
default reflects P5's standard local lexxsrv service location and remains
editable.

### Remote over awsock

Remote mode uses the local `nsdchat` binary as a client and adds an `awsock`
server argument containing the selected profile's credentials, host, and port.
The password remains redacted in normal previews and transcripts.

Use the **Server version — nsdchat** and **Server uptime — nsdchat** recipes to
demonstrate `srvinfo lexxvers` and `srvinfo uptime` across these connection
forms.

### Install P5 and nsdchat

Choose **Demo > Install Archiware P5…** to open the installer helper. It checks
the standard `/usr/local/aw/bin/nsdchat` location. When present, it runs the
read-only local command `srvinfo lexxvers` to distinguish an installed CLI from
a reachable local P5 service and show the service version. It also reads
Archiware's official download page to locate the current
`awpst*-darwin.dmg` New Install link. The resolved filename and source are shown
before the browser opens.

When automatic lookup succeeds, **Download Installer…** is the blue default
action. If lookup fails, **Open Archiware Download Page** becomes the blue
default action instead. **Check Again** remains secondary in both states.

Finding the executable does not prove that the local P5 service is running. A
failed version query is reported separately and does not erase the positive
nsdchat installation result.

This is the full Archiware P5 installer, not a standalone nsdchat package. P5
Command Lab does not mount the DMG, bypass the vendor's licence or choices, or
run a privileged installation. If automatic lookup fails, use **Open Archiware
Download Page** and select macOS New Install manually.

## Run and read a result

Press **Run Read-only Command** after reviewing a built-in recipe. The output
contains a timestamped command block followed by its result or error.

- REST JSON uses jq-inspired key, string, number, Boolean, and error colours.
- CLI output uses an amber terminal treatment.
- **Focus newest** dims earlier blocks and highlights the latest result.
- **Clear** removes the current console history without changing P5.

P5 Command Lab does not automatically retry or reinterpret a failed command.

## Presentation layouts

- **Stacked** places output below the controls.
- **Side by Side** gives output a full-height right column.
- **Detach Output** opens a resizable, always-on-top presentation window.

The selected main-window layout persists between launches. The detached output
shows the same live console history and newest-result preference.

## Custom recipes

Choose **New Custom…**, then provide a name, summary, transport, template, and
comma-separated variables.

- REST templates are relative API paths such as `general/jobs`.
- CLI templates are arguments after `nsdchat -c`.
- Variables use braces, such as `{volume}`, `{client}`, or `{path}`.

Custom recipes are stored locally. Before execution, P5 Command Lab explains
that it cannot classify an arbitrary recipe as read-only and asks for explicit
confirmation.

## Import read-only command packs

Choose **Demo > Import Read-only Command Pack…** or **Import Pack…** beside the
recipe picker, then select a JSON pack. Imported recipes appear in a section
named for that pack. Importing the same stable pack id again replaces its older
version; **Remove Pack** removes the whole selected pack.

Version 0.3.0 deliberately accepts only recipes marked `read-only`. REST
recipes must use `GET`; reserved authentication/host headers, unknown template
placeholders, absolute REST URLs, parent-path traversal, duplicate command
UUIDs, and unsupported schema versions are rejected. Review the displayed
source attribution and constructed command before running it.

The repository includes
[`P5-Read-Only-Comparisons.json`](../CommandPacks/P5-Read-Only-Comparisons.json)
as an importable starting pack. See the
[Command Pack Format](COMMAND_PACK_FORMAT.md) and
[Command Catalog](COMMAND_CATALOG.md) for current authoring and candidate
details. Future non-read-only candidates remain documentation-only in the
[Write Command Pack Test and Verification Plan](WRITE_COMMAND_PACK_PLAN.md)
until their safety and live-version evidence gates are satisfied.

## Transcript export

Choose **Export Transcript…** to write the current console text to a file. The
export omits the stored Keychain password unless it was deliberately revealed
in a command preview before execution.

Responses can still contain server paths, hostnames, client names, archive
indexes, job IDs, media labels, or opaque handles. Review and redact a
transcript before attaching it to an issue or using it in public material.

## In-app Help and About

- Choose **Help > P5 Command Lab Help** or press Command-Question Mark for the
  topic-based quick guide.
- Choose **Help > Full User Guide** to open this document on GitHub.
- Choose **P5 Command Lab > About P5 Command Lab** for the installed version,
  build, privacy summary, Help, and User Guide.
- Choose **Help > Report an Issue** to open the public issue tracker.

External pages are contacted only when one of these links is selected.

## Privacy

P5 Command Lab does not:

- require or create an account;
- collect analytics, telemetry, usage information, or diagnostics;
- upload profiles, recipes, transcripts, or server responses;
- scan the local network or discover P5 servers;
- include an automatic updater, cloud service, or background service; or
- run a command merely because it was selected or previewed.

Running a recipe sends the constructed request or command to the configured P5
server. Checking a certificate makes a TLS connection only to that configured
host and port. Saved certificate fingerprints are public certificate metadata,
remain in the local profile, and are not exported automatically. Support links
open their public destinations only when selected.

Profiles, screenshots, revealed commands, responses, and transcripts can be
sensitive. Use fictional values for demonstrations and redact real operational
information before sharing.

## Troubleshooting

- **Password is not restored:** read the Keychain status below the profile.
  Re-enter it once in a newly signed build and click the key button. Confirm any
  macOS Keychain prompt for the expected P5 Command Lab application.
- **REST request fails:** verify scheme, host, port, API version, credentials,
  and whether the server permits HTTP or requires HTTPS.
- **The HTTPS certificate is invalid:** click **Check Certificate…**, compare
  its subject and SHA-256 fingerprint through a trusted channel, then save it
  for the selected endpoint.
- **The certificate changed:** the connection remains refused until the new
  fingerprint is reviewed. Confirm a server upgrade, reinstall, or renewal
  before choosing **Trust the New Certificate**.
- **nsdchat is missing:** verify the executable path. Remote CLI access still
  requires a local `nsdchat` installation. Use **Demo > Install Archiware P5…**
  to inspect the standard path and open the official installer.
- **Local awfile fails:** confirm the configured awfile service path matches the
  P5 installation.
- **ArchiveEntry lookup returns no handle:** verify the P5 client name, exact
  source path, and optional archive index.
- **Output is difficult to compare:** turn off Focus newest or use Side by Side
  and the detached output window together.

## More information

- [Source](https://github.com/macvfx/CommandLabP5)
- [Report an issue](https://github.com/macvfx/CommandLabP5/issues)
- [code.matx.ca](https://code.matx.ca)

### P5 documentation and examples

- [P5Kit API examples](https://github.com/macvfx/P5Kit-Docs/blob/main/P5_API_EXAMPLES.md) provide independent, curated examples using fictional hosts, paths, identifiers, and credentials.
- [Official Archiware P5 REST API](https://www.archiware.com/blog/redoc/p5_rest_api/awp5api.html) is the authoritative REST resource and request reference.
- [Official P5 CLI/nsdchat manual](https://support.archiware.com/downloads/cli.pdf) documents local and remote connection forms, commands, arguments, and return values.
- [Archiware Manuals & Guides](https://www.archiware.com/manuals/) helps locate documentation matching the P5 version installed at the site.

The official Archiware documentation is the authority for supported behavior.
P5Kit examples and this guide explain integration patterns and do not replace
the vendor contract.

# Write Command Pack Test and Verification Plan

This document is the review gate for a future importable P5 write-command
pack. It records candidates, expected effects, test fixtures, verification,
and exclusions before any schema version 2 implementation or live mutation
testing begins.

Nothing in this document is executable in P5 Command Lab 0.5.0. Command-pack
schema version 1 remains read-only and rejects these operations.

## Proof states

Each command advances independently through these states:

1. **Documented** — its proposed shape, effect, safeguards, and source are
   recorded here.
2. **Static-validated** — the shape is checked against the applicable official
   REST reference or CLI manual for the installed P5 version.
3. **Disposable-tested** — it is exercised once against an approved disposable
   target using fictional identifiers and non-production output paths.
4. **Live-version-verified** — its response and after-state are verified on
   every P5 version claimed by the pack.
5. **Import-enabled** — the app has the required execution gate, receipt,
   verification, and tests. Only then may the recipe enter a JSON pack.

Documentation or command construction alone is not evidence that a P5 server
accepted an operation. A successful response is not evidence of the final
after-state unless the verification step also succeeds.

## Effect classes

The future schema should classify observable effects independently of the HTTP
method:

| Effect | Meaning | Minimum execution gate |
| --- | --- | --- |
| `writes-file` | Creates or replaces a file on a P5 client filesystem | Exact destination preview and overwrite decision |
| `mutates-configuration` | Changes persistent P5 configuration or media metadata | Before-state read, typed confirmation, after-state read |
| `starts-job` | Schedules work and returns or implies a job | Confirmation, captured job identity, terminal-state monitoring |
| `controls-job` | Stops or cancels existing work | Exact job/status preview and terminal-state verification |
| `destructive` | Deletes, resets, recycles, restores over, or otherwise risks irreversible loss | Not allowed in the initial shared pack |

Every non-read-only recipe must use `replayPolicy: never`. If delivery is
ambiguous, retain the receipt and reconcile with read-only queries; do not
automatically send the mutation again.

## Initial candidate matrix

| ID | Candidate | Transport | Effect | Initial disposition | Current proof |
| --- | --- | --- | --- | --- | --- |
| W01 | Archive index inventory file | CLI and REST | `writes-file` | First pack | Documented |
| W02 | Volume inventory file | CLI and REST | `writes-file` | First pack | Documented; CLI pattern exists in P5 Archive Export |
| W03 | Archive index backup file | REST | `writes-file` | First pack | Documented |
| W04 | One exact Archive/TAPE volume: Full to Readonly | CLI | `mutates-configuration` | First guarded mutation | Documented; CLI pattern exists in P5 Archive Export |
| W05 | One exact Archive/TAPE volume: Full to Readonly | REST | `mutates-configuration` | After chained workflow support | Documented |
| W06 | Bounded jukebox inventory | CLI and REST | `starts-job` | After job monitoring/receipts | Documented |
| W07 | Existing ArchiveEntry metadata key update | CLI | `mutates-configuration` | Second-stage pack | Documented |
| W08 | Existing ArchiveEntry metadata key update | REST | `mutates-configuration` | Hold for version-specific body testing | Documented |
| W09 | Cancel or stop one exact job | CLI and REST | `controls-job` | Later operations pack | Candidate only |
| W10 | Submit archive or restore work | REST | `starts-job` | Guided workflow, not a flat recipe | Candidate only |

`Full` and `Readonly` are volume **modes**. They must not be described as the
volume `state`, whose values include `Ok`, `Suspect`, and `OutOfSync`.

## W01 — archive index inventory file

Proposed CLI shape:

```text
ArchiveIndex {index} inventory {client}:{absolutePath} ppath volumes size handle btime mtime ino checksum
```

Proposed REST shape:

```http
PUT /rest/v1/archive/indexes/{indexID}
filename: {client}:{absolutePath}
attributes: ppath volumes size handle btime mtime ino
```

The REST attribute list is intentionally narrower than the proposed CLI list.
Transport-specific attributes must be validated independently; the app must not
assume that every CLI attribute is accepted by REST.

Test fixture and verification:

- use a disposable archive index such as `Example-Archive`;
- use a new absolute filename under an approved test directory;
- show which P5 client owns the destination path;
- test a nonexistent destination first;
- test an existing destination only after the overwrite behavior is established
  and the operator explicitly approves it;
- preserve the response, selected attributes, client, path, and timestamps;
- when the destination is locally accessible, verify existence, nonzero size,
  and a parseable TSV header; otherwise record that remote filesystem
  verification remains outstanding; and
- sample fictional rows and confirm that handles and paths occupy the expected
  columns without publishing actual archive data.

## W02 — volume inventory file

Proposed CLI shape:

```text
Volume {volume} inventory {client}:{absolutePath} ppath size handle btime mtime
```

Proposed REST shape:

```http
POST /rest/v1/general/volumes/{volumeID}
filename: {client}:{absolutePath}
attributes: ppath size handle btime mtime ino
```

Preflight must read the exact volume and show its usage, media type, mode,
state, and location. Initial testing is limited to one disposable Archive
volume at a time.

Verification follows W01. Remote `localhost:` is resolved by the remote P5
server, not by the Mac running Command Lab; the UI and receipt must make that
destination ownership explicit.

## W03 — archive index backup file

Proposed REST shape:

```http
GET /rest/v1/archive/indexes/{indexID}
filename: {client}:{absolutePath}
```

Although this uses `GET`, it writes to a filesystem and must be classified
`writes-file`, not `read-only`. Test it with a new path first and use the same
destination, overwrite, receipt, and filesystem-verification rules as W01.

## W04 — Full to Readonly by CLI

Proposed CLI mutation:

```text
Volume {volume} mode Readonly
```

Required workflow:

1. Read the exact volume identity, usage, media type, mode, state, label, and
   location.
2. Require `usage = Archive`, media type `TAPE`, and current mode `Full`.
3. Refuse an already-`Readonly`, non-Archive, non-tape, missing, or ambiguous
   target.
4. Preview old mode `Full`, new mode `Readonly`, and the complete redacted
   command.
5. Require an exact confirmation such as `READONLY TEST-TAPE-001`.
6. Submit once.
7. Read the exact volume again and require mode `Readonly` before reporting
   success.
8. Save the before-state, command fingerprint, delivery outcome, response, and
   after-state in a durable receipt.

One confirmation applies to one exact volume. The first implementation must
not accept wildcards or bulk target lists. Returning a volume to `Full` is a
separate, separately confirmed operation and is not an automatic rollback.

## W05 — Full to Readonly by REST

The proposed request is:

```http
PUT /rest/v1/general/volumes/{volumeID}
Content-Type: application/json
```

The current REST schema requires `enabled`, `label`, `location`, `mode`, and
`state`. Therefore this cannot be a static recipe with a body containing only
`mode`. The execution engine must:

1. GET the current volume;
2. apply the same eligibility and confirmation gates as W04;
3. preserve the observed values of all required fields;
4. change only `mode` to `Readonly`;
5. PUT the complete object once; and
6. GET the volume again to verify the mode and ensure preserved fields did not
   change.

This candidate remains blocked from import until schema version 2 supports
dependent preflight reads and generated request bodies.

## W06 — bounded jukebox inventory

Proposed CLI shapes:

```text
Jukebox {jukebox} inventory
Jukebox {jukebox} inventory -barcode {startSlot} {endSlot}
```

Proposed REST shape:

```http
POST /rest/v1/general/jukeboxes/{jukeboxID}
action: inventory
barcode: {barcodeMode}
startSlot: {startSlot}
endSlot: {endSlot}
```

The UI must distinguish mount inventory from barcode inventory. Where slot
bounds are supported, testing starts with a small approved range. The receipt
must capture the returned job identity. Success requires a confirmed terminal
job state plus a read-only follow-up of the relevant jukebox/slot state; job
absence alone is not success.

Media labelling is not part of W06 and must not be inferred from the shared
REST operation that supports both `inventory` and `label` actions.

## W07 and W08 — ArchiveEntry metadata

Proposed CLI shape:

```text
ArchiveEntry {opaqueHandle} setmeta {existingKey} {value}
```

The workflow must GET/read the entry first, require a key that already exists
in the index, preview the old and new values, submit once, then read the entry
again and compare the value. The opaque handle must be treated as data; REST
must encode it as one path segment.

The REST candidate is held for version-specific testing. The published/request
schema and observed safe metadata-only behavior must be reconciled before a
body template is approved. In particular, the pack must not send an empty
`clippath`: that can delete an existing clip. Clip attachment or removal is
outside this pack.

## Later guided operations

### W09 — stop or cancel a job

Read the exact job and status first, distinguish scheduled stop from running
cancel semantics where applicable, require a job-specific confirmation, send
once, then verify a terminal state. A cancellation request is not confirmation
that work stopped.

### W10 — archive and restore submission

Archive and restore requests need guided workflow support for source-client
identity, plan and selection preview, path mapping, captured job IDs, restart
reconciliation, and independent output verification. They are not suitable as
uncoordinated command templates.

## Explicit exclusions from the initial shared pack

The importer should reject or reserve an administrator-only future tier for:

- `ArchiveEntry mask` and REST entry deletion;
- jukebox reset;
- archive index restore;
- archive index/key deletion;
- volume mode `Recyclable`;
- bulk or wildcard mutations;
- jukebox media labelling;
- clip attachment or deletion;
- plan changes that may remove source files; and
- automatic retry of any mutation with ambiguous delivery.

These exclusions remain in force even if a command is syntactically valid.

## Schema version 2 acceptance gates

Before an importable pack is created, the app design must support:

- explicit effect and risk classification;
- exact target identity with no unresolved placeholders;
- prerequisite reads and allowed before-state predicates;
- generated REST bodies derived from a pinned before-state;
- redacted command/request preview;
- typed, target-specific confirmation;
- single submission with `replayPolicy: never`;
- response and returned-job capture;
- required verification recipes and timeout/unknown outcomes;
- durable receipts that exclude passwords and authorization headers;
- per-recipe P5 version claims and proof state; and
- a global preference that keeps imported write packs disabled until the
  operator deliberately enables them.

## Test order

1. Review every shape against the manual matching the disposable P5 server.
2. Add unit tests for parsing, effect enforcement, confirmation, body
   preservation, redaction, receipts, and replay refusal.
3. Test W01–W03 with new disposable output paths.
4. Test W04 on one disposable Full Archive/TAPE volume and verify the
   after-state.
5. Test W05 only after the generated-body workflow passes unit tests.
6. Test W06 on a bounded, approved jukebox range and monitor the job.
7. Test W07 with an existing disposable metadata key.
8. Resolve W08 against each claimed P5 version before enabling it.
9. Review anonymized receipts and run the repository privacy scan.
10. Only then build a signed test release containing an opt-in schema version 2
    importer.

## References

- [P5Kit API examples](https://github.com/macvfx/P5Kit-Docs/blob/main/P5_API_EXAMPLES.md)
- [Official ArchiveIndexInventory REST operation](https://www.archiware.com/blog/redoc/p5_rest_api/awp5api.html#tag/archive/operation/ArchiveIndexInventory)
- [Official P5 REST API](https://www.archiware.com/blog/redoc/p5_rest_api/awp5api.html)
- [Official P5 CLI manual](https://support.archiware.com/downloads/cli.pdf)
- [Archiware manuals hub](https://www.archiware.com/manuals/)
- [Command pack format](COMMAND_PACK_FORMAT.md)
- [Command catalog](COMMAND_CATALOG.md)
- [QA checklist](QA_CHECKLIST.md)

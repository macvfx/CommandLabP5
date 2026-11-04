# Command Catalog and Import Candidates

This catalog separates commands available now from candidates that still need
documentation or live-version validation. All identifiers below are fictional.

## Included read-only comparison pack

| Question | REST | nsdchat | Status |
| --- | --- | --- | --- |
| Which clients exist? | `GET general/clients` | `Client names` | Included |
| What are this volume's details? | `GET general/volumes/{volume}` | `Volume {volume} mode`, `location`, `isonline` | Included; closest comparison |
| Which jobs used this volume? | `GET general/volumes/{volume}/jobs` | `Volume {volume} jobs` | Included |
| What is this job's status? | `GET general/jobs/{job}` | `Job {job} status` | Included |
| What did this job report? | `GET general/jobs/{job}/report` | `Job {job} report` | Included |
| Which volumes are in a jukebox? | Built-in `GET general/jukeboxes/{jukebox}/volumes` | `Jukebox {jukebox} volumes` | CLI added to pack |
| Is this archive handle available? | Built-in ArchiveEntry lookup/read | `ArchiveEntry {handle} status` | CLI added to pack |

The candidates came from the existing P5 app and shell-script patterns in this
workspace, then were mapped to the public P5Kit examples, official REST
reference, or CLI manual. Import metadata links to those public references; it
does not expose local source paths.

## Next read-only candidates

Evaluate these against the applicable P5 manual and at least one disposable or
approved server before adding them to the example pack:

- REST job protocol and CLI `Job {job} protocol`;
- REST pools and pool volume details;
- REST and CLI licence-resource availability;
- archive index, plan, and entry detail comparisons;
- volume usage, error counters, and media-health fields;
- job-list filters such as recent, running, failed, or module-specific jobs;
- jukebox, drive, slot, and loaded-media state; and
- exact ArchiveEntry size, birth time, and volume reads.

## Deferred mutating candidates

These are documentation candidates only and are not accepted by schema version
1:

- change one exact volume from its observed current mode to `Readonly`;
- return a volume to an explicitly selected prior mode;
- change an ArchiveEntry comment or supported metadata;
- add entries to a restore selection; and
- start inventory, label, archive, restore, or other jobs.

For the requested volume example, the safe sequence is: read the exact volume,
show its current mode, require the operator to select the exact target and
`Readonly` value, preview the full command, confirm once, submit once, retain a
receipt, and read the volume again. The CLI and REST write forms must be checked
against the installed P5 version before implementation.

## References

- [P5Kit API examples](https://github.com/macvfx/P5Kit-Docs/blob/main/P5_API_EXAMPLES.md)
- [Official P5 REST API](https://www.archiware.com/blog/redoc/p5_rest_api/awp5api.html)
- [Official P5 CLI manual](https://support.archiware.com/downloads/cli.pdf)
- [Archiware manuals hub](https://www.archiware.com/manuals/)


# P5 Command Lab Command Pack Format

P5 Command Lab 0.5.1 imports versioned JSON command packs. JSON is the
executable interchange format; Markdown remains the review and documentation
format. A pack is copied into the current user's app preferences after it
passes validation. Re-importing the same `id` replaces the earlier pack.

## Safety boundary

Schema version 1 is intentionally read-only:

- every recipe must declare `"effect": "read-only"`;
- REST recipes must use `GET`;
- `Authorization`, `Host`, and `Cookie` headers are reserved and rejected;
- REST templates must be relative paths without `..`;
- every placeholder must have one corresponding field; and
- pack ids and recipe UUIDs must be stable and unique.

The importer rejects `mutating`, `starts-job`, and `unknown` effects even if the
command text looks harmless. This prevents a pack author from bypassing the
execution warning merely by omitting safety metadata.

## Top-level object

| Field | Type | Meaning |
| --- | --- | --- |
| `schemaVersion` | integer | Must be `1`. |
| `id` | string | Stable reverse-DNS-style pack identifier. |
| `title` | string | Picker section and operator-facing name. |
| `version` | string | Pack version, independent of the app version. |
| `summary` | string | Brief scope statement. |
| `sources` | array | Reference objects with `title` and HTTP(S) `url`. |
| `recipes` | array | Commands described below. |

## Recipe object

Required fields are `id`, `name`, `summary`, `transport`, `method`, `template`,
`headerTemplates`, `fields`, `isBuiltIn`, and `effect`.

- `id` is a stable UUID.
- `transport` is `REST API` or `nsdchat CLI`.
- `template` is a relative REST resource or the arguments after `nsdchat -c`.
- `fields` contains `key`, `label`, `placeholder`, and `defaultValue`.
- `comparisonID` connects REST and CLI recipes that answer the same question.
- `category`, `sourceTitle`, `sourceURL`, `sourceReference`, and
  `minimumP5Version` are optional review metadata.
- `isBuiltIn` must be `false`; the importer enforces that value in memory.

Example:

```json
{
  "id": "61EED142-44B8-4E0A-A216-51E76FE81903",
  "name": "Volume details — REST",
  "summary": "Reads details for one volume.",
  "transport": "REST API",
  "method": "GET",
  "template": "general/volumes/{volume}",
  "headerTemplates": {},
  "fields": [
    {
      "key": "volume",
      "label": "Volume ID",
      "placeholder": "TEST-VOLUME",
      "defaultValue": ""
    }
  ],
  "isBuiltIn": false,
  "effect": "read-only",
  "comparisonID": "volume-details"
}
```

The complete importable example is
[`P5-Read-Only-Comparisons.json`](../CommandPacks/P5-Read-Only-Comparisons.json).

## Planned write-command extension

Write commands need a later schema and a separate execution path. The design
must include an explicit effect, a before-state read, exact target identity,
old and new values, an operator confirmation, and a durable receipt. A future
example such as `Volume {volume} mode Readonly` must never share the current
one-click read-only execution path.

The candidate operations, proposed future effect classes, proof states,
exclusions, and required test order are specified in the
[Write Command Pack Test and Verification Plan](WRITE_COMMAND_PACK_PLAN.md).
That plan is documentation only; it does not extend schema version 1.


# Reviewed waivers

[Return to the module documentation index](README.md).

Each waiver must contain the tool, rule, affected object, technical justification,
owner, reviewer, creation date and expiration or removal condition.

## Verilator waiver procedure

Open-source lint waivers are stored in `flows/verilator_lint/waivers.vlt`. Scope every
waiver to a specific warning rule and, whenever possible, a file plus a line range
or message match. Repository-wide rule suppression is not accepted.

Generate candidate entries with:

```sh
make open-waiver-draft
```

This creates `reports/verilator_lint/suggested_waivers.vlt`. A generated waiver is
only a starting point. Review the warning, attempt to correct the RTL, and copy an
entry into the committed waiver file only when the behavior is intentional.

Record each accepted waiver below using this format:

```text
ID:
Tool and rule:
Affected file and object:
Technical justification:
Evidence:
Owner:
Reviewer:
Created:
Expires or removal condition:
```

## Accepted waivers

None.

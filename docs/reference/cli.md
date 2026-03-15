# CLI Reference

## Core

- `vessel init <user@host>`
- `vessel deploy [--no-push]`
- `vessel push <image> <user@host>`
- `vessel logs <service>`
- `vessel rollback [revision]`

## Diagnostics

- `vessel doctor`
- `vessel diff`
- `vessel repair`

## Local State Format

Vessel stores local runtime state in `.vessel/state.json` (versioned JSON schema). This is now the only supported on-disk state format.


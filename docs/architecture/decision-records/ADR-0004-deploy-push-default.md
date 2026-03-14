# ADR-0004: Deploy/Push Relationship

## Status
Accepted

## Decision

`vessel deploy` performs push-if-needed by default.

Flags:

- `--no-push`
- `--push-only`

`vessel push` remains a standalone command for CI prewarming and explicit workflows.


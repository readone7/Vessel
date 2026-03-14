# ADR-0001: CLI-to-Node Transport Model

## Status
Accepted

## Decision

Use SSH-tunneled localhost HTTP+JSON as the default transport between `vessel` and `vesseld` for Phase 1.

Phase 3+ prefers direct WireGuard connectivity with SSH fallback.

## Rationale

- Works before cluster mesh exists
- Matches single-node MVP constraints
- Keeps daemon API-first architecture


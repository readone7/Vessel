# ADR-0002: Deploy Health Gate Precedence

## Status
Accepted

## Decision

Health-gate precedence:

1. Docker `HEALTHCHECK`
2. HTTP readiness probe in `vessel.toml`
3. TCP probe
4. Stability-window fallback

## Consequences

- Rolling deployment and rollback share one health policy.
- Compose subset and Vessel config must expose health settings clearly.


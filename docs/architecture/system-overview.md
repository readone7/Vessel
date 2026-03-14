# System Overview

## Components

- `vessel` CLI
- `vesseld` daemon on each node
- `vegistry` helper for direct image transfer
- Caddy ingress service
- Optional hosted control service (Elixir/Phoenix)

## Transport

- SSH-tunneled API in Phase 1
- WireGuard direct transport in Phase 3+

## Health gates

1. Docker `HEALTHCHECK`
2. HTTP readiness probe
3. TCP probe
4. Stability window fallback


# API Reference (Scaffold)

`vesseld` exposes a versioned node control API over:

- Phase 1: SSH-tunneled localhost HTTP+JSON
- Phase 3+: direct WireGuard path with SSH fallback

Primary resource groups:

- `/v1/bootstrap`
- `/v1/deployments`
- `/v1/health`
- `/v1/ingress`
- `/v1/events`


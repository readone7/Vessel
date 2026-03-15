# Vessel

Vessel is a lightweight, CLI-first platform for shipping containerized apps to remote and local machines without Kubernetes overhead.

## Binaries

- `vessel`: operator CLI
- `vesseld`: node daemon (API endpoint)
- `vegistry`: image transfer registry helper

## Quick start (scaffold)

```bash
zig build
zig build run -- help
zig build run -- init user@host
zig build run -- deploy
```

## Command model

- `vessel init`: bootstrap remote machine and start `vesseld`
- `vessel deploy`: deploy using compose + vessel config; push-if-needed by default
- `vessel push`: explicit image distribution command
- `vessel doctor`, `vessel diff`, `vessel repair`: drift and diagnostics workflow

## Project config

- `compose.yaml`: app/service definitions
- `vessel.toml`: target host, project identity, domain, deploy policy flags


# ADR-0003: Zig Dependency Spike Outcomes

## Status
Proposed

## Scope

- YAML parsing candidates: `zig-yaml`, `ymlz`
- gRPC candidate: `gRPC-zig`
- Docker API over unix socket
- SSH shell-out transport
- WireGuard userland tooling integration

## Decision Framework

Adopt only if candidate passes:

- correctness on representative workload
- operational reliability
- maintainability and ecosystem health

Otherwise prefer simple shell-out or internal implementation.


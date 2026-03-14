# ADR-0005: Secrets Lifecycle MVP

## Status
Accepted

## Decision

Phase 1 uses a single-node sealed secret store with local key material.

Phase 4+ introduces multi-node key hierarchy for shared secret decryption.

## Delivery

- metadata references in replicated state
- no plaintext replication of secret values
- runtime materialization as env/tmpfs only


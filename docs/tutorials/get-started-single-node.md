# Get Started: Single Node Deploy

## Goal

Deploy a single service to one machine in under 10 minutes.

## Steps

1. Create `vessel.toml` with `target_host`, `domain`, and `image`.
2. Ensure `compose.yaml` exists.
3. Run `vessel init user@host`.
4. Run `vessel deploy`.
5. Verify with `vessel doctor` and `vessel logs <service>`.


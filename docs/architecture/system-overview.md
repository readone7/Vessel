# System Overview

Vessel is a CLI-first, decentralised orchestrator for Docker hosts. It ships
containerised apps to remote machines over SSH without requiring a central
control plane or Kubernetes.

## High-level architecture

```mermaid
flowchart TB
  subgraph dev ["Developer Machine"]
    cli["vessel CLI"]
    dcli["Docker CLI"]
    compose["compose.yaml"]
    toml["vessel.toml"]
  end

  subgraph cluster ["Vessel Cluster"]
    subgraph nodeA ["Machine A"]
      daemonA["vesseld"]
      caddyA["Caddy Ingress"]
      stateA[("State Replica")]
      containersA["App Containers"]
    end

    subgraph nodeB ["Machine B"]
      daemonB["vesseld"]
      caddyB["Caddy Ingress"]
      stateB[("State Replica")]
      containersB["App Containers"]
    end

    subgraph nodeC ["Machine C"]
      daemonC["vesseld"]
      stateC[("State Replica")]
      containersC["App Containers"]
    end

    dns["Cluster DNS"]
    wg["WireGuard Mesh"]
  end

  subgraph hosted ["Hosted Service (optional)"]
    api["Control API\n(Elixir/Phoenix)"]
    dashboard["Web Dashboard"]
    eventstore["Event Store"]
  end

  cli -- "SSH tunnel / WireGuard" --> daemonA
  cli -- "vessel push" --> dcli
  dcli -- "docker push via\nSSH tunnel" --> daemonA

  daemonA <-- "peer state\nreplication" --> daemonB
  daemonB <-- "peer state\nreplication" --> daemonC
  daemonA <-- "peer state\nreplication" --> daemonC

  daemonA --- stateA
  daemonB --- stateB
  daemonC --- stateC

  daemonA --> containersA
  daemonB --> containersB
  daemonC --> containersC

  daemonA --> caddyA
  daemonB --> caddyB

  containersA -. "service discovery" .-> dns
  containersB -. "service discovery" .-> dns
  containersC -. "service discovery" .-> dns

  containersA <-. "overlay network" .-> wg
  containersB <-. "overlay network" .-> wg
  containersC <-. "overlay network" .-> wg

  cli -- "device auth" --> api
  api --> dashboard
  api --> eventstore
  api -- "federated ops" --> daemonA
```

## Components

- **`vessel`** — operator CLI
- **`vesseld`** — per-node daemon (API endpoint)
- **`vegistry`** — image transfer registry helper
- **Caddy** — ingress service (TLS + L7 routing)
- **Cluster DNS** — service name resolution across nodes
- **WireGuard Mesh** — encrypted container-to-container overlay network
- **Hosted control service** — optional Elixir/Phoenix dashboard and event store

## Component overview

| Component | Binary | Role |
|-----------|--------|------|
| Vessel CLI | `vessel` | Operator interface. Parses compose/config, issues commands over SSH tunnel. |
| Machine Agent | `vesseld` | Per-node daemon. Exposes versioned HTTP+JSON API, manages containers via Docker Engine API. |
| Vegistry | `vegistry` | Ephemeral registry started on-demand during `vessel push` to receive image layers over an SSH tunnel. |
| Caddy Ingress | (Docker service) | L7 reverse proxy managed by `vesseld`. Handles TLS provisioning via Let's Encrypt. |
| Cluster DNS | (embedded in `vesseld`) | Resolves service names to container IPs for cross-machine communication. |
| WireGuard Mesh | (kernel + userland) | Encrypted overlay giving every container a unique routable IP across nodes. |
| Hosted Service | Elixir app | Optional dashboard, event store, and remote operations gateway. |

## Transport model

```mermaid
flowchart LR
  subgraph phase1 ["Phase 1 — Single node"]
    cli1["vessel CLI"] -- "ssh -L tunnel" --> sshd["sshd"]
    sshd --> api1["vesseld HTTP API\n(127.0.0.1:4317)"]
  end

  subgraph phase3 ["Phase 3+ — Multi-node"]
    cli2["vessel CLI"] -- "WireGuard direct" --> api2["vesseld HTTP API\n(mesh IP:4317)"]
    cli2 -. "SSH fallback" .-> sshd2["sshd"] --> api2
  end
```

- **Phase 1**: CLI opens an SSH local-port-forward to `vesseld`'s localhost
  listener, then issues HTTP+JSON API calls through the tunnel.
- **Phase 3+**: CLI connects directly over the WireGuard mesh. SSH tunnel
  remains as a fallback when the mesh is unreachable.

## Deploy flow

```mermaid
sequenceDiagram
  actor Dev as Developer
  participant CLI as vessel CLI
  participant Docker as Docker CLI
  participant Node as vesseld
  participant Veg as vegistry (ephemeral)
  participant Caddy as Caddy Ingress

  Dev ->> CLI: vessel deploy
  CLI ->> Node: Open SSH tunnel, validate cluster
  CLI ->> Docker: Push image if needed

  Docker ->> Node: Open SSH tunnel
  Docker ->> Veg: Start temporary vegistry
  Docker ->> Veg: Push missing layers
  Veg -->> Node: Image available in Docker daemon
  Docker ->> Node: Stop vegistry, close tunnel

  CLI ->> Node: Submit deployment plan
  Node ->> Node: Schedule tasks, start containers
  Node ->> Node: Health-gate checks (HEALTHCHECK → HTTP → TCP → uptime)
  Node ->> Caddy: Push route config via Admin API
  Caddy -->> Node: TLS cert provisioned
  Node -->> CLI: Rollout status
  CLI -->> Dev: Deploy complete
```

## Image transfer (vegistry)

```mermaid
flowchart LR
  A["vessel push myapp:v1 user@host"] --> B["Open SSH tunnel\n(local:random → remote:5000)"]
  B --> C["Start vegistry container\non remote (port 5000)"]
  C --> D["docker push myapp:v1\nlocalhost:random"]
  D --> E["Only missing layers\ntransferred"]
  E --> F["Image available in\nremote Docker daemon"]
  F --> G["Stop vegistry,\nclose tunnel"]
```

Vegistry implements a minimal Docker Registry V2 subset. It reads and writes
directly to the remote Docker daemon's image store, avoiding any intermediate
blob storage. Fallback: `docker save | ssh | docker load` when the registry
path fails.

## Health gate precedence

During rolling deploys and rollbacks, Vessel checks container health using the
first available signal in this order:

```mermaid
flowchart LR
  A["Docker HEALTHCHECK\n(if defined)"] --> B["HTTP readiness probe\n(vessel.toml)"]
  B --> C["TCP port open"]
  C --> D["Stability window\n(container uptime)"]
```

On repeated failures, the deploy engine retries up to a bounded limit, then
triggers automatic rollback to the previous revision.

## State replication (Phase 4+)

```mermaid
flowchart TB
  subgraph replication ["Peer-to-peer state replication"]
    sA[("Node A\nState")] <--> sB[("Node B\nState")]
    sB <--> sC[("Node C\nState")]
    sA <--> sC
  end

  subgraph objects ["Replicated objects"]
    direction LR
    specs["Service specs"]
    ops["Deploy operations"]
    placement["Placement decisions"]
    inventory["Machine inventory"]
    net["Network allocations"]
    routes["Ingress routes"]
    certs["Cert metadata"]
    secrets["Secret references"]
  end

  replication --- objects
```

Each node holds a full copy of the cluster state. Mutations use an
operation-log with deterministic conflict resolution (operation IDs, monotonic
timestamps, actor IDs). Secret *values* are never stored in plaintext in the
replicated state — only references.

## Drift management

```mermaid
flowchart LR
  diff["vessel diff\n(desired vs actual)"] --> doctor["vessel doctor\n(layered diagnostics)"]
  doctor --> repair["vessel repair\n(guided remediation)"]
  repair --> healthy["Cluster healthy"]
```

Reconciliation is explicit and operator-invoked. Vessel does not auto-reconcile
in the background. The drift tooling (`diff`, `doctor`, `repair`) gives
operators full visibility and control over corrections.

## Project config model

```
my-app/
├── compose.yaml      # Service definitions (image, ports, volumes, env)
├── vessel.toml       # Deploy targets, domains, env profiles, policy flags
└── ...
```

- **`compose.yaml`**: application and service source of truth.
- **`vessel.toml`**: Vessel-specific deployment metadata — target hosts,
  domains, environment profiles, deploy policy toggles.
- Default project name derives from directory name, overrideable in
  `vessel.toml`. Deployment identity is cluster-scoped: `<project>/<environment>`.


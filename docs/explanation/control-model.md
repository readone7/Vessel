# Control Model

Vessel combines declarative desired state with imperative mutation commands.

- Operators issue explicit commands (`deploy`, `rollback`, `scale`).
- Drift is not auto-reconciled in the background.
- Drift detection and remediation use explicit commands:
  - `vessel diff`
  - `vessel doctor`
  - `vessel repair`


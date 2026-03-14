# How To Roll Back a Deployment

1. Inspect deployment history.
2. Pick a revision or use the previous revision by default.
3. Run `vessel rollback [revision]`.
4. Monitor health gates and traffic cutover.

Rollback reuses the rolling deployment engine and health checks.


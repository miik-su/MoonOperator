# Principles

Preserve unknown fields and server defaults. Treat RV as opaque. Publish complete
LIST snapshots. Checkpoint only delivered events. Bound pending work. Preserve
dirty events arriving during reconciliation. Make desired-state operations
idempotent. Use an injectable transport. Distinguish tests from future claims.

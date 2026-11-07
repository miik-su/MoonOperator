# Security model

HTTPS verification is required, except an explicitly enabled loopback developer
proxy. Private credential fields have no Debug/Show implementation; projected
token files are reread per request. API errors use HTTP codes and fixed reasons,
not arbitrary server messages. Request bodies and tokens are never logged.

Body/event byte limits, JSON nesting limits, deadlines and cache/queue bounds
prevent unbounded ordinary accumulation. Explicit RBAC declarations reject
wildcards. Ownership rejects a second controlling UID. Diagnostics contain only
queue/cache gauges and should remain on the trusted operator network.
This is a single-replica framework, not a multitenant isolation boundary.

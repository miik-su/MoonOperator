# Bounded diagnostics

Metrics use fixed names and fixed buckets. No namespace, resource name, UID,
token or arbitrary exception text becomes a label. Existing `_duration_seconds`
sum/count series are retained for compatibility. New `api_latency_seconds` and
`reconcile_latency_seconds` histograms use 1/5/10/50/100/500/1000/5000 ms bounds
plus +Inf, with cumulative buckets suitable for Prometheus histogram queries.
They do not expose exact quantiles or retain per-request samples.

API latency measures Config::send including configured throttling, connection
and bounded response reading. Reconcile latency measures one callback attempt,
including cooperative timeout handling; it excludes time waiting in the queue
and delayed retry. Neither is total workload startup/Pod Ready latency.

Thrown reconcile failures have bounded additional counters: conflict (409),
retryable API, permanent API, invalid/capacity, timeout, explicitly typed
transport, and other exceptions. They supplement `reconcile_failure_total`.
An explicit Retry outcome increments queue_retry but is not itself a thrown
exception. Terminal outcomes do not create automatic retry timers; a fresh
event can still schedule the key.

`/healthz` means the diagnostics process is answering; `/readyz` requires cache
sync and the configured watch-disconnection threshold. They do not prove Pod
readiness, API availability for every request or end-to-end reconciliation.
Diagnostics have no built-in authentication. Keep local loopback or use the
provided NetworkPolicy with an enforcing CNI; use an authenticated trusted
proxy when crossing that boundary. See security-model.md and compatibility.md.

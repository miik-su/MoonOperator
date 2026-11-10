# Reproducible bounded observations

See [the results dashboard](test-results.md) for readable tables, input models,
source revisions and permanent raw snapshots. New CI runs publish their own
summaries and downloadable observations; historical snapshots are not overwritten.

Run `moon run benchmarks/runtime --target native --release`. The JSON report
records compiler, target, runtime platform, dataset size (1,000 objects), worker
count and per-operation iteration counts. It measures resource serialization,
JSON parsing, cache reads/label queries, watch decode, queue throughput and
idempotent fake-client MoonApp reconciliation. Checksums keep work observable.
Times are microseconds from the installed core bench monotonic clock. These are
single-process observations, not a production throughput or latency guarantee.
The fake reconcile timing includes no network or API-server admission.

Run `moon run tests/soak --target native --release` for a 10-second focused load
probe, or explicitly set `MOONOPERATOR_SOAK_SECONDS` in 1..3600 for longer runs.
It repeatedly updates 1,000 objects, injects failures and duplicates, checks
queue capacity and drains on shutdown. A short run cannot establish long-term
stability. No RSS measurement or leak-freedom claim is made.

Recorded Windows observations are kept under `docs/evidence/`; machine CPU
metadata may be unavailable in the process environment and is labeled accordingly.

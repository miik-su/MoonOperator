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
probe, or explicitly set `MOONOPERATOR_SOAK_SECONDS` in 1..86400 for longer runs.
It repeatedly updates 1,000 objects, injects failures and duplicates, checks
queue capacity and drains on shutdown. A short run cannot establish long-term
stability. Linux reports process RSS/peak RSS initially, every minute and at the
end, with a bounded progress report; unsupported platforms label RSS unavailable.
No leak-freedom claim is made. The manual release-validation workflow offers
60-second or one-hour runs; 24 hours requires a suitable local runner. Neither
one-hour nor 24-hour execution has been completed in this review.

Separate fresh-container 128/256/512 MiB observations are retained in
[the Linux snapshot](evidence/20261113-linux/README.md). They measure short
snapshot replacement profiles, not elapsed-hours stability.

Recorded Windows observations are kept under `docs/evidence/`; machine CPU
metadata may be unavailable in the process environment and is labeled accordingly.

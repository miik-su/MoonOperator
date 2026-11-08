# Focused verification

No full suite was run. Each feature was tested using its package or one file:
resource ownership, path encoding, authentication validation, loopback HTTP,
byte-split Watch/410, atomic cache replacement, queue dedup/delay, worker failure
release, manager registration, lifecycle helpers, schema/RBAC, fake conflicts,
MoonApp idempotence and drift repair. `moon check --target native`, `moon fmt`
and `moon info --target native` check types/format/interfaces without full tests.

Real-cluster release gate: on disposable Kind follow README, then verify
MoonApp create/update/delete, owned child GC, child drift, restart, API outage,
expired watch and 403 reporting. Check /readyz before/after initial LIST. Run
under the generated Role rather than cluster-admin. Fake tests do not prove
server admission or GC behavior. The implemented `scripts/kind-e2e.mbtx` has
passed the MoonApp lifecycle under a dedicated ServiceAccount. The additional
cluster Client probe exercises actual CRUD, merge PATCH, paginated snapshots,
optimistic conflicts, forbidden namespace access and watch delivery. It passed
in run 42445725470 after the real-server TypeMeta compatibility fix. Exact links
and revisions are retained in release-status.md.

New targeted regressions cover omitted LIST TypeMeta, Retry-After, non-JSON proxy
failures, oversized responses, peer closure on cancellation, four-worker key
exclusion/draining, YAML configuration, finalizer failures, safe logs and schema
versions. Experimental WASM execution is a separate opt-in probe. Fixed dataset
benchmarks and a 10-second bounded fault load report are recorded in evidence/;
no hours-long soak or RSS result is claimed.

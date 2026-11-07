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
server admission or GC behavior. Long-duration soak and benchmark data are pending.

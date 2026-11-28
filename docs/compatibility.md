# Compatibility and evidence

This matrix separates implemented behavior from dated execution evidence.
New local maintenance regressions are listed in maintenance.md. CI links in
release-status.md identify their exact source; historical data is not rewritten.

| Capability | Status / evidence |
|---|---|
| Dynamic resources, typed views, unknown fields, opaque RV | Verified: core/resource_test.mbt and typed_test.mbt |
| CRUD/status client | Implemented; fake CRUD/conflict tests |
| PATCH / multi-page LIST against real API | Verified in Kind Client probe, including omitted item TypeMeta and conflicts |
| HTTP | Verified against real loopback socket, including bearer header |
| HTTPS/custom CA/token rotation | Real Kind CA/token; loopback rotation after simulated 401; Linux unrelated-CA and wrong-hostname rejection passed; real JWT expiry remains untested |
| JSON/YAML kubeconfig / in-cluster | Bounded bearer/CA subset; relative paths and duplicate/alias rejection tested |
| Watch byte framing / 410 state | Verified: split UTF-8/event tests |
| Informer reconnect / relist runtime | Scope and bookmark checks with synthetic fixtures; injected 410/403 and startup backpressure; real MoonApp restart recovery |
| Cache | Verified atomic replacement, bounds, snapshots; label equality maps |
| Workqueue | Verified dirty/in-flight dedup and delayed retries |
| Controller / Manager | Verified failure release, retry scheduling from reconcile completion, concurrent-key exclusion, shutdown drain and registration. [Retry regression and CI](evidence/20261126-mooncakes/README.md) |
| Finalizers / owners / conditions / predicates | Cleanup failure retains finalizer; status-only filtering retains deletion transitions |
| CRD / RBAC | Multiple served versions with equal schemas, exactly one served storage version, defaults/bounds, validated CRD names/root schema/version identifiers and explicit RBAC |
| MoonApp | Fake and real Kind verified: create/update, idempotence, drift repair, restart and GC |
| Health / metrics / logs | Cache/known-disconnect readiness, gauges, fixed error counters, duration sum/count and bounded histograms; safe structured events |
| Windows native | Checked and built locally |
| Linux | Native and WASM CI passed; see release-status.md for exact revisions |
| Kubernetes / Kind | Kubernetes 1.35.8, 1.36.4 and 1.37.0 on amd64 with Calico 3.33.0 passed MoonApp lifecycle, authenticated client, RBAC, ownership admission and policy checks. [Evidence](evidence/20261128-kind-compatibility/README.md) |
| Experimental WASM host | Current pin is Wasmtime 50.0.3. Dated guest and failure-path verification is linked from release-status.md |
| HA / webhooks | Not implemented; single replica deployment contract |
| Benchmarks / load | Fixed dataset and 10s fault probe; Linux short container RSS matrix recorded; one-hour/24-hour soak still pending |
| Source archive / publication | Offline source ZIP and notice byte checks passed. Use the [Mooncakes module page](https://mooncakes.io/docs/miik-su/moonoperator) for available registry versions |
| Follow-up security review | Redacted Resource debug, explicit finalizer results, scoped ownership/adoption, mandatory watch RVs, typed capacity failure policy, bounded file/LIST reads and API type validation verified by focused regressions |
| Container delivery | Linux amd64 v0.1.2 public assets verified and the image rebuilt and deployed to Kind 1.37.0. The [release record](evidence/20261125-v0.1.2/README.md) identifies the exact artifact and scan coverage. The [November 21 OS scan](evidence/20261121-container/README.md) applies to an earlier, different image |
| Diagnostics ingress | Loopback default. Pod interface acceptance verified Calico 3.33.0 allow/deny/recovery on Kubernetes 1.35.8, 1.36.4 and 1.37.0. Other CNIs are unverified |
| Independent library consumer | Public API example passed from the checkout and from an independent module installed from Mooncakes 0.1.3. [Registry install and run](evidence/20261128-mooncakes/README.md) |
| macOS / other Kubernetes versions | Not verified; compilation or interface similarity is not runtime compatibility evidence |

Optional-adoption acceptance passed for final code source 31d7390 with explicit
OwnerReferencesPermissionEnforcement: default refusal, 403 without dependent
delete permission and success with fixture-named grants. The normal example
Role was not broadened. See [same-source final evidence](evidence/20261113-linux/31d7390/README.md).
Full regression is manual-only and unrun.
The later namespace-migration source 3572f1b also passed native/Kind/WASM; see
release-status.md. Maintenance source `6235a5f` passed native, Kind and WASM.
Its [reports](evidence/20261118-maintenance/README.md) identify the tested
Kubernetes and Calico versions, source revision and environment.

Single cooperative event loop only, not OS-thread-safe sharing. Use separate
Store instances for independently watched namespaces of the same GVK: replace
publishes one whole GVK snapshot. Default cache/queue capacity is 10,000 objects.
Cache and LIST snapshots default to 64 MiB encoded bytes and 1 MiB per object.
Restart recovery starts from LIST; queue state is not persisted. Retry-After on
429/503 delays the next Client request; writes are not implicitly replayed.
Schema is a bounded OpenAPI subset, not a complete OpenAPI validator. CRD generator
supports multiple served versions with exactly one storage version, without a
conversion webhook. Fake merge PATCH is tested; admission, garbage collection
and complete selector behavior require the real server.

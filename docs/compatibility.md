# Compatibility and evidence — 2026-11-13

| Capability | Status / evidence |
|---|---|
| Dynamic resources, typed views, unknown fields, opaque RV | Verified: core/resource_test.mbt and typed_test.mbt |
| CRUD/status client | Implemented; fake CRUD/conflict tests |
| PATCH / multi-page LIST against real API | Verified in Kind Client probe, including omitted item TypeMeta and conflicts |
| HTTP | Verified against real loopback socket, including bearer header |
| HTTPS/custom CA/token rotation | Real Kind CA/token; loopback rotation after simulated 401; Linux unrelated-CA and wrong-hostname rejection passed; real JWT expiry remains untested |
| JSON/YAML kubeconfig / in-cluster | Bounded bearer/CA subset; relative paths and duplicate/alias rejection tested |
| Watch byte framing / 410 state | Verified: split UTF-8/event tests |
| Informer reconnect / relist runtime | Injected 410/403 and startup backpressure tests; real MoonApp restart recovery |
| Cache | Verified atomic replacement, bounds, snapshots; label equality maps |
| Workqueue | Verified dirty/in-flight dedup and delayed retries |
| Controller / Manager | Verified failure release, concurrent-key exclusion, shutdown drain, registration |
| Finalizers / owners / conditions / predicates | Cleanup failure retains finalizer; status-only filtering retains deletion transitions |
| CRD / RBAC | Multiple served schemas, exactly one storage version, defaults/bounds, least privilege |
| MoonApp | Fake and real Kind verified: create/update, idempotence, drift repair, restart and GC |
| Health / metrics / logs | Cache readiness, gauges, counters, duration sum/count, safe structured events |
| Windows native | Checked and built locally |
| Linux | Native and WASM CI passed; see release-status.md for exact revisions |
| Kubernetes / Kind | MoonApp lifecycle and narrow-ServiceAccount Client probe passed in GitHub runner |
| Experimental WASM host | Real MoonBit guest on Wasmtime 50.0.1; trap/fuel/memory/capability/ABI/deadline probes passed |
| HA / webhooks | Not implemented; single replica deployment contract |
| Benchmarks / load | Fixed dataset and 10s fault probe; Linux short container RSS matrix recorded; one-hour/24-hour soak still pending |
| Package publication | Offline `moon package` succeeds; Mooncakes publication pending |
| Follow-up security review | Redacted Resource debug, explicit finalizer results, scoped ownership/adoption, mandatory watch RVs, typed capacity failure policy, bounded file/LIST reads and API type validation verified by focused regressions |
| Container delivery | Release production image excludes probes; separate acceptance image; pinned Ubuntu digest/archive snapshot and recorded package inventory verified in Kind CI |
| Diagnostics ingress | Loopback default; explicit cluster interface; actual Calico 3.33.0 allow/deny/recovery passed on Kubernetes 1.37.0; other CNIs unverified |

The latest optional-adoption acceptance is not yet passing. See
[current follow-up](review-followup-20261113.md) rather than inferring a pass
from historical lifecycle acceptance. Full regression is manual-only and unrun.

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

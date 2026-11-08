# Compatibility and evidence — 2026-11-08

| Capability | Status / evidence |
|---|---|
| Dynamic resources, typed views, unknown fields, opaque RV | Verified: core/resource_test.mbt and typed_test.mbt |
| CRUD/status client | Implemented; fake CRUD/conflict tests |
| PATCH / multi-page LIST against real API | Verified in Kind Client probe, including omitted item TypeMeta and conflicts |
| HTTP | Verified against real loopback socket, including bearer header |
| HTTPS/custom CA/token rotation | ServiceAccount CA/token verified in Kind; rotation rereads files, not separately fault-tested |
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
| Benchmarks / load | Fixed dataset report and 10s fault load probe recorded; long soak/RSS still pending |
| Package publication | Offline `moon package` succeeds; Mooncakes publication pending |

Single cooperative event loop only, not OS-thread-safe sharing. Use separate
Store instances for independently watched namespaces of the same GVK: replace
publishes one whole GVK snapshot. Default cache/queue capacity is 10,000 objects.
Restart recovery starts from LIST; queue state is not persisted. Retry-After on
429/503 delays the next Client request; writes are not implicitly replayed.
Schema is a bounded OpenAPI subset, not a complete OpenAPI validator. CRD generator
supports multiple served versions with exactly one storage version, without a
conversion webhook. Fake merge PATCH is tested; admission, garbage collection
and complete selector behavior require the real server.

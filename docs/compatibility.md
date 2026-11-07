# Compatibility and evidence — 2026-11-07

| Capability | Status / evidence |
|---|---|
| Dynamic resources, unknown fields, opaque RV | Verified: core/resource_test.mbt |
| CRUD/status client | Implemented; fake CRUD/conflict tests |
| PATCH / multi-page LIST against real API | Implemented, unverified against cluster |
| HTTP | Verified against real loopback socket, including bearer header |
| HTTPS/custom CA/token rotation | Implemented via async; cluster unverified |
| JSON kubeconfig / in-cluster | Partial: bearer credentials and CA paths |
| Watch byte framing / 410 state | Verified: split UTF-8/event tests |
| Informer reconnect / relist runtime | Type checked; real cluster unverified |
| Cache | Verified atomic replacement, bounds, snapshots; label equality maps |
| Workqueue | Verified dirty/in-flight dedup and delayed retries |
| Controller / Manager | Verified failure release and duplicate registration |
| Finalizers / owners / conditions | Implemented; finalizer/condition tests |
| CRD / RBAC | Verified schema defaults/bounds and wildcard rejection |
| MoonApp | Fake verified: create, idempotence and child drift repair |
| Health and metrics | Readiness and queue/cache gauges; no histograms yet |
| Windows native | Checked and built locally |
| Linux | CI workflow provided; inspect Actions for results |
| Kubernetes / Kind | Untested locally: kubectl, Docker and Kind unavailable |
| HA / webhooks / third-party WASM host | Not implemented |
| Long-duration benchmarks / Mooncakes publication | Pending release gates |

Single cooperative event loop only, not OS-thread-safe sharing. Use separate
Store instances for independently watched namespaces of the same GVK: replace
publishes one whole GVK snapshot. Default cache/queue capacity is 10,000 objects.
Restart recovery starts from LIST; queue state is not persisted. Transport reads
Retry-After but queue retry currently uses capped exponential backoff.
Schema is a bounded OpenAPI subset, not a complete OpenAPI validator. CRD generator
currently describes one served/storage version. Fake API does not simulate
admission, garbage collection, PATCH or full selector semantics.

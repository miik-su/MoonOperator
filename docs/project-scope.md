# Scope

MoonOperator is an experimental MoonBit dynamic-resource Operator framework.
Core coordination is MoonBit; async HTTP/TLS and YAML reuse the MoonBit ecosystem.
This scope is a capability contract, not a claim of production certification.

| Area | Implemented subset | Explicit exclusion / deployment contract |
| --- | --- | --- |
| Resource/client | Dynamic JSON/typed views, CRUD/status, merge PATCH, bounded consistent LIST | No generated complete SDK or automatic discovery; trusted ResourceType declarations |
| Authentication | Verified HTTPS with system/custom CA, bearer/tokenFile, restricted JSON/YAML kubeconfig, in-cluster SA | No exec, OIDC refresh, client certificates, embedded CA or insecure-skip-TLS |
| Recovery/cache | Scope-checked LIST/WATCH, 410 recovery, atomic bounded snapshots, UID-safe tombstones | Collection checks constrain admission; Kubernetes RBAC authorizes requests. Independent watches of one GVK require separate Stores. No durable queue/cache or streaming initial events |
| Workers | Cooperative concurrency, dedup, backoff, deadlines, finalizers/owners | One replica; no Lease election, OS-thread-safe sharing or forced cancellation of arbitrary blocking code |
| CRD/RBAC | Bounded schema subset, equal-schema served versions, explicit namespaced rules | No full OpenAPI validator, admission/conversion webhook or inferred production permissions |
| MoonApp | Desired Deployment/Service, idempotence/drift, generation-aware conditions | ResourcesApplied is API state; Ready stays Unknown without workload observation |
| Diagnostics | Fixed metrics/histograms, safe events, cache/disconnect readiness | No built-in auth; trusted network/NetworkPolicy or authenticated proxy required |
| WASM | Optional Wasmtime 50.0.3 scalar ABI v1 | No general JSON guest or cluster credentials; not a full process-RSS/multitenant sandbox |

Library defaults: 10k cache/queue objects, 64 MiB encoded snapshot budget and
1 MiB per cache object. The MoonApp executable uses 1024 objects, 8 MiB total
cache, 256 KiB per object and queue capacity 1024. The example container is
limited to 128 MiB; encoded JSON bytes do not equal total process RSS.

The production image excludes acceptance probes. Its Linux release binary must
be built on Linux; a Windows native build is not an Ubuntu executable. External
workload images and their own runtime readiness/security requirements remain
the deployer's responsibility. See deployment.md and compatibility.md.

The [compatibility matrix](compatibility.md) identifies the tested Kubernetes
and CNI combinations. The public [Linux amd64 v0.1.2 image](evidence/20261125-v0.1.2/README.md)
was rebuilt and deployed in Kind 1.37.0. Broader Kubernetes and CNI coverage,
full regression and 1h/24h stability remain gates for broader support.
The [Mooncakes library](https://mooncakes.io/docs/miik-su/moonoperator) and
GitHub image releases follow the experimental single-replica scope above.

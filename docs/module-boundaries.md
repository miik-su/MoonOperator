# Module ownership and API policy

| Package | Owns | Boundary |
| --- | --- | --- |
| core | GVK, identity, immutable resources, bounded JSON, error vocabulary | No network, queue or Kubernetes credentials |
| client | API paths, CRUD/status/patch, pagination and Retry-After gating | Injected request transport; does not auto-replay writes |
| transport | TLS, bearer credentials, deadlines, request/response budgets, kubeconfig | Only package that handles Kubernetes credentials |
| watch | Byte framing, event decoding, checkpoint/reconnect state | No independent resource cache |
| cache | Snapshot publication, UID-safe removal, object/byte admission | Single cooperative event loop; consumes watch events |
| queue | Deduplication, in-flight exclusion, delay/backoff, admission | No HTTP retry engine or resource copies |
| controller | Reconcile workers, deadlines, outcomes, finalizer lifecycle | Client handles API calls; queue handles scheduling |
| runtime | Source LIST/WATCH orchestration, recovery and backpressure | Reuses watch, cache and queue rather than duplicating them |
| observability | Fixed counters, logger, diagnostics endpoints | No raw payload or credential labels |
| crd / rbac | Bounded schema subset and explicit permission manifests | No general admission engine or permission discovery |
| wasm | Optional restricted scalar-validator host | No Kubernetes client or credential capability |
| testing / examples | Fake API and example desired-state policy | Fake behavior does not replace real admission or GC |

`core.copy_json` is a low-level copying helper for already bounded JSON.
Validate untrusted values with `json_size` before calling it. The public
`Resource` constructors and transport do so; resource getters return copies.
Typed spec views derive from one Resource representation, not a second cache.
Cache byte accounting measures compact UTF-8 JSON retained, not process RSS.

Controllers distinguish retryable faults (409, 429, 5xx, transport failures and
timeouts) from Invalid/Capacity and permanent API errors. `Terminal` forgets
backoff for that attempt; a fresh event can still schedule the key. An application
that expects absent resources must handle 404 explicitly as desired-state policy.
Retry-After gates future requests, while the queue schedules future reconciliation;
neither replays a failed write automatically. `Manager` owns lifecycle, while
`Controller` owns workers. Async deadlines require cooperative, cancellable work;
they cannot preempt an infinite synchronous loop in a callback.

## Prerelease API policy

0.1.x APIs are experimental and can change. Before merging a breaking change,
document the affected generated `.mbti` symbols, migration example and changed
error/outcome semantics in the PR and release notes. Regenerate interfaces using
`moon info --target native`; do not edit them by hand. Keep implementation helpers
private when possible. A stable 1.0 contract requires further compatibility,
long-duration and deployment evidence; the current version does not promise it.

client-go and controller-runtime inform queue, cache and reconciliation design.
Their code and APIs are not copied or required. Platform HTTP/TLS is delegated
to moonbitlang/async instead of maintaining a second HTTP or cryptography stack.

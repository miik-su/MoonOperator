# Public API map

Module namespace remains `mik1e80/moonoperator`; not published to Mooncakes yet.
Public compiler-generated `.mbti` files are the exact API reference.

| Package | Responsibilities |
|---|---|
| core | Resource, GVK/Key/ResourceType, Registry, lifecycle helpers |
| client / transport | Injectable async CRUD, scoped paths, pagination, verified I/O |
| watch / cache | Byte parser, recovery checkpoint, immutable snapshots |
| queue / controller | Dirty/processing, delayed retry, workers, Manager |
| runtime | LIST/WATCH to cache and queue |
| crd / rbac | Schema subset/defaults, status-enabled CRD and explicit roles |
| testing | Fake transport with RV conflicts and one-shot faults |
| examples/moonapp | Idempotent desired-state example |
| wasm | Experimental scalar validation Host with typed plugin failures |

Keep mutation on one cooperative loop. Always release claimed queue keys with
Done, preferably through defer. Resource JSON accessors copy nested containers.
`Resource::spec_as[T : FromJson]` exposes typed spec views while retaining the raw
resource. `Config::parse_kubeconfig/load_kubeconfig` accept bounded JSON/YAML;
the latter resolves credential paths. `Source::new` injects list/watch functions
into the same recovery loop used by real clusters. `@controller.finalize` retains
cleanup state on failure/conflict. `Metrics` and `Logger` are injectable sinks.

## Review migration (unreleased 0.1.0)

`finalize` now returns `FinalizeResult`, replacing Bool. Continue permits normal
reconciliation; FinalizerAdded and CleanupPending need a delayed requeue;
CleanupComplete and NoLongerResponsible return Complete without another timer.
Cleanup exceptions/timeouts still propagate and retain the finalizer.

`Resource::controlled_by` requires `dependent_type~` and `owner_type~` so scope
does not depend on guessing from an empty namespace. ResourceType::validate checks
the accepted DNS/identifier subset; Registry, ownership and REST paths use it.
Scope declarations must reflect API discovery or a trusted registration.

`Queue::new` and `Parser::new` now raise Invalid for nonpositive limits. Capacity
errors distinguish CacheCapacity/QueueCapacity/ListCapacity; update exhaustive
matches accordingly. `Client::list` adds `max_bytes` (64 MiB default) and
`max_object_bytes` (1 MiB default) before accumulating a snapshot.

`Resource` retains Debug compatibility with fixed redacted output. Explicit JSON
access still exposes data to application code and must not be logged. MoonApp
reconciliation refuses unowned same-name children unless `adopt_unowned=true` is
explicitly selected; foreign controllers remain forbidden in either mode.

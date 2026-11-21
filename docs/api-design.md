# Public API map

Module namespace is `miik-su/moonoperator`, matching the intended publishing
account. The earlier development namespace was `mik1e80/moonoperator`.
Not published to Mooncakes yet; authenticated publishing rights remain to verify.
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

`Source::new` LIST callbacks must return the entire snapshot, a nonempty opaque
resourceVersion and an empty continue token. Partial or unversioned snapshots
are rejected before cache publication or queue admission. Pass `ns="name"` to
`Source::run` for a namespaced collection. The default empty value permits any
nonempty namespace for namespaced resources and requires an empty namespace for
cluster-scoped resources. LIST objects and Watch resource events must match GVK
and scope. Custom bookmarks also require a nonempty resourceVersion. An invalid
LIST stops the informer and preserves the prior snapshot as unready. Invalid
Watch events enter bounded relist recovery before the predicate, cache or queue
can see the event. Independent watches of the same GVK require separate Stores.

Typed GET, create, update and merge PATCH expect the returned object's GVK,
namespace and name to match the requested identity. An invalid response to a
write leaves its server-side outcome uncertain. Read the current resource
before deciding whether another write is needed.

`Client::list_page` requires a nonempty string resourceVersion and a string
continuation token when that field is present. It checks each item's
namespace against the requested scope and still accepts omitted item TypeMeta
by deriving it from the endpoint. `Client::list` rejects duplicate keys across
pages. Store replacement also rejects duplicate keys from custom sources
before changing the cached snapshot.

`Queue::new` and `Parser::new` now raise Invalid for nonpositive limits. Capacity
errors distinguish CacheCapacity/QueueCapacity/ListCapacity; update exhaustive
matches accordingly. `Client::list` adds `max_bytes` (64 MiB default) and
`max_object_bytes` (1 MiB default) before accumulating a snapshot.

`Resource` retains Debug compatibility with fixed redacted output. Explicit JSON
access still exposes data to application code and must not be logged. MoonApp
reconciliation refuses unowned same-name children unless `adopt_unowned=true` is
explicitly selected; foreign controllers remain forbidden in either mode.
When the API server enables OwnerReferencesPermissionEnforcement, updating an
existing child's owner references also needs delete permission on that child;
blocking owner deletion needs update on the owner's finalizers subresource.
The example Role includes the latter, but deliberately excludes dependent delete.
Optional adoption therefore needs a separately reviewed, narrowly scoped grant
on enforcing clusters. The plugin is not default-on in Kubernetes 1.37.

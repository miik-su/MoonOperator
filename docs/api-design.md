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
into the same recovery loop used by real clusters. `Controller::finalize` retains
cleanup state on failure/conflict. `Metrics` and `Logger` are injectable sinks.

# Delivery plan

Each numbered item is a separate substantive commit, with focused verification.

1. Module, architecture and delivery scope.
2. Dynamic resource model, identity, registry and typed errors.
3. Safe REST paths, selectors, pagination and CRUD/status client.
4. Secure transport/configuration and response limits.
5. Bounded streaming watch parsing and recovery state.
6. Snapshot cache, selectors and atomic relist synchronization.
7. Bounded dirty/processing workqueue and delayed exponential retries.
8. Reconcile workers and manager lifecycle with cache readiness.
9. Finalizers, ownership, conditions and event predicates.
10. CRD schema/default validation and least-privilege RBAC generation.
11. Fake API with optimistic concurrency and fault injection.
12. MoonApp Deployment/Service operator and manifests.
13. Observability, experimental extension contract and focused CI/documentation.

Real cluster E2E, longevity measurements and package publication are distinct
release gates. No unexecuted verification is described as passing. HA/Lease,
webhooks and a third-party WASM host remain later work; single replica only.

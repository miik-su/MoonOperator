# Developing a controller

Start with [the separate consumer module](../examples/consumer/README.md) to
exercise public APIs without a cluster. The root [MoonApp](../examples/moonapp)
adds real desired Deployment/Service generation and status publication.

1. Declare ResourceType with the actual group/version/kind/plural and scope.
   It is a trusted registration; automatic API discovery is not implemented.
2. Use Config::load_kubeconfig for the documented bearer/CA-file subset or
   Config::in_cluster for projected ServiceAccount credentials. Keep TLS checks.
3. Create bounded Store/Queue instances. Independent watches of the same GVK in
   different namespaces need separate Stores; replacement covers an entire GVK.
4. Implement reconciliation as read current state, calculate desired fields,
   compare, write only when required. Preserve unrelated metadata/server fields.
   Handle expected 404 explicitly; protect foreign controlling ownership.
5. Register an informer with Manager and gate Controller workers on cache sync.
   Callbacks must cooperate with cancellation and be idempotent. API 409 and
   transient failures retry from current state; permanent failures await a new
   event. Never silently turn a forbidden operation into broad default RBAC.
6. Define CRD schemas within the supported subset. Multiple served versions
   must use equal schemas; no admission or conversion webhook is generated.
7. Generate a namespaced Role with explicit resource/verb lists. Real-cluster
   adoption admission may require extra narrowly named dependent delete grants;
   default MoonApp adoption remains disabled.
8. Use fixed metrics/safe logger events. Applied API state does not mean Pods
   are Ready. Test the business state after duplicate/failure/recovery sequences.

Manager/Controller shutdown is cooperative. stop closes queue admission and
drains eligible ready work; delayed retries are not durable and process restart
starts a new LIST. Graceful shutdown cannot make arbitrary blocking application
callbacks safe or persist their side effects. Use one replica; there is no Lease.

See the [consumer instructions](../examples/consumer/README.md) for running the
same example from an independent directory using the Mooncakes dependency.

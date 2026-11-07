///|
/// Relist publication and queue admission are replayable. On overflow invalidate
/// readiness and relist instead of silently dropping a resource event.
pub async fn inform(
  config : @transport.Config,
  kind : @core.ResourceType,
  ns : String,
  store : @cache.Store,
  queue : @queue.Queue,
) -> Unit {
  let state = @watch.State::new()
  let client = config.client()
  for ;; {
    let code = try {
      if state.needs_list() {
        store.invalidate(kind.gvk)
        let snapshot = client.list(kind, ns)
        // Enqueue disappeared keys too, for delete reconciliation.
        let previous = store.list(kind.gvk)
        store.replace(kind.gvk, snapshot.items)
        for resource in previous {
          queue.add(resource.key())
        }
        for resource in snapshot.items {
          queue.add(resource.key())
        }
        state.listed(snapshot.resource_version)
      }
      @watch.stream(config, @watch.watch_path(kind, ns, state.version()), event => {
        store.apply(event)
        if event.resource() is Some(resource) {
          queue.add(resource.key())
        }
        state.checkpoint(event)
      })
      0
    } catch {
      @core.Api(code, _) => code
      @core.Capacity(_) => 410
      _ => 0
    }
    if code == 401 || code == 403 {
      store.invalidate(kind.gvk)
      raise @core.Api(code, "InformerAuthorizationFailed")
    }
    if code == 410 {
      store.invalidate(kind.gvk)
    }
    let sample = @tls.rand_bytes(1)[0].to_int() * 1000 / 255
    @async.sleep(state.disconnected(code, sample))
  }
}

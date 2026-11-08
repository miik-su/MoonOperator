///|
/// Relist publication and queue admission are replayable. On overflow invalidate
/// readiness and relist instead of silently dropping a resource event.
pub async fn inform(
  config : @transport.Config,
  kind : @core.ResourceType,
  ns : String,
  store : @cache.Store,
  queue : @queue.Queue,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
  predicate~ : (@core.Resource?, @watch.Event) -> Bool = @watch.changed,
  logger~ : @observability.Logger = @observability.Logger::silent(),
) -> Unit {
  let client = config.client()
  let source = Source::new(() => client.list(kind, ns), (rv, on_event) => {
    @watch.stream(config, @watch.watch_path(kind, ns, rv), on_event)
  })
  source.run(kind, store, queue, metrics~, predicate~, logger~)
}

///|
/// Injectable LIST/WATCH I/O. Both fake fault tests and live clusters use this
/// same recovery loop, including backpressure and resource-version checkpoints.
pub struct Source {
  list : async () -> @client.ResourceList
  watch : async (String, async (@watch.Event) -> Unit) -> Unit
}

///|
pub fn Source::new(
  list : async () -> @client.ResourceList,
  watch : async (String, async (@watch.Event) -> Unit) -> Unit,
) -> Source {
  { list, watch, }
}

///|
/// Yield to workers when the bounded queue is full; never discard the event.
async fn enqueue(queue : @queue.Queue, key : @core.Key) -> Unit {
  for ;; {
    let accepted = try queue.add(key) catch {
      @core.Capacity(_) => false
      error => raise error
    } noraise {
      _ => true
    }
    if accepted {
      return
    }
    @async.sleep(10)
  }
}

///|
pub async fn Source::run(
  self : Source,
  kind : @core.ResourceType,
  store : @cache.Store,
  queue : @queue.Queue,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
  predicate~ : (@core.Resource?, @watch.Event) -> Bool = @watch.changed,
  logger~ : @observability.Logger = @observability.Logger::silent(),
) -> Unit {
  let state = @watch.State::new()
  for ;; {
    let code = try {
      if state.needs_list() {
        metrics.increment("watch_relist")
        store.invalidate(kind.gvk)
        let snapshot = (self.list)()
        // Enqueue disappeared keys too, for delete reconciliation.
        let previous = store.list(kind.gvk)
        store.replace(kind.gvk, snapshot.items)
        for resource in previous {
          enqueue(queue, resource.key())
        }
        for resource in snapshot.items {
          enqueue(queue, resource.key())
        }
        state.listed(snapshot.resource_version)
        logger.emit(CacheSynchronized)
      }
      (self.watch)(state.version(), event => {
        if event.resource() is Some(resource) && resource.key().gvk != kind.gvk {
          raise @core.Invalid("watch resource kind mismatch")
        }
        let previous = event
          .resource()
          .bind(resource => store.get(resource.key()))
        let accepted = predicate(previous, event)
        store.apply(event)
        if accepted && event.resource() is Some(resource) {
          enqueue(queue, resource.key())
        }
        state.checkpoint(event)
      })
      0
    } catch {
      @core.Api(code, _) => code
      @core.Capacity(_) => 410
      @core.Invalid(_) => 410
      _ => 0
    }
    if code == 401 || code == 403 {
      store.invalidate(kind.gvk)
      raise @core.Api(code, "InformerAuthorizationFailed")
    }
    if code == 410 {
      store.invalidate(kind.gvk)
    }
    let sample = match @env.rand(1) {
      Some(bytes) => bytes[0].to_int() * 1000 / 255
      None => 500
    }
    metrics.increment("watch_reconnect")
    logger.emit(WatchReconnect, code~)
    @async.sleep(state.disconnected(code, sample))
  }
}

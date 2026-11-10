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
  progress~ : @observability.Progress = @observability.Progress::new(),
) -> Unit {
  let client = config.client()
  let (max_items, max_bytes, max_object_bytes) = store.limits()
  let source = Source::new(
    () => client.list(kind, ns, max_items~, max_bytes~, max_object_bytes~),
    (rv, on_event) => {
      @watch.stream(config, @watch.watch_path(kind, ns, rv), on_event, on_open=() => {
        progress.opened()
      })
    },
  )
  source.run(kind, store, queue, metrics~, predicate~, logger~, progress~)
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
      @core.QueueCapacity(_) => false
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
  progress~ : @observability.Progress = @observability.Progress::new(),
) -> Unit {
  let state = @watch.State::new()
  let mut malformed = 0
  for ;; {
    let mut watching = false
    let mut relist = false
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
        progress.listed(@async.now())
        logger.emit(CacheSynchronized)
      }
      watching = true
      (self.watch)(state.version(), event => {
        if event is Failure(code) {
          raise @core.Api(code, "WatchStatusError")
        }
        if event.resource() is Some(resource) && resource.key().gvk != kind.gvk {
          raise @core.Invalid("watch resource kind mismatch")
        }
        if event.resource() is Some(resource) &&
          resource.resource_version().is_empty() {
          raise @core.Invalid("watch resourceVersion required")
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
        progress.event(@async.now())
        malformed = 0
      })
      0
    } catch {
      @core.Api(code, _) => code
      @core.Invalid(_) as error => {
        malformed += 1
        if !watching || malformed >= 3 {
          store.invalidate(kind.gvk)
          raise error
        }
        relist = true
        0
      }
      @core.Capacity(_)
      | @core.CacheCapacity(_)
      | @core.ListCapacity(_)
      | @core.QueueCapacity(_) as error => {
        store.invalidate(kind.gvk)
        raise error
      }
      _ => 0
    }
    progress.disconnected(@async.now())
    if code != 0 && code != 410 && !@core.retryable(code) {
      store.invalidate(kind.gvk)
      raise @core.Api(code, "InformerPermanentFailure")
    }
    if code == 410 {
      store.invalidate(kind.gvk)
    }
    if relist {
      store.invalidate(kind.gvk)
      state.require_list()
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

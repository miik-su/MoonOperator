///|
pub(all) enum Outcome {
  Complete
  RequeueAfter(Int32)
  Retry
  Terminal
}

///|
pub struct Controller {
  queue : @queue.Queue
  reconcile : async (@core.Key) -> Outcome
  metrics : @observability.Metrics
  logger : @observability.Logger
  mut stopped : Bool
  timeout_ms : Int32
}

///|
pub fn Controller::new(
  queue : @queue.Queue,
  reconcile : async (@core.Key) -> Outcome,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
  logger~ : @observability.Logger = @observability.Logger::silent(),
  timeout_ms~ : Int32 = 30000,
) -> Controller {
  { queue, reconcile, metrics, logger, stopped: false, timeout_ms, }
}

///|
/// Release each claimed key on both normal completion and failure.
pub async fn Controller::step(self : Controller, now : Int64) -> Bool {
  if self.timeout_ms <= 0 {
    raise @core.Invalid("reconcile deadline must be positive")
  }
  guard self.queue.get(now) is Some(key) else { return false }
  defer self.queue.done(key)
  let started = @async.now()
  let mut failed = false
  let result = @async.with_timeout(self.timeout_ms, () => (self.reconcile)(key)) catch {
    error => {
      failed = true
      self.metrics.increment("reconcile_failure")
      let code = match error {
        @core.Api(code, _) => code
        _ => 0
      }
      self.logger.emit(ReconcileFailure, code~)
      match error {
        @core.Invalid(_)
        | @core.Capacity(_)
        | @core.CacheCapacity(_)
        | @core.QueueCapacity(_)
        | @core.ListCapacity(_) => Terminal
        @core.Api(code, _) =>
          if @core.retryable(code) {
            Retry
          } else {
            Terminal
          }
        _ => Retry
      }
    }
  }
  let finished = now + (@async.now() - started)
  self.metrics.observe("reconcile", finished - now)
  match result {
    Terminal => {
      if !failed {
        self.metrics.increment("reconcile_failure")
      }
      self.queue.forget(key)
    }
    Complete => {
      self.metrics.increment("reconcile_success")
      self.queue.forget(key)
    }
    RequeueAfter(delay) => {
      self.metrics.increment("reconcile_success")
      self.metrics.increment("reconcile_requeue")
      self.queue.forget(key)
      self.queue.add_after(
        key,
        finished + (if delay < 0 { 0 } else { delay }).to_int64(),
      )
    }
    Retry => {
      self.metrics.increment("queue_retry")
      ignore(self.queue.retry(key, finished))
    }
  }
  true
}

///|
pub fn Controller::stop(self : Controller) -> Unit {
  self.stopped = true
  self.queue.shutdown()
}

///|
/// Wait for cache synchronization before admitting cooperative workers.
pub async fn Controller::run(
  self : Controller,
  ready : () -> Bool,
  workers~ : Int32 = 1,
) -> Unit {
  if workers <= 0 || workers > 128 {
    raise @core.Invalid("workers must be 1..128")
  }
  while !ready() && !self.stopped {
    @async.sleep(20)
  }
  @async.with_task_group(group => {
    for _ in 0..<workers {
      group.spawn_bg(() => {
        while !self.stopped || self.queue.length() > 0 {
          if !ready() && !self.stopped {
            @async.sleep(20)
            continue
          }
          if !self.step(@async.now()) {
            @async.sleep(20)
          }
        }
      })
    }
  })
}

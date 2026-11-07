///|
pub(all) enum Outcome {
  Complete
  RequeueAfter(Int32)
  Retry
}

///|
pub struct Controller {
  queue : @queue.Queue
  reconcile : async (@core.Key) -> Outcome
  metrics : @observability.Metrics
  mut stopped : Bool
}

///|
pub fn Controller::new(
  queue : @queue.Queue,
  reconcile : async (@core.Key) -> Outcome,
  metrics~ : @observability.Metrics = @observability.Metrics::new(),
) -> Controller {
  { queue, reconcile, metrics, stopped: false, }
}

///|
/// Release each claimed key on both normal completion and failure.
pub async fn Controller::step(self : Controller, now : Int64) -> Bool {
  guard self.queue.get(now) is Some(key) else { return false }
  defer self.queue.done(key)
  let started = @async.now()
  let result = (self.reconcile)(key) catch {
    _ => {
      self.metrics.increment("reconcile_failure")
      Retry
    }
  }
  let finished = now + (@async.now() - started)
  self.metrics.observe("reconcile", finished - now)
  match result {
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

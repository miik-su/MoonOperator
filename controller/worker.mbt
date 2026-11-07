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
  mut stopped : Bool
}

///|
pub fn Controller::new(
  queue : @queue.Queue,
  reconcile : async (@core.Key) -> Outcome,
) -> Controller {
  { queue, reconcile, stopped: false, }
}

///|
/// Release each claimed key on both normal completion and failure.
pub async fn Controller::step(self : Controller, now : Int64) -> Bool {
  guard self.queue.get(now) is Some(key) else { return false }
  defer self.queue.done(key)
  let result = (self.reconcile)(key) catch { _ => Retry }
  match result {
    Complete => self.queue.forget(key)
    RequeueAfter(delay) => {
      self.queue.forget(key)
      self.queue.add_after(
        key,
        now + (if delay < 0 { 0 } else { delay }).to_int64(),
      )
    }
    Retry => ignore(self.queue.retry(key, now))
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
        while !self.stopped {
          if !self.step(@async.now()) {
            @async.sleep(20)
          }
        }
      })
    }
  })
}

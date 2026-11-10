///|
/// Single-event-loop queue; dirty work arriving in flight is never lost.
pub struct Queue {
  admitted : Map[@core.Key, Bool]
  dirty : Map[@core.Key, Bool]
  processing : Map[@core.Key, Bool]
  delayed : Map[@core.Key, Int32]
  timers : Array[Timer]
  mut sequence : Int64
  retries : Map[@core.Key, Int32]
  ready : @deque.Deque[@core.Key]
  capacity : Int32
  mut closed : Bool
}

///|
pub fn Queue::new(capacity~ : Int32 = 10000) -> Queue raise @core.OperatorError {
  if capacity <= 0 {
    raise @core.Invalid("queue capacity must be positive")
  }
  {
    admitted: Map([]),
    dirty: Map([]),
    processing: Map([]),
    delayed: Map([]),
    timers: [],
    sequence: 0L,
    retries: Map([]),
    ready: @deque.Deque([]),
    capacity,
    closed: false,
  }
}

///|
pub fn Queue::add(
  self : Queue,
  key : @core.Key,
) -> Unit raise @core.OperatorError {
  if self.closed {
    return
  }
  if self.dirty.contains(key) {
    return
  }
  if !self.admitted.contains(key) && self.admitted.length() >= self.capacity {
    raise @core.QueueCapacity("workqueue capacity")
  }
  self.cancel_timer(key)
  self.admitted[key] = true
  self.dirty[key] = true
  if !self.processing.contains(key) {
    self.ready.push_back(key)
  }
}

///|
pub fn Queue::get(
  self : Queue,
  now : Int64,
) -> @core.Key? raise @core.OperatorError {
  while !self.timers.is_empty() && self.timers[0].at <= now {
    let key = self.timers[0].key
    self.add(key)
  }
  guard self.ready.pop_front() is Some(key) else { return None }
  self.dirty.remove(key)
  self.processing[key] = true
  Some(key)
}

///|
pub fn Queue::done(self : Queue, key : @core.Key) -> Unit {
  if !self.processing.contains(key) {
    return
  }
  self.processing.remove(key)
  if self.dirty.contains(key) {
    self.ready.push_back(key)
  } else if !self.delayed.contains(key) {
    self.admitted.remove(key)
    self.retries.remove(key)
  }
}

///|
pub fn Queue::forget(self : Queue, key : @core.Key) -> Unit {
  self.retries.remove(key)
}

///|
pub fn Queue::add_after(
  self : Queue,
  key : @core.Key,
  at : Int64,
) -> Unit raise @core.OperatorError {
  if self.closed || self.dirty.contains(key) {
    return
  }
  if !self.admitted.contains(key) && self.admitted.length() >= self.capacity {
    raise @core.QueueCapacity("delayed queue capacity")
  }
  self.admitted[key] = true
  match self.delayed.get(key) {
    Some(index) =>
      if at < self.timers[index].at {
        self.timers[index] = { ..self.timers[index], at, }
        ignore(self.sift_up(index))
      }
    None => {
      self.delayed[key] = self.timers.length()
      self.timers.push({ key, at, order: self.sequence, })
      self.sequence += 1L
      ignore(self.sift_up(self.timers.length() - 1))
    }
  }
}

///|
pub fn Queue::retry(
  self : Queue,
  key : @core.Key,
  now : Int64,
) -> Int32 raise @core.OperatorError {
  if self.closed {
    return 0
  }
  let count = self.retries.get(key).unwrap_or(0)
  let delay = 100 * (1 << (if count > 8 { 8 } else { count }))
  self.add_after(key, now + delay.to_int64())
  self.retries[key] = if count >= 9 { 9 } else { count + 1 }
  delay
}

///|
/// Shutdown stops admission and discards delayed work; admitted work drains.
pub fn Queue::shutdown(self : Queue) -> Unit {
  self.closed = true
  let delayed = self.delayed.keys().collect()
  for key in delayed {
    if !self.processing.contains(key) && !self.dirty.contains(key) {
      self.admitted.remove(key)
      self.retries.remove(key)
    }
  }
  self.delayed.clear()
  self.timers.clear()
}

///|
/// Number of distinct admitted keys across ready, delayed and in-flight work.
pub fn Queue::pending(self : Queue) -> Int32 {
  self.admitted.length()
}

///|
pub fn Queue::length(self : Queue) -> Int32 {
  self.ready.length()
}

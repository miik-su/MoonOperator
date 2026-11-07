///|
/// Single-event-loop queue; dirty work arriving in flight is never lost.
pub struct Queue {
  dirty : Map[@core.Key, Bool]
  processing : Map[@core.Key, Bool]
  delayed : Map[@core.Key, Int64]
  retries : Map[@core.Key, Int32]
  ready : Array[@core.Key]
  capacity : Int32
  mut closed : Bool
}

///|
pub fn Queue::new(capacity~ : Int32 = 10000) -> Queue {
  {
    dirty: Map([]),
    processing: Map([]),
    delayed: Map([]),
    retries: Map([]),
    ready: [],
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
  if !self.processing.contains(key) &&
    self.dirty.length() + self.processing.length() + self.delayed.length() >=
    self.capacity &&
    !self.delayed.contains(key) {
    raise @core.Capacity("workqueue capacity")
  }
  self.delayed.remove(key)
  self.dirty[key] = true
  if !self.processing.contains(key) {
    self.ready.push(key)
  }
}

///|
pub fn Queue::get(
  self : Queue,
  now : Int64,
) -> @core.Key? raise @core.OperatorError {
  let due : Array[@core.Key] = []
  for key, at in self.delayed {
    if at <= now {
      due.push(key)
    }
  }
  for key in due {
    self.delayed.remove(key)
    self.add(key)
  }
  if self.ready.is_empty() {
    return None
  }
  let key = self.ready[0]
  ignore(self.ready.remove(0))
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
    self.ready.push(key)
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
  if !self.delayed.contains(key) &&
    !self.processing.contains(key) &&
    self.dirty.length() + self.processing.length() + self.delayed.length() >=
    self.capacity {
    raise @core.Capacity("delayed queue capacity")
  }
  match self.delayed.get(key) {
    Some(old) => if at < old { self.delayed[key] = at }
    None => self.delayed[key] = at
  }
}

///|
pub fn Queue::retry(
  self : Queue,
  key : @core.Key,
  now : Int64,
) -> Int32 raise @core.OperatorError {
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
  self.delayed.clear()
}

///|
pub fn Queue::length(self : Queue) -> Int32 {
  self.ready.length()
}

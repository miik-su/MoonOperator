///|
/// Indexed min-heap: cancellation removes entries immediately, so repeated
/// rescheduling cannot accumulate stale tombstones beyond queue capacity.
struct Timer {
  key : @core.Key
  at : Int64
  order : Int64
}

///|
fn earlier(a : Timer, b : Timer) -> Bool {
  a.at < b.at || (a.at == b.at && a.order < b.order)
}

///|
fn Queue::swap_timers(self : Queue, a : Int32, b : Int32) -> Unit {
  let tmp = self.timers[a]
  self.timers[a] = self.timers[b]
  self.timers[b] = tmp
  self.delayed[self.timers[a].key] = a
  self.delayed[self.timers[b].key] = b
}

///|
fn Queue::sift_up(self : Queue, start : Int32) -> Int32 {
  let mut index = start
  while index > 0 {
    let parent = (index - 1) / 2
    if !earlier(self.timers[index], self.timers[parent]) {
      break
    }
    self.swap_timers(index, parent)
    index = parent
  }
  index
}

///|
fn Queue::sift_down(self : Queue, start : Int32) -> Unit {
  let mut index = start
  while index * 2 + 1 < self.timers.length() {
    let left = index * 2 + 1
    let right = left + 1
    let smallest = if right < self.timers.length() &&
      earlier(self.timers[right], self.timers[left]) {
      right
    } else {
      left
    }
    if !earlier(self.timers[smallest], self.timers[index]) {
      break
    }
    self.swap_timers(index, smallest)
    index = smallest
  }
}

///|
fn Queue::cancel_timer(self : Queue, key : @core.Key) -> Unit {
  guard self.delayed.get(key) is Some(index) else { return }
  let last = self.timers.pop().unwrap()
  self.delayed.remove(key)
  if index < self.timers.length() {
    self.timers[index] = last
    self.delayed[last.key] = index
    let updated = self.sift_up(index)
    self.sift_down(updated)
  }
}

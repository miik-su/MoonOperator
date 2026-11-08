///|
test "capacity counts distinct keys and due timers never discard admitted work" {
  for capacity in [0, -1] {
    assert_true(
      try @queue.Queue::new(capacity~) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
  let a : @core.Key = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    ns: "",
    name: "a",
  }
  let b = { ..a, name: "b", }
  let c = { ..a, name: "c", }
  let q = @queue.Queue::new(capacity=2)
  q.add(a)
  assert_eq(q.get(0L), Some(a))
  q.add(a) // Dirty and processing refer to the same admitted identity.
  q.add_after(b, 1L)
  assert_eq(q.pending(), 2)
  assert_true(
    try q.add(c) catch {
      @core.QueueCapacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(q.get(1L), Some(b))
  q.done(b)
  q.done(a)
  assert_eq(q.get(1L), Some(a))
  q.done(a)
  assert_eq(q.pending(), 0)
}

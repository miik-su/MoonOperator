///|
test "repeated cancellation cannot grow hidden timer memory" {
  let key : @core.Key = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    ns: "demo",
    name: "x",
  }
  let q = Queue::new(capacity=1)
  for _ in 0..<20000 {
    q.add_after(key, 999999L)
    q.add(key)
    assert_eq(q.get(0L), Some(key))
    q.done(key)
  }
  assert_eq(q.timers.length(), 0)
  assert_eq(q.delayed.length(), 0)
  assert_eq(q.pending(), 0)
}

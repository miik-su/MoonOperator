///|
test "queue deduplicates in flight and retains dirty events" {
  let key : @core.Key = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    ns: "demo",
    name: "x",
  }
  let q = @queue.Queue::new()
  q.add(key)
  q.add(key)
  assert_eq(q.length(), 1)
  assert_eq(q.get(0L), Some(key))
  q.add(key)
  assert_eq(q.get(0L), None)
  q.done(key)
  assert_eq(q.get(0L), Some(key))
  ignore(q.retry(key, 0L))
  q.done(key)
  assert_eq(q.get(99L), None)
  assert_eq(q.get(100L), Some(key))
  q.forget(key)
  q.done(key)
  q.shutdown()
  q.add(key)
  assert_eq(q.get(1000L), None)
}

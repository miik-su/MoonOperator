///|
test "delays are ordered, cancellation is immediate and reschedules keep earliest deadline" {
  let q = @queue.Queue::new(capacity=1000)
  let keys : Array[@core.Key] = []
  for i in 0..<1000 {
    let key : @core.Key = {
      gvk: { group: "", version: "v1", kind: "Pod", },
      ns: "demo",
      name: i.to_string(),
    }
    keys.push(key)
    q.add_after(key, (1000 - i).to_int64())
  }
  q.add_after(keys[0], 1L)
  q.add_after(keys[0], 99999L)
  assert_eq(q.get(0L), None)
  assert_eq(q.get(1L), Some(keys[0]))
  q.done(keys[0])
  assert_eq(q.get(1L), Some(keys[999]))
  q.done(keys[999])
  // Cancel a middle heap node through fresh immediate work.
  q.add(keys[500])
  assert_eq(q.get(1L), Some(keys[500]))
  q.done(keys[500])
  for i in 2..<1000 {
    if i == 500 {
      continue
    }
    let key = q.get(i.to_int64()).unwrap()
    assert_eq(key, keys[1000 - i])
    q.done(key)
  }
  assert_eq(q.pending(), 0)
}

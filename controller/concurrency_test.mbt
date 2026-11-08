///|
async test "cooperative workers never reconcile one key concurrently and drain on stop" {
  let key : @core.Key = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    ns: "demo",
    name: "x",
  }
  let queue = @queue.Queue::new()
  for i in 0..<16 {
    queue.add({ ..key, name: i.to_string(), })
  }
  let in_flight : Map[@core.Key, Bool] = Map([])
  let calls = Ref(0)
  let controller = @controller.Controller::new(queue, key => {
    assert_false(in_flight.contains(key))
    in_flight[key] = true
    if key.name == "0" && calls.val == 0 {
      queue.add(key)
    }
    calls.val += 1
    @async.sleep(2)
    in_flight.remove(key)
    Complete
  })
  @async.with_timeout(2000, () => {
    @async.with_task_group(group => {
      group.spawn_bg(() => controller.run(() => true, workers=4))
      while calls.val < 4 {
        @async.sleep(1)
      }
      controller.stop()
    })
  })
  assert_eq(calls.val, 17)
  assert_eq(queue.pending(), 0)
}

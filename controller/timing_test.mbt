///|
async test "requeue delay starts at completion rather than reconcile start" {
  let key : @core.Key = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    ns: "",
    name: "x",
  }
  let queue = @queue.Queue::new()
  queue.add(key)
  let controller = @controller.Controller::new(queue, _ => {
    @async.sleep(30)
    RequeueAfter(100)
  })
  assert_true(controller.step(0L))
  assert_eq(queue.get(100L), None)
  assert_true(queue.get(1000L) is Some(_))
  queue.done(key)
}

///|
async test "deadline releases key and permanent errors await a fresh event" {
  let key : @core.Key = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    ns: "",
    name: "x",
  }
  let queue = @queue.Queue::new()
  queue.add(key)
  let slow = @controller.Controller::new(
    queue,
    _ => {
      @async.sleep(10000)
      Complete
    },
    timeout_ms=10,
  )
  assert_true(slow.step(0L))
  assert_true(queue.get(1000L) is Some(_))
  queue.done(key)
  queue.add(key)
  let forbidden = @controller.Controller::new(queue, _ => {
    raise @core.Api(403, "forbidden")
  })
  assert_true(forbidden.step(1000L))
  assert_eq(queue.pending(), 0)
  queue.add(key)
  assert_true(forbidden.step(2000L))
  assert_eq(queue.pending(), 0)
  queue.add(key)
  let conflict = @controller.Controller::new(queue, _ => {
    raise @core.Api(409, "conflict")
  })
  assert_true(conflict.step(3000L))
  assert_eq(queue.pending(), 1)
}

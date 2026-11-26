///|
async test "failure releases key and retries after delay" {
  let key : @core.Key = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    ns: "",
    name: "x",
  }
  let q = @queue.Queue::new()
  q.add(key)
  let c = @controller.Controller::new(q, _ => raise @core.Transport("injected"))
  let started = @async.now()
  assert_true(c.step(0L))
  // Retry is scheduled from completion, so include the observed step duration.
  let retry_by = 100L + (@async.now() - started)
  assert_false(c.step(99L))
  assert_true(c.step(retry_by))
  c.stop()
}

///|
async test "100 in-flight changes and conflict retry converge to the latest desired value" {
  let key : @core.Key = {
    gvk: { group: "", version: "v1", kind: "ConfigMap", },
    ns: "model",
    name: "singleton",
  }
  let queue = @queue.Queue::new(capacity=1)
  let desired = Ref(0)
  let actual = Ref(-1)
  let calls = Ref(0)
  let writes = Ref(0)
  let started = Ref(false)
  let metrics = @observability.Metrics::new()
  let controller = @controller.Controller::new(
    queue,
    _ => {
      calls.val += 1
      if calls.val == 1 {
        started.val = true
        @async.sleep(10)
        raise @core.Api(409, "injected conflict")
      }
      if actual.val != desired.val {
        actual.val = desired.val
        writes.val += 1
      }
      Complete
    },
    metrics~,
  )
  queue.add(key)
  @async.with_timeout(2000, () => {
    @async.with_task_group(group => {
      group.spawn_bg(() => ignore(controller.step(@async.now())))
      while !started.val {
        @async.sleep(1)
      }
      for revision in 1..<=100 {
        desired.val = revision
        queue.add(key)
        queue.add(key)
      }
    })
  })
  assert_true(controller.step(@async.now()))
  assert_eq(actual.val, 100)
  assert_eq(writes.val, 1)
  assert_eq(calls.val, 2)
  assert_eq(metrics.count("reconcile_failure"), 1L)
  assert_eq(metrics.count("reconcile_success"), 1L)
  assert_false(controller.step(@async.now()))
  assert_eq(queue.pending(), 0)
}

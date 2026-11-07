///|
test "manager rejects duplicate registrations and starts unready" {
  let manager = @controller.Manager::new()
  let controller = @controller.Controller::new(@queue.Queue::new(), _ => {
    Complete
  })
  manager.register("demo", controller, () => false)
  assert_false(manager.ready())
  assert_true(
    try manager.register("demo", controller, () => true) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
}

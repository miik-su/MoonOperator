///|
async test "reconcile logs retain codes without server message secrets" {
  let records : Array[Json] = []
  let logger = @observability.Logger::new(record => records.push(record))
  let queue = @queue.Queue::new()
  queue.add({
    gvk: { group: "", version: "v1", kind: "Pod", },
    ns: "demo",
    name: "x",
  })
  let controller = @controller.Controller::new(
    queue,
    _ => raise @core.Api(403, "Bearer secret-token"),
    logger~,
  )
  assert_true(controller.step(0L))
  assert_eq(records.length(), 1)
  assert_eq(@core.field(records[0], "httpCode"), Json::number(403.0))
  assert_false(records[0].stringify().contains("secret-token"))
}

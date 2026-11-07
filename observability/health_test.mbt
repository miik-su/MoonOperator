///|
test "readiness depends on synchronized cache" {
  let (code, _) = @observability.route("/readyz", false, 0)
  assert_eq(code, 503)
  let (code, body) = @observability.route("/metrics", true, 4)
  assert_eq(code, 200)
  assert_true(body.contains("moonoperator_queue_depth 4"))
}

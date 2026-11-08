///|
test "readiness depends on synchronized cache" {
  let (code, _) = @observability.route("/readyz", false, 0)
  assert_eq(code, 503)
  let (code, body) = @observability.route(
    "/metrics",
    true,
    4,
    cache_objects=3,
    cache_bytes=1024,
  )
  assert_eq(code, 200)
  assert_true(body.contains("moonoperator_queue_depth 4"))
  assert_true(body.contains("moonoperator_cache_objects 3"))
  assert_true(body.contains("moonoperator_cache_encoded_bytes 1024"))
}

///|
test "readiness tracks sustained disconnects without penalizing a quiet open watch" {
  let state = @observability.Progress::new()
  state.listed(100L)
  state.opened()
  assert_true(state.fresh(1000000L, 1000))
  state.disconnected(1000000L)
  state.disconnected(1000500L)
  assert_false(state.fresh(1001001L, 1000))
  assert_true(state.fresh(1001001L, 0))
  state.event(1001002L)
  assert_true(state.fresh(1001003L, 1000))
  let output = state.prometheus(1001003L)
  assert_true(output.contains("moonoperator_last_watch_event_age_ms 1"))
  assert_true(output.contains("moonoperator_watch_connected 1"))
}

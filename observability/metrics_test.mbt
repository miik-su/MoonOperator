///|
test "metrics reject unbounded labels and expose duration sum count" {
  let metrics = @observability.Metrics::new()
  metrics.increment("reconcile_success")
  metrics.increment("user-controlled-name")
  metrics.observe("reconcile", 250L)
  let output = metrics.prometheus()
  assert_true(output.contains("moonoperator_reconcile_success_total 1"))
  assert_true(
    output.contains("moonoperator_reconcile_duration_seconds_sum 0.25"),
  )
  assert_false(output.contains("user-controlled-name"))
}

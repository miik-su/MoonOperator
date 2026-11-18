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

///|
test "bounded cumulative latency buckets preserve aggregate observations" {
  let metrics = @observability.Metrics::new()
  metrics.observe("reconcile", 250L)
  metrics.observe("reconcile", 750L)
  metrics.observe("unbounded-user-value", 1L)
  let output = metrics.prometheus()
  assert_true(
    output.contains(
      "moonoperator_reconcile_latency_seconds_bucket{le=\"0.1\"} 0\n",
    ),
  )
  assert_true(
    output.contains(
      "moonoperator_reconcile_latency_seconds_bucket{le=\"0.5\"} 1\n",
    ),
  )
  assert_true(
    output.contains(
      "moonoperator_reconcile_latency_seconds_bucket{le=\"1\"} 2\n",
    ),
  )
  assert_true(
    output.contains(
      "moonoperator_reconcile_latency_seconds_bucket{le=\"+Inf\"} 2\n",
    ),
  )
  assert_true(output.contains("moonoperator_reconcile_latency_seconds_sum 1\n"))
  assert_true(
    output.contains("moonoperator_reconcile_duration_seconds_count 2\n"),
  )
  assert_false(output.contains("unbounded-user-value"))
}

///|
/// Fixed metric names keep cardinality bounded. No resource names or credentials.
pub struct Metrics {
  counters : Map[String, Int64]
  durations : Map[String, (Int64, Int64)]
  buckets : Map[String, Array[Int64]]
}

///|
pub fn Metrics::new() -> Metrics {
  { counters: Map([]), durations: Map([]), buckets: Map([]), }
}

///|
let counter_names : Array[String] = [
  "reconcile_success", "reconcile_failure", "reconcile_requeue", "watch_reconnect",
  "watch_relist", "queue_retry", "api_request", "api_error", "diagnostic_timeout",
  "diagnostic_rate_limited", "reconcile_conflict", "reconcile_api_permanent", "reconcile_api_retryable",
  "reconcile_invalid", "reconcile_timeout", "reconcile_transport", "reconcile_other",
]

///|
let latency_bounds_ms : Array[Int64] = [
  1L, 5L, 10L, 50L, 100L, 500L, 1000L, 5000L,
]

///|
pub fn Metrics::increment(self : Metrics, name : String) -> Unit {
  if !counter_names.contains(name) {
    return
  }
  self.counters[name] = self.counters.get(name).unwrap_or(0L) + 1L
}

///|
pub fn Metrics::count(self : Metrics, name : String) -> Int64 {
  self.counters.get(name).unwrap_or(0L)
}

///|
/// Duration sum/count in seconds supports aggregate mean without unbounded samples.
pub fn Metrics::observe(
  self : Metrics,
  name : String,
  elapsed_ms : Int64,
) -> Unit {
  if !(name == "api" || name == "reconcile") {
    return
  }
  let (count, total) = self.durations.get(name).unwrap_or((0L, 0L))
  let elapsed_ms = if elapsed_ms < 0L { 0L } else { elapsed_ms }
  self.durations[name] = (count + 1L, total + elapsed_ms)
  let buckets = self.buckets.get_or_init(name, () => {
    Array::make(latency_bounds_ms.length(), 0L)
  })
  for i, bound in latency_bounds_ms {
    if elapsed_ms <= bound {
      buckets[i] += 1L
    }
  }
}

///|
pub fn Metrics::prometheus(self : Metrics) -> String {
  let out = StringBuilder()
  for name in counter_names {
    out.write_string(
      "# TYPE moonoperator_\{name}_total counter\nmoonoperator_\{name}_total \{self.count(name)}\n",
    )
  }
  for name in ["api", "reconcile"] {
    let (count, total) = self.durations.get(name).unwrap_or((0L, 0L))
    out.write_string(
      "# TYPE moonoperator_\{name}_duration_seconds summary\nmoonoperator_\{name}_duration_seconds_count \{count}\nmoonoperator_\{name}_duration_seconds_sum \{total.to_double() / 1000.0}\n",
    )
    out.write_string("# TYPE moonoperator_\{name}_latency_seconds histogram\n")
    let buckets = self.buckets
      .get(name)
      .unwrap_or(Array::make(latency_bounds_ms.length(), 0L))
    for i, bound in latency_bounds_ms {
      out.write_string(
        "moonoperator_\{name}_latency_seconds_bucket{le=\"\{bound.to_double() / 1000.0}\"} \{buckets[i]}\n",
      )
    }
    out.write_string(
      "moonoperator_\{name}_latency_seconds_bucket{le=\"+Inf\"} \{count}\nmoonoperator_\{name}_latency_seconds_count \{count}\nmoonoperator_\{name}_latency_seconds_sum \{total.to_double() / 1000.0}\n",
    )
  }
  out.to_string()
}

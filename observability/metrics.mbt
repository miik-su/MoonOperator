///|
/// Fixed metric names keep cardinality bounded. No resource names or credentials.
pub struct Metrics {
  counters : Map[String, Int64]
  durations : Map[String, (Int64, Int64)]
}

///|
pub fn Metrics::new() -> Metrics {
  { counters: Map([]), durations: Map([]), }
}

///|
pub fn Metrics::increment(self : Metrics, name : String) -> Unit {
  if ![
      "reconcile_success", "reconcile_failure", "reconcile_requeue", "watch_reconnect",
      "watch_relist", "queue_retry", "api_request", "api_error",
    ].contains(name) {
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
  self.durations[name] = (
    count + 1L,
    total + (if elapsed_ms < 0L { 0L } else { elapsed_ms }),
  )
}

///|
pub fn Metrics::prometheus(self : Metrics) -> String {
  let out = StringBuilder()
  for
    name in [
      "reconcile_success", "reconcile_failure", "reconcile_requeue", "watch_reconnect",
      "watch_relist", "queue_retry", "api_request", "api_error",
    ] {
    out.write_string(
      "# TYPE moonoperator_\{name}_total counter\nmoonoperator_\{name}_total \{self.count(name)}\n",
    )
  }
  for name in ["api", "reconcile"] {
    let (count, total) = self.durations.get(name).unwrap_or((0L, 0L))
    out.write_string(
      "# TYPE moonoperator_\{name}_duration_seconds summary\nmoonoperator_\{name}_duration_seconds_count \{count}\nmoonoperator_\{name}_duration_seconds_sum \{total.to_double() / 1000.0}\n",
    )
  }
  out.to_string()
}

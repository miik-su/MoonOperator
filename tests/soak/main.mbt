///|
/// Explicit bounded load probe, never selected by normal `moon test`.
async fn main {
  let seconds = match @env.get_env_var("MOONOPERATOR_SOAK_SECONDS") {
    Some(value) =>
      match @json.parse(value) {
        Number(n, ..) =>
          if n == n.floor() && n >= 1.0 && n <= 3600.0 {
            n.to_int()
          } else {
            fail("soak duration 1..3600 seconds")
          }
        _ => fail("duration must be integer")
      }
    None => 10
  }
  let store = @cache.Store::new(capacity=1000)
  let queue = @queue.Queue::new(capacity=1000)
  let resources : Array[@core.Resource] = []
  for i in 0..<1000 {
    resources.push(
      @core.Resource::from_json({
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {
          "name": "p\{i}",
          "namespace": "soak",
          "resourceVersion": "initial",
        },
      }),
    )
  }
  let gvk = resources[0].key().gvk
  store.replace(gvk, resources)
  let attempts : Map[@core.Key, Int32] = Map([])
  let metrics = @observability.Metrics::new()
  let controller = @controller.Controller::new(
    queue,
    key => {
      let n = attempts.get(key).unwrap_or(0)
      attempts[key] = n + 1
      if n % 31 == 0 {
        raise @core.Transport("injected transient failure")
      }
      Complete
    },
    metrics~,
  )
  let started = @async.now()
  let mut iterations = 0
  while @async.now() - started < seconds.to_int64() * 1000L {
    let resource = resources[iterations % 1000]
    queue.add(resource.key())
    queue.add(resource.key())
    store.apply(
      Modified(
        resource.with_metadata(
          "resourceVersion",
          Json::string("rv-\{iterations}"),
        ),
      ),
    )
    ignore(controller.step(iterations.to_int64() * 100L))
    assert_true(queue.pending() <= 1000)
    iterations += 1
    if iterations % 100 == 0 {
      @async.pause()
    }
  }
  controller.stop()
  while queue.length() > 0 {
    ignore(controller.step(iterations.to_int64() * 100L))
  }
  assert_eq(queue.pending(), 0)
  assert_eq(store.list(gvk).length(), 1000)
  let report : Json = {
    "duration_ms": (@async.now() - started).to_int(),
    "iterations": iterations,
    "objects": 1000,
    "queue_pending_end": queue.pending(),
    "cache_objects_end": store.list(gvk).length(),
    "faults_and_duplicates": true,
    "reconcile_failures": metrics.count("reconcile_failure"),
    "reconcile_successes": metrics.count("reconcile_success"),
    "queue_retries": metrics.count("queue_retry"),
    "cache_encoded_bytes_end": store.bytes(),
    "memory_rss": "not measured",
  }
  let input : Json = {
    "resource_template": resources[0].json(),
    "resource_count": 1000,
    "name_pattern": "p{index}, index=0..999",
    "duration_seconds": seconds,
    "duplicate_policy": "enqueue each key twice per iteration",
    "failure_policy": "Transport failure when per-key reconcile attempt count modulo 31 is zero (count starts at zero)",
    "queue_capacity": 1000,
    "cache_capacity": 1000,
    "external_services": "none; synthetic cooperative event loop",
  }
  @fs.write_file("soak-input.json", input.stringify(indent=2))
  @fs.write_file("soak-report.json", report.stringify(indent=2))
  println(report.stringify())
}

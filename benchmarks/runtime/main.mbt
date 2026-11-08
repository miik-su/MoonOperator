///|
/// Fixed-count observations, not a performance guarantee. Core bench clock
/// reports microseconds; checksums keep measured work observable.
fn sample(name : String, count : Int32, f : () -> Int32 raise) -> Json raise {
  let started = @bench.monotonic_clock_start()
  let mut checksum = 0
  for _ in 0..<count {
    checksum += f()
  }
  let elapsed_us = @bench.monotonic_clock_end(started)
  {
    "name": name,
    "iterations": count,
    "total_us": elapsed_us,
    "mean_us": elapsed_us / count.to_double(),
    "checksum": checksum,
  }
}

///|
async fn main {
  let resource = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
      "name": "p0",
      "namespace": "bench",
      "resourceVersion": "opaque",
      "labels": { "app": "bench" },
    },
    "spec": { "containers": [{ "name": "app", "image": "nginx:1.27" }] },
  })
  let raw = resource.json().stringify()
  let store = @cache.Store::new(capacity=1000)
  let resources : Array[@core.Resource] = []
  for i in 0..<1000 {
    resources.push(resource.with_metadata("name", Json::string("p\{i}")))
  }
  store.replace(resource.key().gvk, resources)
  let queue = @queue.Queue::new(capacity=1000)
  let event = @utf8.encode("{\"type\":\"ADDED\",\"object\":" + raw + "}\n")
  let observations : Array[Json] = []
  observations.push(
    sample("resource_copy_serialize", 1000, () => {
      resource.json().stringify().length()
    }),
  )
  observations.push(
    sample("json_parse", 1000, () => @json.parse(raw).stringify().length()),
  )
  observations.push(
    sample("cache_get_1000_objects", 10000, () => {
      store.get(resource.key()).unwrap().key().name.length()
    }),
  )
  observations.push(
    sample("cache_label_query_1000_objects", 100, () => {
      store.list(resource.key().gvk, labels={ "app": "bench" }).length()
    }),
  )
  observations.push(
    sample("watch_event_decode", 1000, () => {
      @watch.Parser::new().feed(event).length()
    }),
  )
  observations.push(
    sample("queue_add_claim_done", 10000, () => {
      queue.add(resource.key())
      let key = queue.get(0L).unwrap()
      queue.done(key)
      key.name.length()
    }),
  )
  let fake = @testing.Fake::new()
  let client = fake.client()
  let app = client.create(
    @moonapp.app_type,
    @core.Resource::from_json({
      "apiVersion": "moonoperator.dev/v1",
      "kind": "MoonApp",
      "metadata": { "name": "bench", "namespace": "bench", "generation": 1 },
      "spec": { "image": "nginx:1.27", "replicas": 3 },
    }),
  )
  ignore(@moonapp.reconcile(client, app.key()))
  let writes = fake.write_count()
  let started = @bench.monotonic_clock_start()
  for _ in 0..<1000 {
    ignore(@moonapp.reconcile(client, app.key()))
  }
  let elapsed = @bench.monotonic_clock_end(started)
  assert_eq(writes, fake.write_count())
  observations.push({
    "name": "moonapp_noop_fake_reconcile",
    "iterations": 1000,
    "total_us": elapsed,
    "mean_us": elapsed / 1000.0,
    "writes": fake.write_count() - writes,
  })
  let report : Json = {
    "toolchain": "0.10.17+d971670cd",
    "target": "native-release",
    "dataset_objects": 1000,
    "workers": 1,
    "platform": match @async.platform {
      Windows => "Windows"
      Linux => "Linux"
      MacOS => "MacOS"
    },
    "cpu": @env.get_env_var("PROCESSOR_IDENTIFIER").unwrap_or(
      "not exposed to process",
    ),
    "memory_measurement": "not measured; no RSS claim",
    "observations": observations,
  }
  @fs.write_file("benchmark-report.json", report.stringify(indent=2))
  println(report.stringify(indent=2))
}

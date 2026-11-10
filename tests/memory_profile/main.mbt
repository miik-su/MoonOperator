///|
async fn main {
  let args = @env.args()
  guard args.length() == 2 && ["operator", "10k"].contains(args[1]) else {
    fail("usage: memory_profile operator|10k")
  }
  let count = if args[1] == "operator" { 1024 } else { 10000 }
  let payload_size = if args[1] == "operator" { 7900 } else { 2048 }
  let limit = if args[1] == "operator" { 8388608 } else { 67108864 }
  let store = @cache.Store::new(
    capacity=count,
    max_bytes=limit,
    max_object_bytes=262144,
  )
  let memory = @process.memory()
  if @core.field(memory, "available") != Json::boolean(true) {
    fail("RSS profile requires Linux; unavailable is not a pass")
  }
  let stages : Array[Json] = [{ "stage": "start", "memory": memory }]
  let batch : Array[@core.Resource] = []
  let text = "x".repeat(payload_size)
  for i in 0..<count {
    batch.push(
      @core.Resource::from_json({
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {
          "name": "p\{i}",
          "namespace": "memory",
          "resourceVersion": "initial",
        },
        "data": { "payload": text + i.to_string() },
      }),
    )
  }
  let gvk = batch[0].key().gvk
  store.replace(gvk, batch)
  stages.push({
    "stage": "initial_snapshot",
    "encoded_bytes": store.bytes(),
    "memory": @process.memory(),
  })
  // Different immutable strings in both retained snapshots avoid an artificial
  // shared-template RSS result. Keep the old batch live during replacement.
  let next = batch.map(resource => {
    resource.with_field("data", {
      "payload": "new-" + text + resource.key().name,
    })
  })
  store.replace(gvk, next)
  stages.push({
    "stage": "old_new_snapshots_retained",
    "encoded_bytes": store.bytes(),
    "memory": @process.memory(),
  })
  assert_eq(batch.length(), count)
  batch.clear()
  stages.push({
    "stage": "old_batch_released_no_forced_gc",
    "memory": @process.memory(),
  })
  assert_eq(store.length(), count)
  let report : Json = {
    "profile": args[1],
    "objects": count,
    "payload_bytes": payload_size,
    "cache_limit_bytes": limit,
    "stages": stages,
    "gc_live_heap": "not available",
    "oom_claim": "process completed; container OOM result must be recorded by the caller",
  }
  @fs.write_file(
    "memory-" + args[1] + "-report.json",
    report.stringify(indent=2),
  )
  println(report.stringify(indent=2))
}

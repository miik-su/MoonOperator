///|
/// Separate consumer module: every framework call is a public API.
async fn main {
  let fake = @testing.Fake::new()
  let client = fake.client()
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "ConfigMap", },
    plural: "configmaps",
    scope: Namespaced,
  }
  let resource = client.create(
    kind,
    @core.Resource::from_json({
      "apiVersion": "v1",
      "kind": "ConfigMap",
      "metadata": {
        "name": "example",
        "namespace": "demo",
        "annotations": { "keep": "yes" },
      },
      "data": { "message": "synthetic example" },
    }),
  )
  let queue = @queue.Queue::new(capacity=16)
  let controller = @controller.Controller::new(queue, key => {
    let current = client.get(kind, key.ns, key.name) catch {
      @core.Api(404, _) => return Complete
      error => raise error
    }
    let annotations = match @core.field(current.metadata(), "annotations") {
      Object(fields) => fields
      _ => Map([])
    }
    if annotations.get("moonoperator.dev/example") !=
      Some(Json::string("managed")) {
      annotations["moonoperator.dev/example"] = Json::string("managed")
      ignore(
        client.update(
          kind,
          current.with_metadata("annotations", Json::object(annotations)),
        ),
      )
    }
    Complete
  })
  // A fresh duplicate event exercises idempotence, not only queue deduplication.
  for now in [0L, 1L] {
    queue.add(resource.key())
    assert_true(controller.step(now))
  }
  let current = client.get(kind, "demo", "example")
  assert_eq(
    @core.field(@core.field(current.metadata(), "annotations"), "keep"),
    "yes",
  )
  assert_eq(fake.write_count(), 2) // Initial create and one annotation update.
  assert_eq(queue.pending(), 0)
  let report : Json = {
    "consumer_module": "moonoperator-examples/consumer",
    "public_api_only": true,
    "reconcile_attempts": 2,
    "child_updates": 1,
    "unrelated_annotation_preserved": true,
    "pending": 0,
    "transport": "in-memory fake; no cluster or GC validation",
  }
  println(report.stringify())
}

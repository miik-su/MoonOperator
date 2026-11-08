///|
async test "finalizer is retained on failed cleanup and removed after success" {
  let fake = @testing.Fake::new()
  let client = fake.client()
  let kind : @core.ResourceType = {
    gvk: { group: "demo.dev", version: "v1", kind: "App", },
    plural: "apps",
    scope: Namespaced,
  }
  let created = client.create(
    kind,
    @core.Resource::from_json({
      "apiVersion": "demo.dev/v1",
      "kind": "App",
      "metadata": { "name": "x", "namespace": "demo" },
    }),
  )
  assert_false(
    @controller.finalize(client, kind, created, "demo.dev/cleanup", _ => true),
  )
  let live = client.get(kind, "demo", "x")
  assert_true(
    @controller.finalize(client, kind, live, "demo.dev/cleanup", _ => true),
  )
  let deleting = client.update(
    kind,
    live.with_metadata("deletionTimestamp", Json::string("now")),
  )
  assert_true(
    try
      @controller.finalize(client, kind, deleting, "demo.dev/cleanup", _ => {
        raise @core.Transport("cleanup unavailable")
      })
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    client.get(kind, "demo", "x").finalizers().contains("demo.dev/cleanup"),
  )
  assert_false(
    @controller.finalize(client, kind, deleting, "demo.dev/cleanup", _ => true),
  )
  assert_false(
    client.get(kind, "demo", "x").finalizers().contains("demo.dev/cleanup"),
  )
}

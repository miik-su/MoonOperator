///|
async test "merge PATCH removes fields preserves unknowns and guards RV" {
  let fake = @testing.Fake::new()
  let client = fake.client()
  let kind : @core.ResourceType = {
    gvk: { group: "demo.dev", version: "v1", kind: "App", },
    plural: "apps",
    scope: Namespaced,
  }
  let resource = client.create(
    kind,
    @core.Resource::from_json({
      "apiVersion": "demo.dev/v1",
      "kind": "App",
      "metadata": { "name": "x", "namespace": "demo" },
      "spec": { "remove": true, "keep": "unknown" },
    }),
  )
  let patch : Json = {
    "metadata": { "resourceVersion": resource.resource_version() },
    "spec": { "remove": null, "replicas": 2 },
  }
  let updated = client.patch(kind, "demo", "x", patch)
  assert_eq(@core.field(updated.json(), "spec"), {
    "keep": "unknown",
    "replicas": 2,
  })
  assert_true(
    try client.patch(kind, "demo", "x", patch) catch {
      @core.Api(409, _) => true
      _ => false
    } noraise {
      _ => false
    },
  )
}

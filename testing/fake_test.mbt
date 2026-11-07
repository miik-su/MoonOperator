///|
async test "fake API detects stale updates and isolates status writes" {
  let fake = @testing.Fake::new()
  let c = fake.client()
  let kind : @core.ResourceType = {
    gvk: { group: "demo.dev", version: "v1", kind: "App", },
    plural: "apps",
    scope: Namespaced,
  }
  let resource = @core.Resource::from_json({
    "apiVersion": "demo.dev/v1",
    "kind": "App",
    "metadata": { "name": "x", "namespace": "demo" },
    "spec": { "replicas": 1 },
  })
  let created = c.create(kind, resource)
  ignore(c.update(kind, created.with_field("spec", { "replicas": 2 })))
  assert_true(
    try c.update(kind, created) catch {
      @core.Api(409, _) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  fake.fail_next(429)
  assert_true(
    try c.get(kind, "demo", "x") catch {
      @core.Api(429, _) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(@core.field(c.get(kind, "demo", "x").json(), "spec"), {
    "replicas": 2,
  })
}

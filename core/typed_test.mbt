///|
struct AppSpec {
  replicas : Int32
} derive(FromJson)

///|
test "typed spec views retain unknown fields" {
  let resource = @core.Resource::from_json({
    "apiVersion": "demo.dev/v1",
    "kind": "App",
    "metadata": { "name": "x" },
    "spec": { "replicas": 3, "future": true },
  })
  let spec : AppSpec = resource.spec_as()
  assert_eq(spec.replicas, 3)
  assert_eq(
    @core.field(@core.field(resource.json(), "spec"), "future"),
    Json::boolean(true),
  )
}

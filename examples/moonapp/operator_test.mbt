///|
async test "MoonApp creates children idempotently and repairs deployment drift" {
  let fake = @testing.Fake::new()
  let client = fake.client()
  let app = client.create(
    @moonapp.app_type,
    @core.Resource::from_json({
      "apiVersion": "moonoperator.dev/v1",
      "kind": "MoonApp",
      "metadata": { "name": "demo", "namespace": "demo", "generation": 1 },
      "spec": { "image": "nginx:1.27", "replicas": 3 },
    }),
  )
  ignore(@moonapp.reconcile(client, app.key()))
  let writes = fake.write_count()
  ignore(@moonapp.reconcile(client, app.key()))
  assert_eq(fake.write_count(), writes)
  let deployment = client.get(@moonapp.deployment_type, "demo", "demo")
  let spec = @core.field(deployment.json(), "spec")
  if spec is Object(fields) {
    fields["replicas"] = Json::number(1.0)
  }
  ignore(
    client.update(@moonapp.deployment_type, deployment.with_field("spec", spec)),
  )
  ignore(@moonapp.reconcile(client, app.key()))
  assert_eq(
    @core.field(
      @core.field(
        client.get(@moonapp.deployment_type, "demo", "demo").json(),
        "spec",
      ),
      "replicas",
    ),
    Json::number(3.0),
  )
}

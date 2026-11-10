///|
async test "MoonApp refuses implicit adoption and preserves unrelated owners" {
  let fake = @testing.Fake::new()
  let client = fake.client()
  let app = client.create(
    @moonapp.app_type,
    @core.Resource::from_json({
      "apiVersion": "moonoperator.dev/v1",
      "kind": "MoonApp",
      "metadata": { "name": "demo", "namespace": "demo" },
      "spec": { "image": "nginx:1.27" },
    }),
  )
  let unowned = client.create(
    @moonapp.deployment_type,
    @core.Resource::from_json({
      "apiVersion": "apps/v1",
      "kind": "Deployment",
      "metadata": {
        "name": "demo",
        "namespace": "demo",
        "ownerReferences": [{ "uid": "other", "controller": false }],
      },
      "spec": { "replicas": 9 },
    }),
  )
  let writes = fake.write_count()
  assert_true(
    try @moonapp.reconcile(client, app.key()) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(fake.write_count(), writes + 1) // One safe status update; no child adoption.
  assert_eq(
    client.get(@moonapp.deployment_type, "demo", "demo").json(),
    unowned.json(),
  )
  ignore(@moonapp.reconcile(client, app.key(), adopt_unowned=true))
  let owned = client.get(@moonapp.deployment_type, "demo", "demo")
  guard @core.field(owned.metadata(), "ownerReferences") is Array(refs) else {
    fail("missing references")
  }
  assert_eq(refs.length(), 2)
  assert_true(refs.any(r => @core.field(r, "uid") == Json::string("other")))
  let writes = fake.write_count()
  ignore(@moonapp.reconcile(client, app.key()))
  assert_eq(fake.write_count(), writes)
  let foreign = owned.with_metadata("ownerReferences", [
    { "uid": "foreign-controller", "controller": true },
  ])
  ignore(client.update(@moonapp.deployment_type, foreign))
  let writes = fake.write_count()
  assert_true(
    try @moonapp.reconcile(client, app.key(), adopt_unowned=true) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(fake.write_count(), writes + 1) // Surface ownership failure through status.
}

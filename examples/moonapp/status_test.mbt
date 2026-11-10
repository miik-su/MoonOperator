///|
async test "schema and failure conditions agree without leaking payloads or claiming Ready" {
  assert_true(
    try @crd.validate(@moonapp.spec_schema(), { "image": "" }) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  let fake = @testing.Fake::new()
  let client = fake.client()
  let app = client.create(
    @moonapp.app_type,
    @core.Resource::from_json({
      "apiVersion": "moonoperator.dev/v1",
      "kind": "MoonApp",
      "metadata": { "name": "x", "namespace": "demo", "generation": 7 },
      "spec": { "image": "" },
    }),
  )
  assert_true(
    try @moonapp.reconcile(client, app.key()) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  let status = @core.field(
    client.get(@moonapp.app_type, "demo", "x").json(),
    "status",
  )
  assert_eq(@core.field(status, "observedGeneration"), 7)
  guard @core.field(status, "conditions") is Array(conditions) else {
    fail("missing conditions")
  }
  assert_true(
    conditions.any(c => {
      @core.field(c, "type") == Json::string("Accepted") &&
      @core.field(c, "status") == Json::string("False")
    }),
  )
  assert_true(
    conditions.any(c => {
      @core.field(c, "type") == Json::string("Ready") &&
      @core.field(c, "status") == Json::string("Unknown")
    }),
  )
  let writes = fake.write_count()
  ignore(@moonapp.reconcile(client, app.key())) catch {
    _ => ()
  }
  assert_eq(fake.write_count(), writes)
}

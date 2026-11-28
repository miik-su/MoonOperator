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

///|
async test "MoonApp preserves status fields and conditions it does not manage" {
  let fake = @testing.Fake::new()
  let client = fake.client()
  let app = client.create(
    @moonapp.app_type,
    @core.Resource::from_json({
      "apiVersion": "moonoperator.dev/v1",
      "kind": "MoonApp",
      "metadata": { "name": "demo", "namespace": "demo", "generation": 2 },
      "spec": { "image": "nginx:1.27" },
    }),
  )
  let external_condition : Json = { "type": "External", "status": "True" }
  ignore(
    client.update(
      @moonapp.app_type,
      app.with_field("status", {
        "external": { "revision": 3 },
        "conditions": [external_condition],
      }),
      status=true,
    ),
  )
  ignore(@moonapp.reconcile(client, app.key()))
  let status = @core.field(
    client.get(@moonapp.app_type, "demo", "demo").json(),
    "status",
  )
  assert_eq(@core.field(status, "external"), { "revision": 3 })
  assert_eq(@core.field(status, "observedGeneration"), 2)
  guard @core.field(status, "conditions") is Array(conditions) else {
    fail("missing conditions")
  }
  assert_true(conditions.any(condition => condition == external_condition))
  let writes = fake.write_count()
  ignore(@moonapp.reconcile(client, app.key()))
  assert_eq(fake.write_count(), writes)
}

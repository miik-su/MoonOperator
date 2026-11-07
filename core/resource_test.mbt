///|
test "resource preserves unknown fields and isolates JSON ownership" {
  let input : Json = {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
      "name": "demo",
      "namespace": "test",
      "resourceVersion": "opaque:rv",
    },
    "futureField": { "enabled": true },
  }
  let resource = @core.Resource::from_json(input)
  if input is Object(fields) {
    fields["futureField"] = Json::null()
  }
  assert_eq(@core.field(resource.json(), "futureField"), { "enabled": true })
  assert_eq(resource.key().gvk.group, "apps")
  assert_eq(resource.resource_version(), "opaque:rv")
  let updated = resource.with_metadata("labels", { "app": "demo" })
  assert_eq(@core.field(resource.metadata(), "labels"), Json::null())
  assert_eq(@core.field(updated.metadata(), "labels"), { "app": "demo" })
}

///|
test "invalid identities and duplicate registrations are rejected" {
  let bad = try @core.Resource::from_json({}) catch {
    _ => None
  } noraise {
    r => Some(r)
  }
  assert_true(bad is None)
  let registry = @core.Registry::new()
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Namespace", },
    plural: "namespaces",
    scope: Cluster,
  }
  registry.register(kind)
  assert_eq(registry.lookup(kind.gvk), Some(kind))
  let duplicate = try registry.register(kind) catch {
    _ => true
  } noraise {
    _ => false
  }
  assert_true(duplicate)
}

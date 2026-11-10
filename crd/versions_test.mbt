///|
test "CRD multiversion requires one storage version" {
  let kind : @core.ResourceType = {
    gvk: { group: "demo.dev", version: "v1", kind: "App", },
    plural: "apps",
    scope: Namespaced,
  }
  let v1 : @crd.Version = {
    name: "v1",
    schema: { "type": "object" },
    served: true,
    storage: true,
    status_subresource: true,
  }
  let v2 = { ..v1, name: "v2", storage: false, }
  let crd = @crd.definition_with_versions(kind, "app", [v1, v2])
  guard @core.field(@core.field(crd, "spec"), "versions") is Array(versions) else {
    fail("versions missing")
  }
  assert_eq(versions.length(), 2)
  let incompatible_schemas : Array[Json] = [
    { "type": "object", "properties": { "x": { "type": "integer" } } },
    {
      "type": "object",
      "properties": { "x": { "type": "string", "default": "different" } },
    },
  ]
  for incompatible in incompatible_schemas {
    assert_true(
      try
        @crd.definition_with_versions(kind, "app", [
          v1,
          { ..v2, schema: incompatible, },
        ])
      catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
  assert_true(
    try
      @crd.definition_with_versions(kind, "app", [v1, { ..v2, storage: true, }])
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    try
      @crd.validate({ "type": "string", "minLength": 1 }, Json::string(""))
    catch {
      _ => true
    } noraise {
      _ => false
    },
  )
}

///|
test "CRD generation rejects invalid registration and root schema before emission" {
  let kind : @core.ResourceType = {
    gvk: { group: "demo.dev", version: "v1", kind: "App", },
    plural: "apps",
    scope: Namespaced,
  }
  for singular in ["", "App", "1app", "app_thing", "app/thing", "app-"] {
    assert_true(
      try @crd.definition(kind, singular, { "type": "object" }) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
  for
    bad in [
      { ..kind, plural: "1apps", },
      { ..kind, gvk: { ..kind.gvk, group: "", }, },
      { ..kind, gvk: { ..kind.gvk, kind: "App_Thing", }, },
      { ..kind, gvk: { ..kind.gvk, kind: "A".repeat(60), }, },
    ] {
    assert_true(
      try @crd.definition(bad, "app", { "type": "object" }) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
  for schema in [Json::null(), { "type": "string" }, { "properties": {} }] {
    assert_true(
      try @crd.definition(kind, "app", schema) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
  let generated = @crd.definition(kind, "app", { "type": "object" })
  assert_eq(
    @core.field(@core.field(generated, "metadata"), "name"),
    "apps.demo.dev",
  )
}

///|
test "CRD validation checks every served version identifier" {
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
  assert_true(
    try
      @crd.definition_with_versions(kind, "app", [
        v1,
        { ..v1, name: "v2/bad", storage: false, },
      ])
    catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
}

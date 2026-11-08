///|
test "registry rejects malformed GVK and plural before publishing" {
  let valid : @core.ResourceType = {
    gvk: { group: "apps.example.dev", version: "v1alpha1", kind: "MoonApp", },
    plural: "moonapps",
    scope: Namespaced,
  }
  let registry = @core.Registry::new()
  for
    invalid in [
      { ..valid, gvk: { ..valid.gvk, group: "apps.*", }, },
      { ..valid, gvk: { ..valid.gvk, group: "apps..dev", }, },
      { ..valid, gvk: { ..valid.gvk, version: "../v1", }, },
      { ..valid, gvk: { ..valid.gvk, kind: "", }, },
      { ..valid, plural: "pods/status", },
      { ..valid, plural: "", },
    ] {
    assert_true(
      try registry.register(invalid) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
    assert_eq(registry.lookup(invalid.gvk), None)
  }
  registry.register(valid)
  assert_eq(registry.lookup(valid.gvk), Some(valid))
}

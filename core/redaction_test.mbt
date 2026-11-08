///|
test "resource debug never includes Secret or custom resource payloads" {
  for kind in ["Secret", "CustomCredentials"] {
    let r = @core.Resource::from_json({
      "apiVersion": "v1",
      "kind": kind,
      "metadata": { "name": "sensitive-name" },
      "data": { "token": "fixture-private-value" },
      "stringData": { "password": "fixture-password" },
    })
    let output = @debug.to_string(r)
    assert_true(output.contains("redacted"))
    for value in ["fixture-private-value", "fixture-password", "sensitive-name"] {
      assert_false(output.contains(value))
    }
    // Explicit JSON access is still available to application logic.
    assert_eq(
      @core.field(@core.field(r.json(), "data"), "token"),
      "fixture-private-value",
    )
  }
}

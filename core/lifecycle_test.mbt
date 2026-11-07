///|
test "finalizer updates preserve other controllers and are idempotent" {
  let r = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "x", "finalizers": ["other.dev/cleanup"] },
  })
  let r = r
    .set_finalizer("moonoperator.dev/cleanup", true)
    .set_finalizer("moonoperator.dev/cleanup", true)
  assert_eq(r.finalizers().length(), 2)
  assert_eq(r.set_finalizer("moonoperator.dev/cleanup", false).finalizers(), [
    "other.dev/cleanup",
  ])
}

///|
test "condition reason changes retain transition timestamp" {
  let conditions : Json = [
    { "type": "Ready", "status": "True", "lastTransitionTime": "old" },
  ]
  let result = @core.conditions_upsert(conditions, {
    "type": "Ready",
    "status": "True",
    "lastTransitionTime": "new",
    "reason": "Updated",
  })
  guard result is Array(items) else { fail("expected array") }
  assert_eq(@core.field(items[0], "lastTransitionTime"), Json::string("old"))
}

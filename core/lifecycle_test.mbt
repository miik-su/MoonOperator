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

///|
test "condition upsert repairs missing transition timestamps without losing other conditions" {
  let updated = @core.conditions_upsert(
    [
      { "type": "Ready", "status": "True", "lastTransitionTime": null },
      { "type": "External", "status": "True" },
    ],
    {
      "type": "Ready",
      "status": "True",
      "lastTransitionTime": "2026-11-28T00:00:00Z",
    },
  )
  guard updated is Array(items) else { fail("missing conditions") }
  assert_eq(items.length(), 2)
  assert_eq(@core.field(items[0], "type"), "External")
  assert_eq(@core.field(items[1], "lastTransitionTime"), "2026-11-28T00:00:00Z")
}

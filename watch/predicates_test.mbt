///|
test "generation predicate preserves cleanup transitions and filters status only" {
  let before = @core.Resource::from_json({
    "apiVersion": "demo.dev/v1",
    "kind": "App",
    "metadata": { "name": "x", "generation": 1, "resourceVersion": "a" },
  })
  let after = before
    .with_metadata("resourceVersion", Json::string("b"))
    .with_field("status", { "ready": true })
  assert_false(@watch.generation_changed(Some(before), Modified(after)))
  let recreated = before.with_metadata("uid", "new")
  assert_true(@watch.changed(Some(before), Modified(recreated)))
  assert_true(@watch.generation_changed(Some(before), Modified(recreated)))
  assert_true(
    @watch.generation_changed(
      Some(before),
      Modified(after.with_metadata("deletionTimestamp", Json::string("now"))),
    ),
  )
  assert_true(
    @watch.generation_changed(
      Some(before),
      Modified(after.with_metadata("generation", Json::number(2.0))),
    ),
  )
}

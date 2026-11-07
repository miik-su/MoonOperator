///|
test "cache atomically publishes snapshots and protects resource ownership" {
  let r = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "x" },
  })
  let store = @cache.Store::new(capacity=1)
  store.replace(r.key().gvk, [r])
  assert_true(store.ready(r.key().gvk))
  let second = r.with_metadata("name", Json::string("y"))
  assert_true(
    try store.replace(r.key().gvk, [r, second]) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(store.get(r.key()) is Some(_))
  assert_eq(store.list(r.key().gvk).length(), 1)
}

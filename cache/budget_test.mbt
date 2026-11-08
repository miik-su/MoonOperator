///|
test "byte budget is atomic and stale tombstones preserve accounting" {
  let r = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "x", "uid": "new" },
  })
  let size = r.byte_size()
  let store = @cache.Store::new(max_bytes=size + 1)
  store.replace(r.key().gvk, [r])
  let other = r.with_metadata("name", "y")
  assert_true(
    try store.replace(r.key().gvk, [r, other]) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_eq(store.bytes(), size)
  assert_true(store.get(r.key()) is Some(_))
  assert_true(
    try store.apply(Added(other)) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  store.apply(Deleted(r.with_metadata("uid", "old")))
  assert_eq(store.bytes(), size)
  store.apply(Deleted(r))
  assert_eq(store.bytes(), 0)
  store.apply(Added(other))
  assert_eq(store.bytes(), other.byte_size())
}

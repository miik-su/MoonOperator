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
  let larger = other.with_field("spec", { "extra": "longer data" })
  assert_true(
    try store.apply(Modified(larger)) catch {
      @core.CacheCapacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(store.bytes(), other.byte_size())
  assert_eq(store.get(other.key()).unwrap().json(), other.json())
  let tiny = @cache.Store::new(max_object_bytes=size - 1)
  assert_true(
    try tiny.replace(r.key().gvk, [r]) catch {
      @core.CacheCapacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(tiny.bytes(), 0)
  assert_false(tiny.ready(r.key().gvk))
  let invalid = @cache.Store::new(max_bytes=-1)
  assert_true(
    try invalid.replace(r.key().gvk, []) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
}

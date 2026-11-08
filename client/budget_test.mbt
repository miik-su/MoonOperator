///|
async test "LIST rejects snapshot bytes and objects without repeated page requests" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let object : Json = {
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "name": "x", "namespace": "demo" },
  }
  let size = @core.Resource::from_json(object).byte_size()
  let requests = Ref(0)
  let client = @client.Client::new(_ => {
    requests.val += 1
    {
      code: 200,
      body: { "metadata": { "resourceVersion": "snapshot" }, "items": [object] },
      retry_after_seconds: None,
    }
  })
  assert_true(
    try client.list(kind, "demo", max_bytes=size - 1) catch {
      @core.ListCapacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(requests.val, 1)
  assert_true(
    try client.list(kind, "demo", max_object_bytes=size - 1) catch {
      @core.ListCapacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(requests.val, 2)
  assert_eq(
    client.list(kind, "demo", max_bytes=size, max_object_bytes=size).items.length(),
    1,
  )
  assert_true(
    try client.list(kind, "demo", max_items=0) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(requests.val, 3)
}

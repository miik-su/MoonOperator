///|
async test "built-in LIST items inherit endpoint TypeMeta while preserving fields" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "ConfigMap", },
    plural: "configmaps",
    scope: Namespaced,
  }
  let client = @client.Client::new(_ => {
    code: 200,
    body: {
      "apiVersion": "v1",
      "kind": "ConfigMapList",
      "metadata": { "resourceVersion": "opaque" },
      "items": [
        {
          "metadata": { "name": "x", "namespace": "demo" },
          "data": { "future": "kept" },
        },
      ],
    },
    retry_after_seconds: None,
  })
  let page = client.list_page(kind, "demo")
  assert_eq(page.items[0].key().gvk, kind.gvk)
  assert_eq(@core.field(page.items[0].json(), "data"), { "future": "kept" })
  let mismatch = @client.Client::new(_ => {
    code: 200,
    body: {
      "metadata": { "resourceVersion": "opaque" },
      "items": [
        { "apiVersion": "v1", "kind": "Pod", "metadata": { "name": "x" } },
      ],
    },
    retry_after_seconds: None,
  })
  assert_true(
    try mismatch.list_page(kind, "demo") catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
}

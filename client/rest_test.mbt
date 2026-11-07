///|
test "REST paths scope and encode selectors and tokens" {
  let kind : @core.ResourceType = {
    gvk: { group: "apps", version: "v1", kind: "Deployment", },
    plural: "deployments",
    scope: Namespaced,
  }
  assert_eq(
    @client.object_path(kind, "demo", "web"),
    "/apis/apps/v1/namespaces/demo/deployments/web",
  )
  assert_true(
    @client.list_path(kind, "", continue_token="a+/=", labels="app=测试").contains(
      "continue=a%2B%2F%3D",
    ),
  )
  assert_eq(@client.encode("测试"), "%E6%B5%8B%E8%AF%95")
  let rejected = try @client.object_path(kind, "demo", "../secret") catch {
    _ => true
  } noraise {
    _ => false
  }
  assert_true(rejected)
}

///|
async test "client classifies errors and rejects unsafe update" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let client = @client.Client::new(_ => {
    code: 403,
    body: Json::null(),
    retry_after_seconds: None,
  })
  let forbidden = try client.get(kind, "demo", "web") catch {
    @core.Api(403, _) => true
    _ => false
  } noraise {
    _ => false
  }
  assert_true(forbidden)
  let resource = @core.Resource::from_json({
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": { "namespace": "demo", "name": "web" },
  })
  let invalid = try client.update(kind, resource) catch {
    @core.Invalid(_) => true
    _ => false
  } noraise {
    _ => false
  }
  assert_true(invalid)
}

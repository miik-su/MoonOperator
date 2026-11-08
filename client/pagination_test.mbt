///|
async test "LIST keeps opaque continuation and rejects inconsistent snapshots" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let requests : Array[String] = []
  let client = @client.Client::new(request => {
    requests.push(request.path)
    let body : Json = if requests.length() == 1 {
      {
        "metadata": { "resourceVersion": "snapshot", "continue": "opaque+/=" },
        "items": [],
      }
    } else {
      { "metadata": { "resourceVersion": "changed" }, "items": [] }
    }
    { code: 200, body, retry_after_seconds: None, }
  })
  assert_true(
    try client.list(kind, "demo") catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_true(requests[1].contains("continue=opaque%2B%2F%3D"))
}

///|
async test "server Retry-After delays the next request without replaying writes" {
  let calls = Ref(0)
  let times : Array[Int64] = []
  let client = @client.Client::new(_ => {
    calls.val += 1
    times.push(@async.now())
    {
      code: if calls.val == 1 {
        429
      } else {
        200
      },
      body: Json::null(),
      retry_after_seconds: Some(1),
    }
  })
  let request : @client.Request = {
    verb: "POST",
    path: "/test",
    body: Json::null(),
    content_type: "application/json",
  }
  ignore(client.execute(request)) catch {
    @core.Api(429, _) => ()
    error => raise error
  }
  ignore(client.execute(request))
  assert_eq(calls.val, 2)
  assert_true(times[1] - times[0] >= 900L)
}

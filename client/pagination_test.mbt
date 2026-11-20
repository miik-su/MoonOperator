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
async test "LIST rejects malformed cursor, foreign namespace and duplicate keys across pages" {
  let kind : @core.ResourceType = {
    gvk: { group: "", version: "v1", kind: "Pod", },
    plural: "pods",
    scope: Namespaced,
  }
  let item : Json = { "metadata": { "name": "sample", "namespace": "demo" } }
  let malformed : Array[Json] = [
    {
      "metadata": { "resourceVersion": "opaque", "continue": 7 },
      "items": [item],
    },
    {
      "metadata": { "resourceVersion": "opaque", "continue": null },
      "items": [item],
    },
    { "metadata": { "resourceVersion": 7 }, "items": [item] },
    {
      "metadata": { "resourceVersion": "opaque" },
      "items": [{ "metadata": { "name": "sample", "namespace": "other" } }],
    },
  ]
  for body in malformed {
    let client = @client.Client::new(_ => {
      code: 200,
      body,
      retry_after_seconds: None,
    })
    assert_true(
      try client.list_page(kind, "demo") catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
  let requests = Ref(0)
  let client = @client.Client::new(_ => {
    requests.val += 1
    let next = if requests.val == 1 { "second" } else { "" }
    {
      code: 200,
      body: {
        "metadata": { "resourceVersion": "opaque", "continue": next },
        "items": [item],
      },
      retry_after_seconds: None,
    }
  })
  assert_true(
    try client.list(kind, "demo") catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  assert_eq(requests.val, 2)
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

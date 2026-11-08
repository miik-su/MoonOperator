///|
async test "unsafe raw targets and oversized writes fail before credential IO" {
  let config = @transport.Config::new(
    "https://api.example",
    token_file="missing-token",
    max_request_bytes=32,
  )
  for
    path in [
      "https://other.example/", "//other.example/", "/x\r\nInjected: yes", "/x\u0000",
    ] {
    assert_true(
      try
        config.send({
          verb: "GET",
          path,
          body: Json::null(),
          content_type: "application/json",
        })
      catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
  assert_true(
    try
      config.send({
        verb: "POST",
        path: "/api",
        body: Json::string(String::make(100, 'x')),
        content_type: "application/json",
      })
    catch {
      @core.Capacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
}

///|
async test "cross-origin redirects never open the target connection" {
  let origin = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer origin.close()
  let target = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
  defer target.close()
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      let (conn, _) = origin.accept()
      defer conn.close()
      let request = conn.read_request()
      assert_eq(request.headers.get("Authorization"), Some("Bearer test-token"))
      conn.skip_request_body()
      conn.send_response(302, "Found", extra_headers={
        "Location": "http://127.0.0.1:\{target.addr.port()}/steal",
      })
      conn.end_response()
    })
    let client = @transport.Config::new(
      "http://127.0.0.1:\{origin.addr.port()}",
      token="test-token",
      allow_loopback_http=true,
    ).client()
    assert_true(
      try
        client.execute({
          verb: "GET",
          path: "/",
          body: Json::null(),
          content_type: "application/json",
        })
      catch {
        @core.Api(302, _) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  })
  assert_true(@async.with_timeout_opt(100, () => target.accept()) is None)
}

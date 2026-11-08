///|
async test "non-JSON proxy errors preserve HTTP status classification" {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      let (conn, _) = server.accept()
      defer conn.close()
      ignore(conn.read_request())
      conn.skip_request_body()
      conn.send_response(503, "Unavailable")
      conn.write("<html>proxy temporarily unavailable</html>")
      conn.end_response()
    })
    let client = @transport.Config::new(
      "http://127.0.0.1:\{server.addr.port()}",
      allow_loopback_http=true,
    ).client()
    let request : @client.Request = {
      verb: "GET",
      path: "/",
      body: Json::null(),
      content_type: "application/json",
    }
    assert_true(
      try client.execute(request) catch {
        @core.Api(503, _) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  })
}

///|
async test "HTTP body limit stops oversized response before JSON decoding" {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      let (conn, _) = server.accept()
      defer conn.close()
      ignore(conn.read_request())
      conn.skip_request_body()
      conn.send_response(200, "OK")
      conn.write("12345678901234567890")
      conn.end_response()
    })
    let config = @transport.Config::new(
      "http://127.0.0.1:\{server.addr.port()}",
      allow_loopback_http=true,
      max_response_bytes=8,
    )
    assert_true(
      try
        config.send({
          verb: "GET",
          path: "/",
          body: Json::null(),
          content_type: "application/json",
        })
      catch {
        @core.Capacity(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  })
}

///|
async test "HTTP transport sends bearer headers and parses a real loopback response" {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      let (conn, _) = server.accept()
      defer conn.close()
      let request = conn.read_request()
      assert_eq(request.headers.get("Authorization"), Some("Bearer test-token"))
      assert_eq(request.path, "/api/v1/namespaces")
      conn.skip_request_body()
      conn.send_response(200, "OK")
      conn.write("{\"items\":[]}")
      conn.end_response()
    })
    let config = @transport.Config::new(
      "http://127.0.0.1:\{server.addr.port()}",
      token="test-token",
      allow_loopback_http=true,
    )
    let response = config.send({
      verb: "GET",
      path: "/api/v1/namespaces",
      body: Json::null(),
      content_type: "application/json",
    })
    assert_eq(response.code, 200)
    assert_eq(response.body, { "items": [] })
  })
}

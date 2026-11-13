///|
async test "projected token rotation recovers from a simulated expired-token 401" {
  @fs.mkdir("_build/auth-fixtures", recursive=true, allow_exist=true)
  let path = "_build/auth-fixtures/token"
  @fs.write_file(path, "expired-fixture")
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      for
        (expected, status) in [
          ("Bearer expired-fixture", 401),
          ("Bearer rotated-fixture", 200),
        ] {
        let (conn, _) = server.accept()
        defer conn.close()
        let request = conn.read_request()
        assert_eq(request.headers.get("Authorization"), Some(expected))
        conn.send_response(
          status,
          if status == 200 {
            "OK"
          } else {
            "Unauthorized"
          },
        )
        conn.write("{}")
        conn.end_response()
      }
    })
    let client = @transport.Config::new(
      "http://127.0.0.1:\{server.addr.port()}",
      token_file=path,
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
        @core.Api(401, _) => true
        _ => false
      } noraise {
        _ => false
      },
    )
    @fs.write_file(path, "rotated-fixture")
    assert_eq(client.execute(request).code, 200)
  })
}

///|
async test "cancelled HTTP request closes the underlying peer connection" {
  let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
  defer server.close()
  let closed = Ref(false)
  @async.with_timeout(2000, () => {
    @async.with_task_group(group => {
      group.spawn_bg(() => {
        let (peer, _) = server.accept()
        defer peer.close()
        ignore(peer.read_until("\r\n\r\n"))
        closed.val = peer.read_some() is None
      })
      let config = @transport.Config::new(
        "http://127.0.0.1:\{server.addr.port()}",
        allow_loopback_http=true,
        timeout_ms=1500,
      )
      let cancelled = try
        @async.with_timeout(50, () => {
          config.send({
            verb: "GET",
            path: "/",
            body: Json::null(),
            content_type: "application/json",
          })
        })
      catch {
        @async.TimeoutError => true
        _ => false
      } noraise {
        _ => false
      }
      assert_true(cancelled)
    })
  })
  assert_true(closed.val)
}

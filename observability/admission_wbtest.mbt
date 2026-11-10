///|
async test "slow diagnostic connections release capacity and requests are rate bounded" {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  let metrics = Metrics::new()
  @async.with_timeout(2000, () => {
    @async.with_task_group(group => {
      group.spawn_bg(() => {
        serve_on(
          server,
          () => true,
          () => 0,
          metrics~,
          request_timeout_ms=30,
          max_connections=2,
          requests_per_second=1,
        )
      })
      let a = @socket.Tcp::connect(server.addr)
      defer a.close()
      let b = @socket.Tcp::connect(server.addr)
      defer b.close()
      a.write("GET /metrics HTTP/1.1\r\n")
      b.write("GET /metrics HTTP/1.1\r\n")
      @async.sleep(80)
      let url = "http://127.0.0.1:\{server.addr.port()}/metrics"
      let (response, _) = @http.get(url)
      assert_eq(response.code, 200)
      let (response, _) = @http.get(url)
      assert_eq(response.code, 429)
      assert_eq(metrics.count("diagnostic_timeout"), 2L)
      assert_eq(metrics.count("diagnostic_rate_limited"), 1L)
      group.return_immediately(())
    })
  })
}

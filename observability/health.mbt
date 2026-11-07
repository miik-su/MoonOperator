///|
/// Low-cardinality metrics; resource names and credentials never enter labels.
pub fn route(
  path : String,
  ready : Bool,
  queue_depth : Int32,
) -> (Int32, String) {
  match path {
    "/healthz" => (200, "ok\n")
    "/readyz" =>
      if ready {
        (200, "ready\n")
      } else {
        (503, "cache not synchronized\n")
      }
    "/metrics" =>
      (
        200,
        "# TYPE moonoperator_queue_depth gauge\nmoonoperator_queue_depth \{queue_depth}\n# TYPE moonoperator_cache_synced gauge\nmoonoperator_cache_synced \{if ready { 1 } else { 0 }}\n",
      )
    _ => (404, "not found\n")
  }
}

///|
pub async fn serve(
  address : String,
  ready : () -> Bool,
  queue_depth : () -> Int32,
) -> Unit {
  let server = @http.Server(@socket.Addr::parse(address))
  defer server.close()
  server.run_forever(
    (request, _, conn) => {
      let (code, body) = route(request.path, ready(), queue_depth())
      conn.send_response(code, if code == 200 { "OK" } else { "Unavailable" }, extra_headers={
        "Content-Type": "text/plain; charset=utf-8",
      })
      conn.write(body)
      conn.end_response()
    },
    max_connections=32,
  )
}

///|
/// Low-cardinality metrics; resource names and credentials never enter labels.
pub fn route(
  path : String,
  ready : Bool,
  queue_depth : Int32,
  cache_objects~ : Int32 = 0,
  cache_bytes~ : Int32 = 0,
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
        "# TYPE moonoperator_queue_depth gauge\nmoonoperator_queue_depth \{queue_depth}\n# TYPE moonoperator_cache_synced gauge\nmoonoperator_cache_synced \{if ready { 1 } else { 0 }}\n# TYPE moonoperator_cache_objects gauge\nmoonoperator_cache_objects \{cache_objects}\n# TYPE moonoperator_cache_encoded_bytes gauge\nmoonoperator_cache_encoded_bytes \{cache_bytes}\n",
      )
    _ => (404, "not found\n")
  }
}

///|
pub async fn serve(
  address : String,
  ready : () -> Bool,
  queue_depth : () -> Int32,
  metrics~ : Metrics = Metrics::new(),
  cache_objects~ : () -> Int32 = () => 0,
  cache_bytes~ : () -> Int32 = () => 0,
) -> Unit {
  let server = @http.Server(@socket.Addr::parse(address))
  defer server.close()
  server.run_forever(
    (request, _, conn) => {
      let (code, body) = route(
        request.path,
        ready(),
        queue_depth(),
        cache_objects=cache_objects(),
        cache_bytes=cache_bytes(),
      )
      let body = if request.path == "/metrics" {
        body + metrics.prometheus()
      } else {
        body
      }
      conn.send_response(code, if code == 200 { "OK" } else { "Unavailable" }, extra_headers={
        "Content-Type": "text/plain; charset=utf-8",
      })
      conn.write(body)
      conn.end_response()
    },
    max_connections=32,
  )
}

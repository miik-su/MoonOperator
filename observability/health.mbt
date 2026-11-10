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
  request_timeout_ms~ : Int32 = 2000,
  max_connections~ : Int32 = 32,
  requests_per_second~ : Int32 = 100,
  progress~ : () -> String = () => "",
) -> Unit {
  let server = @http.Server(@socket.Addr::parse(address))
  serve_on(
    server,
    ready,
    queue_depth,
    metrics~,
    cache_objects~,
    cache_bytes~,
    request_timeout_ms~,
    max_connections~,
    requests_per_second~,
    progress~,
  )
}

///|
async fn serve_on(
  server : @http.Server,
  ready : () -> Bool,
  queue_depth : () -> Int32,
  metrics~ : Metrics = Metrics::new(),
  cache_objects~ : () -> Int32 = () => 0,
  cache_bytes~ : () -> Int32 = () => 0,
  request_timeout_ms~ : Int32 = 2000,
  max_connections~ : Int32 = 32,
  requests_per_second~ : Int32 = 100,
  progress~ : () -> String = () => "",
) -> Unit {
  defer server.close()
  if request_timeout_ms <= 0 ||
    request_timeout_ms > 60000 ||
    max_connections <= 0 ||
    max_connections > 128 ||
    requests_per_second <= 0 ||
    requests_per_second > 10000 {
    fail("invalid diagnostics admission limits")
  }
  let budget = RequestBudget::{
    start: @async.now(),
    count: 0,
    limit: requests_per_second,
  }
  let active = Ref(0)
  @async.with_task_group(group => {
    for ;; {
      while active.val >= max_connections {
        @async.sleep(1)
      }
      let (conn, _) = server.accept()
      active.val += 1
      group.spawn_bg(() => {
        defer conn.close()
        defer {
          active.val -= 1
        }
        @async.with_timeout(request_timeout_ms, () => {
          let request = conn.read_request()
          if !budget.admit(@async.now()) {
            metrics.increment("diagnostic_rate_limited")
            conn.send_response(429, "Too Many Requests", extra_headers={
              "Connection": "close",
            })
            conn.end_response()
            return
          }
          if request.meth != Get {
            conn.send_response(405, "Method Not Allowed", extra_headers={
              "Connection": "close",
              "Allow": "GET",
            })
            conn.end_response()
            return
          }
          let (code, body) = route(
            request.path,
            ready(),
            queue_depth(),
            cache_objects=cache_objects(),
            cache_bytes=cache_bytes(),
          )
          let body = if request.path == "/metrics" {
            body + metrics.prometheus() + progress()
          } else {
            body
          }
          conn.send_response(
            code,
            if code == 200 {
              "OK"
            } else {
              "Unavailable"
            },
            extra_headers={
              "Content-Type": "text/plain; charset=utf-8",
              "Connection": "close",
            },
          )
          conn.write(body)
          conn.end_response()
        }) catch {
          @async.TimeoutError => metrics.increment("diagnostic_timeout")
          _ => ()
        }
      })
    }
  })
}

///|
priv struct RequestBudget {
  mut start : Int64
  mut count : Int32
  limit : Int32
}

///|
fn RequestBudget::admit(self : RequestBudget, now : Int64) -> Bool {
  if now - self.start >= 1000L {
    self.start = now
    self.count = 0
  }
  if self.count >= self.limit {
    return false
  }
  self.count += 1
  true
}

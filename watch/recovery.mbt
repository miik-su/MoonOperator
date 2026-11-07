///|
pub struct State {
  mut rv : String
  mut relist : Bool
  mut failures : Int32
}

///|
pub fn State::new() -> State {
  { rv: "", relist: true, failures: 0, }
}

///|
pub fn State::needs_list(self : State) -> Bool {
  self.relist
}

///|
pub fn State::version(self : State) -> String {
  self.rv
}

///|
/// Only a successfully installed complete LIST may unlock watching.
pub fn State::listed(
  self : State,
  rv : String,
) -> Unit raise @core.OperatorError {
  if rv.is_empty() {
    raise @core.Invalid("LIST resourceVersion required")
  }
  self.rv = rv
  self.relist = false
}

///|
/// Called after cache/queue acceptance, so failed delivery never advances RV.
pub fn State::checkpoint(self : State, event : Event) -> Unit {
  let rv = event.version()
  if !rv.is_empty() {
    self.rv = rv
    self.failures = 0
  }
}

///|
/// Capped exponential delay with caller-supplied random sample in 0..1000.
pub fn State::disconnected(self : State, code : Int32, jitter : Int32) -> Int32 {
  if code == 410 {
    self.rv = ""
    self.relist = true
  }
  let exponent = if self.failures > 8 { 8 } else { self.failures }
  let base = 100 * (1 << exponent)
  self.failures = if self.failures < 9 { self.failures + 1 } else { 9 }
  let sample = if jitter < 0 {
    0
  } else if jitter > 1000 {
    1000
  } else {
    jitter
  }
  base + base * sample / 5000
}

///|
pub fn watch_path(
  kind : @core.ResourceType,
  ns : String,
  rv : String,
  labels~ : String = "",
  fields~ : String = "",
) -> String raise @core.OperatorError {
  if rv.is_empty() {
    raise @core.Invalid("WATCH requires initial LIST")
  }
  @client.collection_path(kind, ns) +
  "?watch=true&allowWatchBookmarks=true&timeoutSeconds=60&resourceVersion=" +
  @client.encode(rv) +
  "&labelSelector=" +
  @client.encode(labels) +
  "&fieldSelector=" +
  @client.encode(fields)
}

///|
/// One bounded watch session. Cancellation closes its connection immediately.
pub async fn stream(
  config : @transport.Config,
  path : String,
  on_event : async (Event) -> Unit,
) -> Unit {
  let (response, conn) = config.open({
    verb: "GET",
    path,
    body: Json::null(),
    content_type: "application/json",
  })
  defer conn.close()
  if response.code != 200 {
    raise @core.Api(response.code, "WatchRequestFailed")
  }
  let parser = Parser::new()
  for ;; {
    let chunk = @async.with_timeout(75000, () => conn.read_some(max_len=8192))
    match chunk {
      None => {
        parser.finish()
        break
      }
      Some(chunk) =>
        for event in parser.feed(chunk) {
          match event {
            Failure(code) => raise @core.Api(code, "WatchStatusError")
            _ => on_event(event)
          }
        }
    }
  }
}

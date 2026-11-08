///|
/// Closed event vocabulary excludes raw errors, credentials and request bodies.
pub(all) enum LogEvent {
  ReconcileFailure
  WatchReconnect
  CacheSynchronized
}

///|
pub struct Logger {
  sink : (Json) -> Unit
}

///|
pub fn Logger::new(sink : (Json) -> Unit) -> Logger {
  { sink, }
}

///|
pub fn Logger::silent() -> Logger {
  Logger::new(_ => ())
}

///|
pub fn Logger::stdout() -> Logger {
  Logger::new(record => println(record.stringify()))
}

///|
pub fn Logger::emit(self : Logger, event : LogEvent, code~ : Int32 = 0) -> Unit {
  let (name, level) = match event {
    ReconcileFailure => ("reconcile_failure", "error")
    WatchReconnect => ("watch_reconnect", "warning")
    CacheSynchronized => ("cache_synchronized", "info")
  }
  let record : Json = {
    "component": "moonoperator",
    "event": name,
    "level": level,
    "httpCode": code,
  }
  (self.sink)(record)
}

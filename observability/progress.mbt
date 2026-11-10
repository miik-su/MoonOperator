///|
pub struct Progress {
  mut last_list : Int64?
  mut last_event : Int64?
  mut disconnected_since : Int64?
  mut connected : Bool
}

///|
pub fn Progress::new() -> Progress {
  {
    last_list: None,
    last_event: None,
    disconnected_since: None,
    connected: false,
  }
}

///|
pub fn Progress::listed(self : Progress, now : Int64) -> Unit {
  self.last_list = Some(now)
}

///|
pub fn Progress::opened(self : Progress) -> Unit {
  self.connected = true
  self.disconnected_since = None
}

///|
pub fn Progress::event(self : Progress, now : Int64) -> Unit {
  self.last_event = Some(now)
  self.opened()
}

///|
pub fn Progress::disconnected(self : Progress, now : Int64) -> Unit {
  self.connected = false
  if self.disconnected_since is None {
    self.disconnected_since = Some(now)
  }
}

///|
/// Optional readiness degradation for a sustained known disconnect, not for an
/// otherwise quiet healthy watch. Zero disables this additional threshold.
pub fn Progress::fresh(
  self : Progress,
  now : Int64,
  max_disconnected_ms : Int32,
) -> Bool {
  max_disconnected_ms <= 0 ||
  (match self.disconnected_since {
    None => true
    Some(at) => now - at <= max_disconnected_ms.to_int64()
  })
}

///|
pub fn Progress::prometheus(self : Progress, now : Int64) -> String {
  fn age(value : Int64?, now : Int64) -> String {
    match value {
      None => "-1"
      Some(at) => Int64::max(0L, now - at).to_string()
    }
  }
  "# TYPE moonoperator_watch_connected gauge\nmoonoperator_watch_connected \{if self.connected { 1 } else { 0 }}\n# TYPE moonoperator_last_list_age_ms gauge\nmoonoperator_last_list_age_ms \{age(self.last_list, now)}\n# TYPE moonoperator_last_watch_event_age_ms gauge\nmoonoperator_last_watch_event_age_ms \{age(self.last_event, now)}\n# TYPE moonoperator_watch_disconnected_ms gauge\nmoonoperator_watch_disconnected_ms \{if self.connected { "0" } else { age(self.disconnected_since, now) }}\n"
}

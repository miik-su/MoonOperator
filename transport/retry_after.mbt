///|
fn decimal(value : String) -> Int32? {
  if value.is_empty() ||
    value.length() > 4 ||
    !value.all(c => c >= '0' && c <= '9') {
    return None
  }
  let mut n = 0
  for c in value {
    n = n * 10 + c.to_int() - 48
  }
  Some(n)
}

///|
/// Delay-seconds and HTTP dates (IMF-fixdate, obsolete RFC850/asctime). Invalid
/// headers are ignored; past dates yield zero; all waits cap at one hour.
pub fn retry_after(value : String, now_unix_seconds~ : Int64) -> Int32? {
  let value = value.trim().to_owned()
  if value.is_empty() || value.length() > 128 {
    return None
  }
  if value.all(c => c >= '0' && c <= '9') {
    let mut n = 0
    for c in value {
      n = Int32::min(3600, n * 10 + c.to_int() - 48)
    }
    return Some(n)
  }
  let parts = value
    .split(" ")
    .filter(s => !s.is_empty())
    .map(s => s.to_owned())
    .collect()
  let (weekday, day, month, year, time) = match parts {
    [weekday, day, month, year, time, "GMT"] if weekday.has_suffix(",") =>
      (weekday.trim_end(chars=",").to_owned(), day, month, year, time)
    [weekday, date, time, "GMT"] if weekday.has_suffix(",") => {
      let pieces = date.split("-").map(s => s.to_owned()).collect()
      guard pieces is [day, month, year] && year.length() == 2 else {
        return None
      }
      guard decimal(year) is Some(two) else { return None }
      let current = @core.rfc3339(now_unix_seconds) catch { _ => return None }
      guard decimal(current[:4].to_owned()) is Some(current_year) else {
        return None
      }
      let candidate = current_year / 100 * 100 + two
      let resolved = if candidate > current_year + 50 {
        candidate - 100
      } else {
        candidate
      }
      (
        weekday.trim_end(chars=",").to_owned(),
        day,
        month,
        resolved.to_string(),
        time,
      )
    }
    [weekday, month, day, time, year] => (weekday, day, month, year, time)
    _ => return None
  }
  if ![
      "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Monday", "Tuesday", "Wednesday",
      "Thursday", "Friday", "Saturday", "Sunday",
    ].contains(weekday) {
    return None
  }
  let months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov",
    "Dec",
  ]
  let mut m = 0
  for index, name in months {
    if name == month {
      m = index + 1
    }
  }
  guard decimal(year) is Some(y) &&
    year.length() == 4 &&
    decimal(day) is Some(d) else {
    return None
  }
  let clock = time.split(":").map(s => s.to_owned()).collect()
  guard clock is [hh, mm, ss] &&
    hh.length() == 2 &&
    mm.length() == 2 &&
    ss.length() == 2 else {
    return None
  }
  guard decimal(hh) is Some(h) &&
    decimal(mm) is Some(minute) &&
    decimal(ss) is Some(s) else {
    return None
  }
  guard @core.unix_seconds(y, m, d, h, minute, s) is Some(target) else {
    return None
  }
  if target <= now_unix_seconds {
    Some(0)
  } else {
    Some(Int64::min(3600L, target - now_unix_seconds).to_int())
  }
}

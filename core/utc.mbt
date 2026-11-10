///|
fn leap(year : Int32) -> Bool {
  year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

///|
fn month_days(year : Int32, month : Int32) -> Int32 {
  if month == 2 {
    if leap(year) {
      29
    } else {
      28
    }
  } else if [4, 6, 9, 11].contains(month) {
    30
  } else {
    31
  }
}

///|
/// UTC civil time, bounded to Unix epoch through year 9999. Leap seconds are
/// deliberately rejected rather than normalized silently.
pub fn unix_seconds(
  year : Int32,
  month : Int32,
  day : Int32,
  hour : Int32,
  minute : Int32,
  second : Int32,
) -> Int64? {
  if year < 1970 ||
    year > 9999 ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > month_days(year, month) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59 ||
    second < 0 ||
    second > 59 {
    return None
  }
  let mut days = 0
  for y in 1970..<year {
    days += if leap(y) { 366 } else { 365 }
  }
  for m in 1..<month {
    days += month_days(year, m)
  }
  Some(
    (days + day - 1).to_int64() * 86400L +
    (hour * 3600 + minute * 60 + second).to_int64(),
  )
}

///|
pub fn rfc3339(seconds : Int64) -> String raise OperatorError {
  if seconds < 0L || seconds > 253402300799L {
    raise Invalid("UTC timestamp outside supported range")
  }
  let mut days = (seconds / 86400L).to_int()
  let mut year = 1970
  while days >= (if leap(year) { 366 } else { 365 }) {
    days -= if leap(year) { 366 } else { 365 }
    year += 1
  }
  let mut month = 1
  while days >= month_days(year, month) {
    days -= month_days(year, month)
    month += 1
  }
  let rest = (seconds % 86400L).to_int()
  fn two(n : Int32) -> String {
    if n < 10 {
      "0" + n.to_string()
    } else {
      n.to_string()
    }
  }
  year.to_string() +
  "-" +
  two(month) +
  "-" +
  two(days + 1) +
  "T" +
  two(rest / 3600) +
  ":" +
  two(rest / 60 % 60) +
  ":" +
  two(rest % 60) +
  "Z"
}

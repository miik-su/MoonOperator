///|
/// Linux kernel process accounting. VmHWM is cumulative since process start,
/// not a per-stage peak or a GC live-heap statistic.
pub async fn memory() -> Json {
  guard @async.platform is Linux else {
    return {
      "available": false,
      "reason": "Linux /proc process accounting is required",
    }
  }
  let text = @fs.read_file("/proc/self/status").text()
  let values : Map[String, Json] = {
    "available": Json::boolean(true),
    "unit": Json::string("KiB"),
    "scope": Json::string(
      "this process; peak is since process start; no GC live-heap measurement",
    ),
  }
  for (name, output) in [("VmRSS:", "rss_kib"), ("VmHWM:", "peak_rss_kib")] {
    let mut found = false
    for line in text.split("\n") {
      if line.strip_prefix(name) is Some(value) {
        let tokens = value
          .trim()
          .split(" ")
          .filter(s => !s.is_empty())
          .collect()
        guard tokens is [number, "kB"] else {
          fail("unexpected proc memory unit")
        }
        let value = @json.parse(number.to_owned())
        guard value is Number(n, ..) && n > 0.0 else {
          fail("invalid proc memory sample")
        }
        values[output] = value
        found = true
      }
    }
    guard found else { fail("kernel memory metric missing") }
  }
  Json::object(values)
}

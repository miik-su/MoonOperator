///|
async fn main {
  let rows : Array[Json] = []
  for count in [1000, 10000, 50000] {
    let q = @queue.Queue::new(capacity=count)
    let keys : Array[@core.Key] = []
    for i in 0..<count {
      keys.push({
        gvk: { group: "", version: "v1", kind: "Pod", },
        ns: "scale",
        name: i.to_string(),
      })
    }
    for mode in ["ready_fifo", "delayed_heap"] {
      let started = @bench.monotonic_clock_start()
      for i, key in keys {
        if mode == "ready_fifo" {
          q.add(key)
        } else {
          q.add_after(key, i.to_int64() + 1L)
        }
      }
      let setup_us = @bench.monotonic_clock_end(started)
      let poll = @bench.monotonic_clock_start()
      if mode == "delayed_heap" {
        for _ in 0..<1000 {
          assert_eq(q.get(0L), None)
        }
      }
      let poll_us = @bench.monotonic_clock_end(poll)
      let samples : Array[Double] = []
      let drain = @bench.monotonic_clock_start()
      for i in 0..<count {
        let at = @bench.monotonic_clock_start()
        assert_eq(q.get(i.to_int64() + 1L), Some(keys[i]))
        q.done(keys[i])
        samples.push(@bench.monotonic_clock_end(at))
      }
      let drain_us = @bench.monotonic_clock_end(drain)
      assert_eq(q.pending(), 0)
      samples.sort()
      rows.push({
        "keys": count,
        "mode": mode,
        "setup_us": setup_us,
        "drain_us": drain_us,
        "mean_claim_done_us": drain_us / count.to_double(),
        "p95_claim_done_us": samples[(count * 95 + 99) / 100 - 1],
        "p99_claim_done_us": samples[(count * 99 + 99) / 100 - 1],
        "not_due_poll_count": if mode == "delayed_heap" {
          1000
        } else {
          0
        },
        "not_due_poll_us": poll_us,
        "memory_at_end": @process.memory(),
      })
    }
  }
  let report : Json = {
    "measurement": "single process; operation latency includes clock/assertion overhead, not end-to-end reconcile or intentional timer delay",
    "observations": rows,
  }
  @fs.write_file("queue-scale-report.json", report.stringify(indent=2))
  println(report.stringify(indent=2))
}

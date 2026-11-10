///|
test "Retry-After supports dates and strict bounded seconds" {
  let now = @core.unix_seconds(1994, 11, 6, 8, 49, 0).unwrap()
  for
    value in [
      "Sun, 06 Nov 1994 08:49:37 GMT", "Sunday, 06-Nov-94 08:49:37 GMT", "Sun Nov  6 08:49:37 1994",
    ] {
    assert_eq(@transport.retry_after(value, now_unix_seconds=now), Some(37))
  }
  assert_eq(
    @transport.retry_after(
      "Sun, 06 Nov 1994 08:48:00 GMT",
      now_unix_seconds=now,
    ),
    Some(0),
  )
  assert_eq(
    @transport.retry_after("999999999999999999999", now_unix_seconds=now),
    Some(3600),
  )
  for
    value in [
      "-1", "+1", "1.5", "1e2", "Sun, 31 Feb 1994 08:49:37 GMT", "Sun, 06 Nov 1994 08:49:37 PST",
    ] {
    assert_eq(@transport.retry_after(value, now_unix_seconds=now), None)
  }
}

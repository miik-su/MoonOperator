///|
test "UTC bounds and leap day conversion" {
  assert_eq(@core.rfc3339(0L), "1970-01-01T00:00:00Z")
  assert_eq(
    @core.rfc3339(@core.unix_seconds(2000, 2, 29, 23, 59, 59).unwrap()),
    "2000-02-29T23:59:59Z",
  )
  assert_eq(@core.unix_seconds(2100, 2, 29, 0, 0, 0), None)
  assert_eq(@core.rfc3339(253402300799L), "9999-12-31T23:59:59Z")
}

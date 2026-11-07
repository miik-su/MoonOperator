///|
test "watch framing handles every byte boundary including UTF8" {
  let parser = @watch.Parser::new()
  let input = @utf8.encode(
    "{\"type\":\"ADDED\",\"object\":{\"apiVersion\":\"v1\",\"kind\":\"Pod\",\"metadata\":{\"name\":\"测试\",\"resourceVersion\":\"r:1\"}}}\n{\"type\":\"BOOKMARK\",\"object\":{\"metadata\":{\"resourceVersion\":\"r:2\"}}}\n",
  )
  let events : Array[@watch.Event] = []
  for byte in input {
    events.append(parser.feed(Bytes::from_array([byte])))
  }
  parser.finish()
  assert_eq(events.length(), 2)
  assert_eq(events[0].resource().unwrap().key().name, "测试")
  assert_eq(events[1].version(), "r:2")
}

///|
test "watch bounded records and 410 recovery" {
  let parser = @watch.Parser::new(max_event_bytes=3)
  assert_true(
    try parser.feed(b"1234") catch {
      @core.Capacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  let state = @watch.State::new()
  assert_true(state.needs_list())
  state.listed("opaque")
  state.checkpoint(Bookmark("next"))
  assert_eq(state.version(), "next")
  assert_eq(state.disconnected(500, 0), 100)
  ignore(state.disconnected(410, 0))
  assert_true(state.needs_list())
  assert_eq(state.version(), "")
}

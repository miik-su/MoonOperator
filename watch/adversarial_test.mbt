///|
test "deterministic malformed watch corpus fails closed at every chunk boundary" {
  for
    input in [
      "{\"type\":\"BOOKMARK\",\"object\":{\"metadata\":{\"resourceVersion\":42}}}\n",
      "{\"type\":\"ERROR\",\"object\":{\"code\":410.5}}\n", "{\"type\":\"BOOKMARK\",\"type\":\"ERROR\",\"object\":{\"code\":410}}\n",
      "{\"type\":\"ADDED\",\"object\":{}}\n",
    ] {
    let bytes = @utf8.encode(input)
    for split in 0..<=bytes.length() {
      let parser = @watch.Parser::new()
      assert_true(
        try {
          ignore(parser.feed(bytes[:split].to_owned()))
          ignore(parser.feed(bytes[split:].to_owned()))
          parser.finish()
          false
        } catch {
          _ => true
        },
      )
    }
  }
}

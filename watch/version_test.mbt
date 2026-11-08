///|
test "resource events require nonempty string resource versions" {
  for kind in ["ADDED", "MODIFIED", "DELETED"] {
    for version in [Json::null(), Json::number(42.0), Json::string("")] {
      let parser = @watch.Parser::new()
      let value : Json = {
        "type": kind,
        "object": {
          "apiVersion": "v1",
          "kind": "Pod",
          "metadata": { "name": "x", "resourceVersion": version },
        },
      }
      assert_true(
        try parser.feed(@utf8.encode(value.stringify() + "\n")) catch {
          @core.Invalid(_) => true
          _ => false
        } noraise {
          _ => false
        },
      )
    }
    let parser = @watch.Parser::new()
    let value : Json = {
      "type": kind,
      "object": {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": { "name": "x", "resourceVersion": "opaque:rv" },
      },
    }
    let events = parser.feed(@utf8.encode(value.stringify() + "\n"))
    assert_eq(events[0].version(), "opaque:rv")
  }
  for capacity in [0, -1] {
    assert_true(
      try @watch.Parser::new(max_event_bytes=capacity) catch {
        @core.Invalid(_) => true
        _ => false
      } noraise {
        _ => false
      },
    )
  }
}

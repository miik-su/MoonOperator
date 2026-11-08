///|
test "WASM host rejects disabled limits and precompiled inputs" {
  assert_true(
    try @wasm.Host::new("wasmtime", "plugin.cwasm") catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    try @wasm.Host::new("wasmtime", "plugin.wasm", fuel=0) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
  assert_true(
    try @wasm.Host::new("wasmtime", "plugin.wasm", timeout_ms=0) catch {
      _ => true
    } noraise {
      _ => false
    },
  )
}

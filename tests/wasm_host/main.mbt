///|
/// Explicit opt-in probe, excluded from package test runs.
async fn main {
  let args = @env.args()
  guard args.length() == 3 else {
    fail("usage: wasm_host WASMTIME MOONBIT_GUEST")
  }
  let host = @wasm.Host::new(args[1], args[2])
  assert_eq(host.validate({ "replicas": 3 }), { "abiVersion": 1, "valid": true })
  assert_eq(host.validate({ "replicas": 101 }), {
    "abiVersion": 1,
    "valid": false,
  })
  assert_true(
    try host.validate({ "replicas": "bad" }) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  for
    (file, expected) in [
      ("invalid.wat", "load"),
      ("trap.wat", "trap"),
      ("spin.wat", "fuel"),
      ("memory.wat", "memory"),
      ("capability.wat", "load"),
      ("abi.wat", "abi"),
    ] {
    let fault = @wasm.Host::new(args[1], "tests/wasm_host/fixtures/" + file)
    let actual = try fault.validate({ "replicas": 3 }) catch {
      @wasm.ModuleLoad => "load"
      @wasm.GuestTrap => "trap"
      @wasm.FuelExhausted => "fuel"
      @wasm.MemoryLimit => "memory"
      @wasm.InvalidAbi => "abi"
      _ => "unexpected"
    } noraise {
      _ => "success"
    }
    assert_eq(
      actual,
      expected,
      msg="\{file}: got \{actual}, expected \{expected}",
    )
  }
  let deadline = @wasm.Host::new(
    args[1],
    "tests/wasm_host/fixtures/spin.wat",
    fuel=100000000,
    timeout_ms=10,
  )
  assert_true(
    try deadline.validate({ "replicas": 3 }) catch {
      @wasm.Deadline | @async.TimeoutError => true
      _ => false
    } noraise {
      _ => false
    },
  )
  @fs.write_file(
    "wasm-host-report.json", "{\"guest\":\"MoonBit\",\"wasmtime\":\"50.0.1\",\"normal_invalid_trap_fuel_memory_capability_abi_deadline\":true}\n",
  )
  println("WASM host bounded execution probe passed")
}

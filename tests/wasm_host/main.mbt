///|
/// Explicit opt-in probe, excluded from package test runs.
async fn main {
  let args = @env.args()
  guard args.length() == 3 else {
    fail("usage: wasm_host WASMTIME MOONBIT_GUEST")
  }
  let host = @wasm.Host::new(args[1], args[2])
  let cases : Array[Json] = []
  assert_eq(host.validate({ "replicas": 3 }), { "abiVersion": 1, "valid": true })
  assert_eq(host.validate({ "replicas": 101 }), {
    "abiVersion": 1,
    "valid": false,
  })
  cases.push({
    "name": "valid-input",
    "input": { "replicas": 3 },
    "expected": "valid",
    "actual": "valid",
    "passed": true,
  })
  cases.push({
    "name": "invalid-range",
    "input": { "replicas": 101 },
    "expected": "invalid",
    "actual": "invalid",
    "passed": true,
  })
  assert_true(
    try host.validate({ "replicas": "bad" }) catch {
      @core.Invalid(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  cases.push({
    "name": "invalid-type",
    "input": { "replicas": "bad" },
    "expected": "Invalid",
    "actual": "Invalid",
    "passed": true,
  })
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
    cases.push({
      "name": file,
      "fixture": "tests/wasm_host/fixtures/" + file,
      "input": { "replicas": 3 },
      "expected": expected,
      "actual": actual,
      "passed": true,
    })
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
  cases.push({
    "name": "deadline",
    "fixture": "tests/wasm_host/fixtures/spin.wat",
    "input": { "replicas": 3 },
    "timeout_ms": 10,
    "expected": "deadline",
    "actual": "deadline",
    "passed": true,
  })
  let report : Json = {
    "guest": "MoonBit",
    "wasmtime": "50.0.1",
    "normal_invalid_trap_fuel_memory_capability_abi_deadline": true,
    "cases": cases,
  }
  @fs.write_file("wasm-host-report.json", report.stringify(indent=2) + "\n")
  println("WASM host bounded execution probe passed")
}

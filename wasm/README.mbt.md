# Experimental Wasmtime host

Host code and validator guest are MoonBit. Execution uses the separately
installed Wasmtime 50.0.1 CLI (Apache-2.0 WITH LLVM-exception).

```mbt check
///|
test "configure a bounded host" {
  let host = @wasm.Host::new("wasmtime", "validator.wasm", fuel=1000000)
  ignore(host)
}
```

ABI v1 exports `abi_version() -> i32` returning 1 and
`validate(replicas:i32) -> i32`, returning 0 (valid) or 1 (invalid).
`Host::validate` accepts `{"replicas":3}` and produces
`{"abiVersion":1,"valid":true}`. JSON stays host-side. This is a narrow scalar
validation ABI, not a general JSON plugin transport.

Each export runs in a fresh process. WASI imports are disabled. Guest modules
receive no filesystem/network/environment capabilities. Module size, output,
fuel, linear memory, table size, instance count, stack and wall time are bounded.
Compilation is included in the process deadline; compiled caching and precompiled
input are disabled. Limits constrain guest execution, not the CLI process's total
resident memory. This experimental adapter is not a general multitenant sandbox.

Build using `moon build examples/wasm_validator --target wasm`, then:

```
moon run tests/wasm_host --target native -- /absolute/path/to/wasmtime _build/wasm/debug/build/examples/wasm_validator/wasm_validator.wasm
```

The probe checks the real MoonBit guest, invalid inputs/modules, incompatible ABI,
trap, fuel exhaustion, memory rejection, missing capabilities and deadline. WAT
fault fixtures are test assets; the example is actual compiled Wasm.
See `.github/workflows/wasm.yml` for Linux verification with a fixed archive hash.

References: https://docs.wasmtime.dev/cli-options.html and
https://github.com/bytecodealliance/wasmtime/releases/tag/v50.0.1.

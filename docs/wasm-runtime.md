# Experimental extension direction

An actual bounded Wasmtime 50.0.1 process adapter and MoonBit guest now ship in
`wasm/` and `examples/wasm_validator/`. See `wasm/README.mbt.md` for the ABI,
capability/limit boundary, test command and known constraints. It validates a
bounded scalar input and returns host-side JSON. General JSON guest ABI and
authorized desired-state operations remain future extensions.

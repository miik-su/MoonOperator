(module
  (import "wasi_snapshot_preview1" "random_get" (func (param i32 i32) (result i32)))
  (func (export "abi_version") (result i32) i32.const 1)
  (func (export "validate") (param i32) (result i32) i32.const 0))

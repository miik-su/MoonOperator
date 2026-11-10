## MoonOperator wasm

Status before report upload: **local observation**. GitHub shows the final workflow status. Missing evidence is not a pass.

Wasmtime: 50.0.1.

| Case | Expected | Observed | Passed |
| --- | --- | --- | --- |
| valid-input | valid | valid | true |
| invalid-range | invalid | invalid | true |
| invalid-type | Invalid | Invalid | true |
| invalid.wat | load | load | true |
| trap.wat | trap | trap | true |
| spin.wat | fuel | fuel | true |
| memory.wat | memory | memory | true |
| capability.wat | load | load | true |
| abi.wat | abi | abi | true |
| deadline | deadline | deadline | true |

Download wasm-host-evidence for inputs and per-case outcomes. This is a bounded experimental validator probe, not a general isolation proof.

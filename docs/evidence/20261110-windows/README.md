# Windows 实测快照 — 2026-11-10

源提交：`e8e639679e97a2942934c4096f4d6055b39fc5a1`。原生采集开始时工作区干净，
对应状态记录在 benchmark.json / soak.json 的 provenance 中。结果采集后作为独立文档提交归档。

| 文件 | 内容 |
| --- | --- |
| [benchmark-input.json](benchmark-input.json) | Pod 模板、1,000 对象生成规则、Watch 事件、Fake MoonApp 输入 |
| [benchmark.json](benchmark.json) | 原生 release 基准结果、迭代次数、校验和、环境、源提交 |
| [soak-input.json](soak-input.json) | 1,000 对象、重复入队及每 Key 故障注入规则 |
| [soak.json](soak.json) | 十秒负载的实际循环数、成功/失败/重试计数、结束队列和缓存状态 |
| [summary.md](summary.md) | 由脚本生成的原生结果表 |
| [wasm-cases.json](wasm-cases.json) | 同一源提交本地运行的十个 WASM 用例，含输入、预期、实际结果 |
| [wasm-summary.md](wasm-summary.md) | WASM 逐项结果表 |

WASM 使用 Windows Wasmtime 50.0.1，宿主为 native debug，MoonBit guest 为 wasm debug；
基准和短负载使用 native release，两者不能混为同一种性能测试。
64 位计数器在原始 JSON 中可能采用十进制字符串。CPU 信息未由进程环境暴露，RSS 未测量。
这是单次观测，不用于推断性能提升、长时间稳定性或不存在内存泄漏。

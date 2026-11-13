# 测试数据与结果展示

[![原生关键检查](https://github.com/miik-su/MoonOperator/actions/workflows/check.yml/badge.svg)](https://github.com/miik-su/MoonOperator/actions/workflows/check.yml)
[![Kind 集群验收](https://github.com/miik-su/MoonOperator/actions/workflows/kind.yml/badge.svg)](https://github.com/miik-su/MoonOperator/actions/workflows/kind.yml)
[![WASM 用例](https://github.com/miik-su/MoonOperator/actions/workflows/wasm.yml/badge.svg)](https://github.com/miik-su/MoonOperator/actions/workflows/wasm.yml)

上方徽章显示最新 CI 状态；下面的表格是有固定源提交的历史实测快照。
测试数据以合成 Kubernetes Pod、MoonApp 和 Watch 事件为主。
输入模板、生成规则、原始结果均已保存到仓库，无需登录 Actions 下载即可阅读。

## 数据模型与样例

最新审查的完成项与待验证项见[2026-11-13 跟进记录](review-followup-20261113.md)。

## Linux 容器内存与网络隔离 · 2026-11-13

源提交 `695c58cc93a18bc2139751c7dad0e18f91b78e35` 的
[真实集群与独立内存作业](https://github.com/miik-su/MoonOperator/actions/runs/43364884221)
均通过；[原始数据与校验值](evidence/20261113-linux/README.md)永久保存在仓库。

| 合成资源模型 | 容器上限 MiB | 进程峰值 RSS KiB | 退出码 | OOMKilled |
| --- | ---: | ---: | ---: | --- |
| 示例配置：1,024 对象 / 8 MiB 编码缓存 | 128 | 38,104 | 0 | false |
| 同上 | 256 | 38,084 | 0 | false |
| 同上 | 512 | 38,080 | 0 | false |
| 通用配置：10,000 对象 / 64 MiB 编码缓存 | 128 | 129,780 | 0 | false |
| 同上 | 256 | 129,712 | 0 | false |
| 同上 | 512 | 129,756 | 0 | false |

每行使用新的非 root、只读根目录容器，保留替换前后快照且不强制 GC。
10k/128 MiB 已接近上限，不能据此推荐该配置或推断长期稳定性。
旧失败记录实际为退出码 1、OOMKilled=false，不能当作 OOM 证据。

Calico 3.33.0 / Kubernetes 1.37.0 实测同一探针 Pod 的允许访问、去除 Pod
标签拒绝、恢复、去除 namespace 标签拒绝及恢复；六项 RBAC 预期与实际一致。
这些结果不覆盖后来新增且仍在排查的可选接管探针，不代表最新 HEAD 全部通过。
全量回归、1 小时和 24 小时运行均未执行。

## 数据模型输入

| 数据/模型 | 规模及用途 | 原始输入 / 实现 |
| --- | --- | --- |
| Pod 资源集 | `p0` 至 `p999`，同 namespace，携带 label 与 opaque RV | [完整模板及生成规则](evidence/20261110-windows/benchmark-input.json)、[基准实现](../benchmarks/runtime/main.mbt) |
| Watch 事件 | 上述 Pod 封装为 ADDED，UTF-8 NDJSON 编码 | [事件输入](evidence/20261110-windows/benchmark-input.json)、[恶意分块样例](../watch/adversarial_test.mbt) |
| MoonApp 协调模型 | Fake API 创建资源后重复协调 1,000 次，检查无额外写入 | [MoonApp 输入](evidence/20261110-windows/benchmark-input.json)、[所有权案例](../examples/moonapp/ownership_test.mbt) |
| 故障与重复事件 | 每轮重复入队；每个 Key 的协调次数模 31 为零时注入临时失败 | [负载配置](evidence/20261110-windows/soak-input.json)、[实现](../tests/soak/main.mbt) |
| WASM 验证模型 | replicas=3 / 101 / 错误类型，加畸形、陷阱、fuel、内存、权限、ABI、超时模块 | [用例输入及结果](evidence/20261110-windows/wasm-cases.json)、[WAT 模块](../tests/wasm_host/fixtures) |
| 真实 API 集群模型 | 狭窄 ServiceAccount 的客户端探针与 MoonApp 生命周期 | [探针实现](../tests/cluster_client/main.mbt)、[部署输入](../config/moonapp.yaml)、[验收流程](../scripts/kind-e2e.mbtx) |

Pod 模板中的镜像字段仅参与本地 JSON/Fake 测试，不会在基准中被拉取或运行。
真实部署输入单独维护在 config/ 中。测试样例均使用合成身份和模拟凭据。

## Windows 基准快照 · 2026-11-10

来源：[`e8e6396`](https://github.com/miik-su/MoonOperator/commit/e8e639679e97a2942934c4096f4d6055b39fc5a1)，
MoonBit `0.10.17+d971670cd`，native-release，1 worker，1,000 个对象。
计时单位为微秒，表格四舍五入到四位小数；原始 JSON 保留完整数值。

| 观测项目 | 迭代次数 | 平均 µs/次 |
| --- | ---: | ---: |
| Resource 复制及序列化 | 1,000 | 9.6895 |
| JSON 解析及序列化 | 1,000 | 12.3292 |
| Cache 按 Key 读取 | 10,000 | 0.6560 |
| Cache label 查询（扫描 1,000 对象） | 100 | 1,873.4110 |
| Watch 事件解析 | 1,000 | 15.0637 |
| Queue 入队、领取与完成 | 10,000 | 1.5010 |
| Fake MoonApp 幂等协调 | 1,000 | 567.3204 |

最后一项 **额外写入为 0**。这不包含网络、API Server admission 或真实工作负载启动耗时。
CPU 型号未暴露，RSS 未测量；单次结果不能作为性能保证或跨版本优劣比较。

[原始基准及来源](evidence/20261110-windows/benchmark.json) ·
[生成的详细表格](evidence/20261110-windows/summary.md) ·
[2026-11-08 历史结果](evidence/windows-benchmark-20261108.json)（未记录同等完整来源信息）

## 十秒故障负载快照

| 项目 | 实际记录 |
| --- | ---: |
| 持续时间 | 10,015 ms |
| 主循环迭代 | 496,409 |
| 资源对象 | 1,000 |
| 协调成功 | 480,617 |
| 注入失败 / 安排重试 | 16,617 / 16,617 |
| 关闭排空后待处理 Key | 0 |
| 最终缓存对象 | 1,000 |
| 最终缓存编码字节 | 107,890 |

主循环数与协调计数含不同阶段（例如关闭排空），不要求相等。
[原始负载结果](evidence/20261110-windows/soak.json)记录来源和未测量项。
十秒运行只证明该有界样例完成，不证明小时/天级稳定性。

## WASM 十个用例 · 本地实测

| 用例 | 输入 / 故障 | 预期与观测 |
| --- | --- | --- |
| 合法参数 | replicas=3 | valid，通过 |
| 越界参数 | replicas=101 | invalid，通过 |
| 错误类型 | replicas="bad" | Invalid，通过 |
| 畸形模块 | invalid.wat | load 拒绝，通过 |
| 执行陷阱 | trap.wat | trap，通过 |
| 指令预算 | spin.wat | fuel 耗尽，通过 |
| 内存预算 | memory.wat | memory 拒绝，通过 |
| 未授权能力 | capability.wat | load 拒绝，通过 |
| ABI 不匹配 | abi.wat | abi 拒绝，通过 |
| 截止时间 | spin.wat，10 ms | deadline，通过 |

[逐项原始记录](evidence/20261110-windows/wasm-cases.json) ·
[生成的用例表](evidence/20261110-windows/wasm-summary.md)

使用 Windows Wasmtime 50.0.1，native debug 宿主与 wasm debug guest。
这是受限 scalar validator 探针，不证明完整的系统沙箱隔离。

## 已归档的真实 Kind 集群验收

源提交 `21b5cbb`，观察日期 2026-11-08；Kubernetes server **v1.37.0**。
[原始 CI](https://github.com/miik-su/MoonOperator/actions/runs/42489317303)已通过。

| 验收组 | 归档结果 |
| --- | --- |
| MoonApp 创建、更新、漂移修复、重启、GC | true |
| 实际 API CRUD、PATCH、分页、冲突、权限拒绝、Watch | true |
| ServiceAccount TLS 验证 | true |

[MoonApp 报告](evidence/20261108-kind-21b5cbb/moonapp.json) ·
[客户端报告](evidence/20261108-kind-21b5cbb/client.json) ·
[Kubernetes 环境](evidence/20261108-kind-21b5cbb/kubernetes-version.json) ·
[运行时包版本](evidence/20261108-kind-21b5cbb/runtime-packages.txt) ·
[来源及已校验归档摘要](evidence/20261108-kind-21b5cbb/provenance.json)

这些报告保存验收组结果，不是独立的逐测试覆盖率报告。默认 Kind 也未验证 NetworkPolicy 流量隔离。

## 后续 CI 如何查看

1. 从本页徽章进入对应 workflow，打开一次运行的 **Summary**。
2. 原生任务展示基准和短负载表，Kind 展示验收组及 Kubernetes 版本，WASM 展示每个用例。
3. 从 **Artifacts** 下载 `native-observations`、`kind-acceptance` 或 `wasm-host-evidence`，获取 Markdown 和原始 JSON。

缺失结果显示 `not recorded`，不会填成通过；最终状态以 GitHub workflow 结果为准。
原生 CI 仅在既有关键回归之外增加固定规模基准和十秒观察，不运行全量测试。
CI 附件受保存期限影响；本页链接的仓库快照会长期留在版本历史中，后续 CI 不会自动覆盖历史快照。

## 复现与生成展示

```sh
moon run scripts/collect-observations.mbtx -- ci-evidence
moon run scripts/report-summary.mbtx -- native "local observation" ci-evidence
```

采集器将短负载固定为十秒，保留 Git SHA 和运行前工作区状态。
要生成带显示日期的独立快照，可为采集器提供第三个参数，例如 `2026-11-10`。
WASM 及 Kind 复现命令分别见 [WASM 文档](wasm-runtime.md) 和 workflow/验收脚本；它们需要对应运行时或集群环境。

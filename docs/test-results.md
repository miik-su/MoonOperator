# 测试数据与结果展示

[![原生关键检查](https://github.com/miik-su/MoonOperator/actions/workflows/check.yml/badge.svg)](https://github.com/miik-su/MoonOperator/actions/workflows/check.yml)
[![Kind 集群验收](https://github.com/miik-su/MoonOperator/actions/workflows/kind.yml/badge.svg)](https://github.com/miik-su/MoonOperator/actions/workflows/kind.yml)
[![WASM 用例](https://github.com/miik-su/MoonOperator/actions/workflows/wasm.yml/badge.svg)](https://github.com/miik-su/MoonOperator/actions/workflows/wasm.yml)

上方徽章链接至各工作流；以下实测快照均标注源提交。仅更新文档并跳过 CI
的提交不会产生新的验证证据。
测试数据以合成 Kubernetes Pod、MoonApp 和 Watch 事件为主。
输入模板、生成规则、原始结果均已保存到仓库，无需登录 Actions 下载即可阅读。

## RSS 对照与真实 Kind 一小时长稳 · 2026-11-28

样本改为流式写入后，Linux 合成测试首分钟至结束的 RSS 增量从 972 KiB 降至
128 KiB，系统分配器组为 16 KiB。Kubernetes 1.37.0 + Calico 实测 61 次检查，
同一 Operator Pod 持续处理副本数变化，采样时均就绪，容器重启数为 0。
[对照设计、原始样本与 CI](evidence/20261128-soak-followup/README.md)。

## Linux 一小时合成长稳测试 · 2026-11-28

1,000 个合成资源运行 3,600,002 ms，注入 17,100,000 次瞬时失败，结束时队列
清空且缓存保留 1,000 个对象。61 个 RSS 样本中，第一分钟为 5,004 KiB，
结束为 5,976 KiB。[原始报告、输入和范围](evidence/20261128-linux-soak/README.md)。

## Kubernetes 三版本兼容性 · 2026-11-28

修复 Kind 在 Kubernetes 1.35 上未应用所有权准入配置的问题。1.35.8、1.36.4 和
1.37.0 复测通过真实 API、TLS、RBAC、所有权准入、Calico 网络策略和 MoonApp 生命周期。
[首轮失败、复测和原始报告](evidence/20261128-kind-compatibility/README.md)。

## MoonApp 状态更新与真实集群回归 · 2026-11-28

原修复及后续条件顺序修复的 GitHub 原生 CI 均通过，Kind 1.36.4 和 1.37.0
均通过。后续版本本地原生关键测试 9/9，两个集群均确认副本数变更后，外部写入
的状态字段和条件顺序都得到保留。[源码版本、实测命令和 CI 日志](evidence/20261128-moonapp-status/README.md)。

## Mooncakes 0.1.3 安装与引用 · 2026-11-28

注册表公开返回 0.1.3，SHA-256 与上传 ZIP 一致。仓库外的独立模块直接下载
此版本，原生检查和示例运行通过。实测得到两次调谐、一次更新，保留无关注解，
待处理任务为 0。[发布与验证记录](evidence/20261128-mooncakes/README.md)。

## 仓库说明与关键检查 · 2026-11-27

Windows 原生关键用例 3/3 通过。两个命名空间成功生成安装清单，独立消费示例
通过本地源码引用验证。实际 ZIP 核对了 514 个路径、10 份许可与声明以及
2 份依赖许可证。[命令、源码版本和归档校验值](evidence/20261127-repository/README.md)。

## 生产镜像标量 UTF · 2026-11-22

源提交 `ce94fb5` 的 GNU 链接映射确认选入 SDK 的 `runtime-utf.o`。
镜像内可执行文件与独立链接审查产物摘要一致，链接映射没有两个可选 SIMD
对象。发布模式 Watch 用例 2/2 通过，两版 Kind 的真实 API、TLS 和网络策略
验收也通过。生产镜像的 94 个系统包与之前的签名源码清单一致。
[实测记录](evidence/20261122-scalar-utf/README.md)。

## 单层生产镜像与 Ubuntu 源码包 · 2026-11-22

生产镜像只含一层最终文件系统。中间 Ubuntu 基础镜像的 92 个包中有 8 个
版本在生产镜像里被替换，最终 94 个包与已核验的源码清单一致。对应源码包
回读抽取时对全部 212 个源码文件进行了大小和 SHA-256 核对。
[镜像层、源码包与 SDK 来源记录](evidence/20261122-production-layers/README.md)。

## Ubuntu 对应源码与链接成员 · 2026-11-22

94 个实装 Ubuntu 软件包映射到 67 个源包。212 个源码文件下载后均与签名
索引中的大小和 SHA-256 一致。GNU 链接映射确认 19 个选入成员，
`libbacktrace.a` 无选入成员。带映射构建的可执行文件与镜像内的文件摘要一致。
14 个已知 CVE 复查结果仍为 4 个待修、10 个延期。
[源码清单、链接映射和复查记录](evidence/20261122-source-link/README.md)。

## 镜像源码签名与静态许可复查 · 2026-11-21

核验固定 Noble 快照的归档签名和三个源码包的上传者签名。6 个源码文件
的大小与 SHA-256 同时匹配源码索引和各自的签名描述符，改动索引的反例被拒绝。
Linux 链接证据确认了 mimalloc 2.1.7 和 simdutf，源码 ZIP 和镜像中的 10 份通知
均逐字节通过。先前 14 个 CVE 逐项对照 Canonical，4 个待修、10 个延期，
未发现已发布的 Noble 修复。[原始核验记录](evidence/20261121-redistribution/README.md)。

## 容器安全、再分发与 Kubernetes 兼容性 · 2026-11-21

源提交 `471a658` 的 amd64 生产镜像使用 Ubuntu 24.04，`libc6` 从
`2.39-0ubuntu8.9` 更新到 `2.39-0ubuntu8.12`。Trivy 核对 94 个已安装包，
记录 23 个包与漏洞组合（14 个不同 CVE、18 条中危、5 条低危、0 条高危或严重）。
该扫描库未为这些记录列出 Ubuntu 修复版本。7 份镜像随附项目与依赖声明
逐字节验收通过，三个重点 Ubuntu 源包的六个文件完成大小和 SHA-256 核对。

Kubernetes 1.36.4 和 1.37.0 均通过定向验收，使用 Calico 3.33.0。
验证了真实 API、TLS、MoonApp 生命周期、RBAC、所有权准入和网络策略。
[结果、剩余发现和归档校验值](evidence/20261121-container/README.md)。

## Informer 范围与源码许可校验 · 2026-11-21

干净源提交 `7c16596` 在 Windows 通过 16 项关键模型用例、独立公开 API 示例与
实际源码 ZIP 检查。模型覆盖命名空间及集群级范围、不合法书签、重新 LIST 和缓存
保留；归档核对了 312 个路径、7 份许可与声明文件及 2 份依赖许可证归档副本。
[命令及实测结果](evidence/20261121-scope-license/README.md)可直接查看。

同一源码的 GitHub 原生、Kind 和 WASM 检查均已通过。Linux 模型用例 16/16，
实际 ZIP 许可内容一致，TLS 正反用例通过。Kind 覆盖 Kubernetes 1.37.0 与
Calico 3.33.0；实验 WASM 用例 10/10。[同源 CI 结果及校验值](evidence/20261121-scope-license/README.md#github-actions-on-the-same-source)。

## API 协议与 WASM 定向验证 · 2026-11-21

Windows 原生定向用例 15/15 通过，覆盖 API 返回对象身份、LIST 分页元数据、
重复键拒绝、失败后缓存快照保留，以及同名资源 UID 变化触发协调。
升级 Wasmtime 后，实验宿主的本地定向用例 1/1、Linux WASM 用例 10/10 通过。

Linux 源提交 `457c794` 的原生关键检查已通过，其中维护模型用例 14/14，
独立公开 API 示例、源码 ZIP 检查及 TLS 正向和拒绝用例均通过。
旧版 Wasmtime 50.0.1 的安全检查返回八条公告，升级到 50.0.3 后对该确切版本
的 OSV 查询返回空列表。[运行记录、原始报告和校验值](evidence/20261121-protocol/README.md)
包含测试源提交和实际覆盖范围。

同一提交也通过 Kind 集群验收，覆盖 Kubernetes 1.37.0、Calico 3.33.0、
实际 API、示例生命周期、RBAC、所有权接管和网络策略。六组短时容器缓存探针
均正常退出。镜像清单保存了 94 个已安装软件包及其版权文本的采集记录。

## 定向维护回归 · 2026-11-18

干净源提交 `420620c7a0a4fd0c259e5492ddea6b0267edef64` 在 Windows native
通过 14 项定向测试、独立公共 API 消费示例及实际源码 ZIP 检查。
[完整命令、输出和来源](evidence/20261118-maintenance/README.md)永久保留。
新增模型覆盖未完成 LIST 拒绝、重复事件/UID 重建/410 恢复、独立命名空间
缓存隔离、处理中 100 次变更和 409 冲突后的最终状态、CRD 生成校验，
以及固定延迟桶的累计语义。消费示例实测两次协调、一次更新、保留无关注解。

本轮未执行全量测试或小时/天级负载；这些短测不能证明无泄漏或生产稳定性。
Linux CI 和镜像版权采集有独立源提交及运行记录，不与本地结果混为一谈。
测试模型、数据来源和许可见[模型目录](test-models.md)。

修复归档工具兼容性后的 Linux 源提交 `6235a5f` 已通过原生关键检查，
其中维护回归 14/14、独立消费示例和实际 ZIP 校验均通过；TLS 正向与
错误 CA／主机名拒绝结果已保留。镜像证据记录 94 个系统包及全部对应
版权文本；六组内存探针均完成，退出码 0、OOMKilled=false。
[原始报告、附件 ID 与校验值](evidence/20261118-maintenance/README.md)可直接核对。
版权文本可用不等于许可兼容性或漏洞审计通过，10k/128 MiB 仍接近上限。
同一源码提交的 Kind 与 WASM 检查也已通过。Kind 报告记录 Kubernetes
1.37.0、Calico 3.33.0，以及实际的 RBAC、网络策略和接管准入结果。

## 数据模型与样例

当前完成项和开放门槛见[维护清单](maintenance.md)；
[2026-11-13 跟进记录](review-followup-20261113.md)保留历史审查结论。

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
这里运行独立的缓存快照探针，不是完整控制器、TLS/watch 与工作负载的总内存。
10k/128 MiB 已接近上限，不能据此推荐该配置或推断长期稳定性。
旧失败记录实际为退出码 1、OOMKilled=false，不能当作 OOM 证据。

Calico 3.33.0 / Kubernetes 1.37.0 实测同一探针 Pod 的允许访问、去除 Pod
标签拒绝、恢复、去除 namespace 标签拒绝及恢复；六项 RBAC 预期与实际一致。
上表保留早期修复后的快照。最终代码源提交 `31d7390` 的原生、WASM、Kind
三项检查也已全部通过：[同源 CI 链接及原始结果](evidence/20261113-linux/31d7390/README.md)。
显式启用所有权准入后，默认拒绝接管、缺少删除权限返回 403、指定资源授权后
成功接管均获实测确认；没有扩大示例账号权限。最终六组内存峰值详见同源原始数据。
全量回归、1 小时和 24 小时运行均未执行。

源提交 `186a7fb` 的 [Linux TLS 负向用例](evidence/20261113-linux/tls-negative.json)
证明可信 CA/正确主机名可连接，无关 CA 和错误主机名均被拒绝。
[队列规模原始数据](evidence/20261113-linux/queue-scale.json)提供 1k/10k/50k
就绪 FIFO 与延时堆的操作 P95/P99 和进程内存；峰值在同一进程中累计，
操作延迟不等同于端到端协调延迟或定时等待时长。
[同源 Linux 十秒负载](evidence/20261113-linux/soak.json)实际持续 10,003 ms，
注入失败／重试各 37,000 次，排空后待处理 Key 为 0；起止 RSS 为
3,448／5,020 KiB。[输入配置](evidence/20261113-linux/soak-input.json)和
[基准结果](evidence/20261113-linux/benchmark.json)一并归档。

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

# MoonOperator 安全整改记录 — 2026-11-08

本轮审查对象是 `miik-su/MoonOperator`，起点为 `163df10`。
第一轮引用报告检查的是旧地址 `mik1e80/MoonOperator`，当时没有可审查代码；
其中 C01–C18 是审查要求，不是已经发现的漏洞。本记录保留第一轮整改证据。
对话随后改为正确仓库并新增代码级发现，其整改详见
[后续代码审查整改](review-followup-20261108.md)。
这是限定范围的代码审查与整改，不是独立渗透测试或生产安全认证。

## 本轮确认并修复的缺口

| 位置 | 原有缺口及影响 | 修改与验收 |
| --- | --- | --- |
| core/types、crd/schema、client/rest | 先递归复制再限制深度；程序内循环 Json 可导致无界递归，超大对象增加分配压力 | 新增有深度、节点、UTF-8 字节预算的遍历；在复制前验证；循环 Json 和编码边界回归 |
| transport/http | 注入 Request 未在边界明确限定相对地址、请求体和部分头字段 | 仅接受安全的 origin-relative target，限制请求体和凭据文件；危险地址在凭据读取前失败 |
| transport/http | 没有显式拒绝重定向响应的契约 | 全部 3xx 拒绝；双监听器测试证明第二地址没有收到连接，原请求正常携带测试凭据 |
| transport/config | 同名条目取第一个、错误字段类型可能默认为空、部分安全配置被忽略 | 拒绝重复名称、错误类型、混合 token/tokenFile 和不支持的凭据、代理、TLS 名称覆盖 |
| cache/store | 仅限制对象数，无法控制大对象的总编码体积 | 默认每对象 1 MiB、总计 64 MiB、10,000 对象；原子替换、更新失败、旧 UID 删除和负预算回归；暴露数量/字节指标 |
| controller/worker、finalizer | 回调无截止时间，永久错误也反复重试 | 默认 30 秒协作式超时；Invalid/Capacity 和永久 API 错误进入 Terminal；超时释放 Key；清理超时保留自身 finalizer，同时保留其他 finalizer |
| runtime/informer | 永久 HTTP 错误分类不足；注入 Source 的 Failure 事件可能被忽略 | 非 410、非可重试状态立即失败并撤销就绪；事件与异常统一分类；400 一次失败和 410 重新 LIST 回归 |
| watch/parser | bookmark RV 被宽松转换，ERROR 小数状态码被截断 | RV 必须为不透明字符串，状态码必须为整数；恶意记录在每个分块边界均拒绝 |
| CI | 可移动 Actions 标签及未校验的远程安装脚本 | Actions 固定完整 SHA；SDK/core/Kind/Gitleaks/Wasmtime 下载后验证固定 SHA-256；移除远程脚本执行；关闭 checkout 凭据持久化 |
| 治理 | 缺少贡献、行为、安全报告及模块契约文件 | 补齐 NOTICE、CONTRIBUTING、CODE_OF_CONDUCT、SECURITY 和模块边界；保持已有 Apache-2.0 及第三方声明 |

重定向测试并不意味着原版 HTTP 库曾自动跨域转发凭据；本次增加的是明确的拒绝契约与回归保护。
编码体积限制也不等同于进程 RSS 限制，快照构建会暂时保留旧、新两份索引。

## C01–C18 对照

| 编号 | 当前处理与证据 | 边界 |
| --- | --- | --- |
| C01 Token 泄露 | transport 私有凭据、固定错误原因、无原始请求日志；历史 Gitleaks 扫描 | 调用方自定义日志仍需自行控制；扫描不是无泄露证明 |
| C02 TLS | async 原生 TLS 验证 CA/主机名；Kind 使用 ServiceAccount CA/token | 无效 CA、错误证书主机名和过期 Token 的完整负向矩阵仍待独立测试 |
| C03 重定向 | origin_test 双监听器回归；所有 3xx 拒绝 | 不提供自动重定向模式 |
| C04 路径 | client 安全路径构造及编码，transport 再检查注入请求 | 不实现通用任意 URL 代理 |
| C05 流解析 | UTF-8 字节边界、重复字段、畸形 bookmark/status 和截断检测 | 有限确定性对抗语料，不宣称持续覆盖式模糊测试 |
| C06 410 | 真实流和注入 Source 统一失败分类，重新 LIST 后恢复 watch | 快照以 GVK 为边界，不跨多个独立命名空间共享同一 Store |
| C07 重连 | 指数退避上限与随机抖动；永久 HTTP 错误终止 | 暂时故障会持续、有间隔恢复，不是有限重试后丢弃控制器 |
| C08 数据竞争 | 同一协作事件循环同步修改，读取 Resource 副本，原子快照 | 不是跨 OS 线程共享容器 |
| C09 内存增长 | 新增总字节/对象字节预算、规模指标及原子失败测试 | RSS、长时间运行和容器 OOM 行为尚未充分测量 |
| C10 重复任务 | queue dirty/in-flight 去重；并发同 Key 排他及释放回归 | 进程重启后重新 LIST，队列不持久化 |
| C11 重试风暴 | 单一队列退避、Worker 上限、请求间隔、Retry-After；永久错误不自动重试 | 不自动重放写请求；外部副作用由业务保证幂等 |
| C12 幂等协调 | MoonApp fake 与 Kind 创建、更新、漂移修复、重启与 GC | 不能替用户任意回调保证幂等 |
| C13 RV 冲突 | RV 保持字符串；fake/真实 API 409 回归，重新协调读取 | 不是跨资源事务 |
| C14 CRD 输入 | 深度/字节预算先于复制；已有类型、必填、范围、长度、未知字段策略 | 有界 OpenAPI 子集，没有通用 webhook/conversion |
| C15 RBAC | 显式规则，拒绝通配资源及特权动词；命名空间 Role；Kind 越界 403 | 安装 CRD 所需权限与运行 ServiceAccount 权限分开；cluster scope 须显式选择 |
| C16 Finalizer | 幂等回调、冲突保留、超时保留；只移除指定名称 | 清理永久失败仍需运维决策，不会为避免卡删除而自动跳过清理 |
| C17 WASM | 已有无 WASI 能力、fuel/内存/时间/输出限制及故障探针；固定 Wasmtime 50.0.1 | 实验性 scalar ABI；不证明不存在逃逸，也不提供完整 OS/RSS 隔离；仅运行可信来源模块 |
| C18 异常覆盖 | 新增预算、超时、永久错误、恶意 Watch、重定向、配置歧义回归；保留已有并发和 Kind 验收 | 按要求只跑关键定向测试；没有全量测试、长时间 soak 或全平台矩阵 |

## 供应链和条款

新增 `scripts/sbom.mbtx` 从 `moon tree --json` 生成 CycloneDX 1.6 清单，
核对实际依赖版本和许可证；未审查的新依赖、版本或许可证变化会失败。
清单为 [source-sbom.json](evidence/source-sbom.json)，只覆盖解析出的 Mooncakes
源码模块，不包含 SDK、系统 TLS、镜像 OS 或可选 Wasmtime 二进制。
保持 async 0.22.5 的 Apache-2.0 和 yaml 0.0.8 的 MIT 归属声明。

Dependabot 配置覆盖 GitHub Actions 与 Docker；Mooncakes 需人工核对上游更新。
新增 `scripts/advisories.mbtx` 查询固定 Wasmtime 的 OSV 记录，网络/分页异常不会记成通过，
已知未撤回公告会使检查失败。[2026-11-08 查询](evidence/osv-wasmtime-20261108.json)
未返回 Wasmtime 50.0.1 的公告；这不能推广为其他依赖或二进制无漏洞。
上游 [50.0.1 发布说明](https://github.com/bytecodealliance/wasmtime/releases/tag/v50.0.1)
记录了本版安全修复；
[GHSA-32h6-97mm-8q3c](https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-32h6-97mm-8q3c)
列出的受影响区间不包含 50.0.1。Mooncakes/SDK 缺少完整自动扫描覆盖仍是维护工作项。

GitHub 私密漏洞报告已开启，并用 API 读取确认 `enabled=true`。
CI 使用 Gitleaks 8.30.1 全部已取回 Git 历史的脱敏扫描；不声称 GitHub 平台内置
Secret Scanning/Push Protection 已开启，也不修改付费安全产品设置。

保留已有 Apache-2.0 主许可证，新增 NOTICE 不改变授权范围；不新增 CLA、
响应 SLA 或官方背书。二进制分发方仍须按实际打包组件核对第三方声明。

## 本地复核

以下定向命令执行结果为 **11 个测试全部通过**：

```sh
moon test core/budget_test.mbt cache/budget_test.mbt controller/deadline_test.mbt controller/finalizer_test.mbt transport/origin_test.mbt transport/kubeconfig_test.mbt watch/adversarial_test.mbt runtime/recovery_test.mbt --target native
```

`moon check --target native`、`moon fmt`、`moon info --target native` 已完成。
另外执行过 cache/store、controller/concurrency、controller/timing、crd/schema、
watch/watch、observability/health 等受影响部分的定向回归，均通过。
没有运行全量测试。新业务保护及依赖检查脚本均使用 MoonBit，未新增 C/JS/Python 运行时实现。

## 后续发布门槛

仍保持 0.1.0 未发布状态，不把分阶段功能交付等同于稳定 1.0。
后续门槛是：小时/天级 soak 与 RSS、TLS/凭据轮换负向矩阵、更多 Kubernetes 版本、
完整分发物 SBOM/OS 漏洞检查、Mooncakes 命名空间和发布确认。
HA/Leader Election、webhooks 和通用 JSON 插件 ABI 继续按已有范围单独规划。

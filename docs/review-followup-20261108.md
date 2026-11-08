# 最新代码审查建议整改 — 2026-11-08

本轮按引用对话中 `c5bd2c88`、`7770823e` 两次正确仓库审查继续修改，
保留已有 MoonBit 实现、分批提交及仅运行关键定向测试的要求。
原有 C01–C18 第一轮记录仍保留；本文件对照新增代码级建议。

## 八项主要建议

| 建议 | 已修改行为 | 定向验证 |
| --- | --- | --- |
| 2.1 Resource Debug 泄密 | 所有资源（含自定义资源与 metadata）输出固定 redacted 文本，不派生原始 Json 调试输出 | core/redaction_test：Secret 和自定义类型的模拟凭据不出现在输出 |
| 2.2 Finalizer 空转 | Bool 改为 Continue、FinalizerAdded、CleanupPending、CleanupComplete、NoLongerResponsible | controller/finalizer_test：清理成功/失败/超时、无自身 finalizer、剩余其他 finalizer；完成后不要求重排 |
| 2.3 / 2.7 OwnerReference 作用域 | API 显式接收双方 ResourceType，允许 namespaced → cluster owner，拒绝跨 namespace、cluster → namespaced、类型/声明不匹配与自引用 | core/ownership_test 覆盖合法组合、拒绝组合及引用保留 |
| 2.4 MoonApp 接管及引用覆盖 | 默认拒绝已有无主资源；仅显式 adopt_unowned=true 可接管；任何模式均拒绝其他控制器；比较/覆盖前合并保留其他非控制型引用 | examples/moonapp/ownership_test：默认零写入、显式接管、保留引用、再次协调零写入、拒绝外部控制器 |
| 2.5 Watch RV | ADDED/MODIFIED/DELETED 必须非空字符串 RV，注入 Source 也先验证再应用 | watch/version_test：缺失/空/数字/正常 RV；runtime/capacity_test：非法资源不进入缓存 |
| 2.6 容量无限 LIST | 新增 CacheCapacity、QueueCapacity、ListCapacity；缓存/LIST/一般容量立即撤销 readiness 并上抛；队列满在入队处等待 | runtime/capacity_test：超额快照仅请求一次；backpressure_test 保留队列背压行为 |
| 2.6 持续非法事件 | 无效 LIST 直接失败；非法 Watch 受控重建，连续三次后失败，成功事件重置预算；不伪造 HTTP 410 | runtime/capacity_test 验证三次上限；recovery_test 保留真正 410 relist |
| 2.8 审计链接 404 | 已补交 security-audit-20261108.md，并从旧记录链接到本轮记录 | 文件已纳入版本控制；README、SECURITY、security-model 路径一致 |

## 附加检查项

| 建议 | 处理 |
| --- | --- |
| debug 二进制、混入探针 | Docker 默认 production 使用 release 二进制；acceptance 为独立兄弟阶段；CI 断言生产镜像中不存在 client-probe |
| 基础镜像与系统包浮动 | Ubuntu 24.04 固定 OCI index digest；运行时使用 20261108T000000Z 签名 APT 快照；固定 ca-certificates=20240203 仅提取证书数据引导 HTTPS，无关闭 TLS 校验；CI 保存 dpkg 清单 |
| 诊断端口 | 本地默认 127.0.0.1；集群显式开启 pod 端口并提供 NetworkPolicy，仅匹配获准 namespace 与 pod；没有宣称新增身份认证 |
| 示例 Pod 保护 | runAsNonRoot、RuntimeDefault、禁提权、drop ALL、CPU/内存请求及上限；示例改用固定摘要的非 root 镜像和 8080 |
| Queue/Parser 非正容量 | 构造时直接 Invalid，不再产生永远无法完成的入队或读取循环 |
| RBAC group | 公用 DNS group 校验拒绝部分通配符、大小写/路径等无效组；资源名拒绝空字符串和通配符 |
| 配置文件 TOCTOU | 不再依据路径 stat 决定后续无界读取；打开一次、验证普通文件、边读边限制 limit+1，截止时间内关闭句柄；保留 projected token 路径轮换 |
| Registry 类型校验 | 注册前检查 group、version、kind、plural 的已支持标识符范围；REST 路径和 ownership 使用同一验证 |
| LIST 汇总内存 | 新增总编码字节及单对象预算，默认 64 MiB/1 MiB；在追加分页资源前检查，返回 ListCapacity；client/budget_test 验证边界与请求次数 |

资源/缓存/LIST 字节预算仍非 RSS 上限。一次响应页的解码分配受 Transport
响应上限约束，汇总快照与缓存替换仍有短暂共存；进程需要容器内存限额。
调用方使用不同 Store 容量时应同步调整 Client::list 参数。

## 使用及迁移

精确 API 见生成的 `.mbti` 和 [API 迁移](api-design.md)。应用必须区分
FinalizeResult：只有 FinalizerAdded/CleanupPending 安排延迟重试；删除完成
与不再负责都返回 Controller Complete。业务回调异常按 Worker 策略处理。
Queue/Parser 构造函数现在可能返回 Invalid；穷举错误匹配需加入新的容量类型。
自定义资源作用域必须由可信注册或 API discovery 提供，不是依赖 namespace 猜测。

生产镜像构建：

```sh
moon build cmd/moonapp --target native --release
docker build --target production -t moonoperator:dev .
```

诊断 NetworkPolicy 必须在同 namespace 应用。需要 CNI 执行策略；本轮 Kind
只验证清单可被 API 接受，不代表默认 Kind 网络已验证流量隔离。
示例负载必须兼容非 root；不把任意用户镜像“创建 Deployment 成功”当成业务服务就绪。
镜像和快照固定后必须定期审查并更新，否则不会自动获得安全补丁。

## 验证范围与未完成发布门槛

本地已运行新增/受影响文件的原生定向回归及 moon check、fmt、info；未运行全量测试。
CI 继续验证限定的原生回归、真实 Kind 客户端/生命周期和受限 WASM 探针。
最终 CI 链接与对应提交会补充到本记录；失败不记为通过。

长期 RSS/soak、更广 Kubernetes/认证矩阵、策略型 CNI 流量验证、完整分发物
SBOM/OS 漏洞扫描与 Mooncakes 发布仍是已有发布门槛，本轮不宣称达到稳定 1.0。

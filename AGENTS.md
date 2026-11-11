# Clash/Mihomo 代理配置项目 - AI 上下文文档

> 个人使用的 mihomo 内核配置文件, 适用于 Windows/Linux/macOS 等平台.
>
> **详细的项目说明、使用指南、配置特性请查看 [README.md](./README.md)**

## 项目概览

Mihomo (Clash Meta) 内核配置仓库, 核心特性:
- DNS 防泄露 (Fake-IP IPv4/IPv6 + respect-rules + TUN 严格路由)
- 精细化分流 (8 层规则体系)
- 自动化节点选择 (URL-Test 测速; Fallback/负载均衡锚点已预置, 按需启用)
- 局域网接入 (allow-lan) + 内网 HTTP 代理节点
- Git 提交自动脱敏 (本地 clean/smudge filter 清洗 secret 与订阅 URL)

**关键文件:**
- `mihomo.yaml` - 主配置文件 (工作区含真实 secret/订阅 URL, 仓库提交版本为脱敏占位版)
- `mihomo-manager.ps1` - Windows 管理脚本 (启停/重载/延迟测试)
- `Ruleset/` - 自定义规则集模块
- `scripts/` - Git 自动脱敏工具 (filter 安装 + clean/smudge 逻辑)

## 模块索引

| 模块 | 路径 | 职责 | 状态 |
|------|------|------|------|
| 根配置 | `/` | mihomo 主配置、订阅、策略组、规则体系 | 活跃 |
| [Ruleset](./Ruleset/AGENTS.md) | `Ruleset/` | 自定义代理/直连规则列表 | 活跃 |
| [scripts](./scripts/) | `scripts/` | Git filter 脱敏 (setup-git-filter.sh + mihomo_git_filter.py) | 活跃 |

## 快速参考

**启动与管理:**
- Linux/macOS: `./mihomo -d . -f mihomo.yaml`
- Windows: `.\mihomo-manager.ps1` (交互菜单) 或 `.\mihomo-manager.ps1 start` (命令行, 非管理员自动 UAC 提权)
- 详细说明见 [README.md - 快速开始](./README.md#快速开始)

**关键端口:**
- 混合代理: `127.0.0.1:7890` (HTTP/SOCKS5; allow-lan 启用后局域网设备可用局域网 IP 接入)
- Web UI: `http://127.0.0.1:9090/ui` (密码为 `mihomo.yaml` 的 `secret` 字段值, 仓库提交版本默认 `123456`)
- DNS: `:1053`

## ⛔ 强制要求: Git 提交脱敏验证

每次 `git commit` (尤其涉及 `mihomo.yaml` 时) **必须**完成以下验证, 缺一不可:

1. **提交前确认 filter 已生效**

   ```bash
   git config --get filter.mihomo-secrets.clean
   # 期望输出: python3 scripts/mihomo_git_filter.py clean
   # 无输出 = 未安装, 先执行:
   bash scripts/setup-git-filter.sh
   git add --renormalize "mihomo.yaml"
   ```

   注意: filter 只写入本地 `.git/config`, **不随仓库分发**, 新环境/新 clone 后必须先自行安装才能提交.

2. **提交后验证暂存区与提交内容已脱敏**

   ```bash
   git show :"mihomo.yaml" | grep -nE "secret:|url:"    # 暂存区
   git show HEAD:mihomo.yaml | grep -nE "secret:|url:"  # 最近一次提交
   # 期望: 只出现占位符 (secret: 123456 / url: '---'), 不得出现真实 secret 或订阅 URL
   ```

3. **验证失败时 (提交含真实敏感信息)**: 立即停止推送; 未 push 的提交用 `git reset --soft HEAD~1` 撤销, 确认 filter 生效后重新提交; 若已 push, 需重写历史 (如 `git filter-repo`) 清除敏感信息.

**背景:** clean filter 只作用于暂存区, 所以 `git status` 里 `mihomo.yaml` 可能长期显示"有修改"属正常现象, 以 `git diff --cached` / `git show` 为准. `git checkout/pull` 会把仓库脱敏版本写回工作区.

## AI 使用指引

### 常见任务

1. **添加代理规则**: 编辑 `Ruleset/Proxy.list`
2. **添加直连规则**: 编辑 `Ruleset/Direct.list`
3. **修改策略组行为**: 编辑 `mihomo.yaml` 的 `proxy-groups` 部分 (注意共享锚点 `*UrlTest`/`*Select`/`*pg_Proxy`/`*pg_Direct`, 改动影响面大)
4. **添加新订阅**: 在 `proxy-providers` 下添加新条目 (继承 `<<: *NodeParam`)
5. **Windows 启动/管理**: 使用 `mihomo-manager.ps1` 脚本
6. **测试 URL 延迟**: 使用 `test` 命令对比不同节点的真实访问速度
7. **提交代码**: 必须先满足「强制要求: Git 提交脱敏验证」章节 (filter 生效 + 提交后脱敏验证)

### 关键配置位置

> 行号基于当前 `mihomo.yaml` (358 行) 与 `mihomo-manager.ps1` (627 行); 文件变动后行号会漂移, 以功能列的锚点/grep 结果为准.

| 功能 | 文件 | 行号 |
|------|------|------|
| 订阅地址 (xsus) | `mihomo.yaml` | 36-39 |
| 地区筛选 (FilterUS/JP/SG/TW/HK/Exclude) | `mihomo.yaml` | 116-121 |
| 策略组锚点 (Select/UrlTest/FallBack/LoadBalance) | `mihomo.yaml` | 128-131 |
| 节点锚点 (pg_Proxy/pg_Direct) | `mihomo.yaml` | 139-149 |
| 策略组定义 | `mihomo.yaml` | 150-187 |
| 规则列表 (8 层) | `mihomo.yaml` | 188-253 |
| 规则集引用 (rule-providers) | `mihomo.yaml` | 262-358 |
| DNS 配置 | `mihomo.yaml` | 61-80 |
| 管理脚本配置区 (路径/端口/Secret 读取) | `mihomo-manager.ps1` | 101-199 |

### 注意事项

- 工作区 `mihomo.yaml` 含真实 secret 与订阅 URL; 仓库提交版本是脱敏占位 (`secret: 123456` / `url: '---'`), 不要把真实配置直接贴进提交记录, 也不要绕过 filter 强制提交
- `git checkout/pull` 会用仓库脱敏版本覆盖工作区; 建议真实配置在别处备份维护
- 规则顺序影响匹配优先级 (第一层优先级最高)
- 管理脚本 Secret 优先级: `MIHOMO_SECRET` 环境变量 > `mihomo.yaml` 的 `secret` 字段 > 默认值 `123456`

### 详细文档引用

- **配置特性说明**: [README.md - 配置特性](./README.md#配置特性)
- **DNS 防泄露原理**: [README.md - DNS 配置](./README.md#dns-配置)
- **规则体系详解**: [README.md - 规则体系](./README.md#规则体系)
- **高级配置选项**: [README.md - 高级配置](./README.md#高级配置)
- **常见问题解答**: [README.md - 常见问题](./README.md#常见问题)

## 变更记录 (Changelog)

| 时间 | 操作 | 说明 |
|------|------|------|
| 2026-11-11 15:16:49 | 删除 | 移除已弃用的 `lvbibir.ini` 文件, 并清理 README.md (项目结构、参考资料) 与 AGENTS.md (注意事项) 中的相关引用 |
| 2026-11-11 11:47:50 | 更新+新增 | 同步项目现状 (IPv6 Fake-IP、allow-lan、内网代理、scripts 模块); 刷新关键配置行号; 修正 README 锚点链接; 移除不存在的「编码规范」引用; 新增「Git 提交脱敏验证」强制要求 |
| 2026-01-19 14:30:00 | 精简 | 移除与 README.md 重复的详细说明, 添加文档引用链接 |
| 2026-01-19 12:11:59 | 创建 | 初始化 AI 上下文文档系统 |

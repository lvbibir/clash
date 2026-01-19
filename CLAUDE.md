# Clash/Mihomo 代理配置项目 - AI 上下文文档

> 个人使用的 mihomo 内核配置文件, 适用于 Windows/Linux/macOS 等平台.
>
> **详细的项目说明、使用指南、配置特性请查看 [README.md](./README.md)**

## 项目概览

Mihomo (Clash Meta) 内核配置仓库, 核心特性:
- DNS 防泄露 (Fake-IP + respect-rules + TUN 严格路由)
- 精细化分流 (8 层规则体系)
- 自动化节点选择 (URL-Test / Fallback)

**关键文件:**
- `mihomo.yaml` - 主配置文件
- `mihomo-manager.ps1` - Windows 管理脚本 (启停/重载/延迟测试)
- `Ruleset/` - 自定义规则集模块

## 模块索引

| 模块 | 路径 | 职责 | 状态 |
|------|------|------|------|
| 根配置 | `/` | mihomo 主配置、订阅、策略组、规则体系 | 活跃 |
| [Ruleset](./Ruleset/CLAUDE.md) | `Ruleset/` | 自定义代理/直连规则列表 | 活跃 |

## 快速参考

**启动与管理:**
- Linux/macOS: `./mihomo -d . -f mihomo.yaml`
- Windows: `.\mihomo-manager.ps1` (交互菜单) 或 `.\mihomo-manager.ps1 start` (命令行)
- 详细说明见 [README.md - 快速开始](./README.md#-快速开始)

**关键端口:**
- 混合代理: `127.0.0.1:7890` (HTTP/SOCKS5)
- Web UI: `http://127.0.0.1:9090/ui` (密码: `123456`)
- DNS: `0.0.0.0:1053`

## AI 使用指引

### 常见任务

1. **添加代理规则**: 编辑 `Ruleset/Proxy.list`
2. **添加直连规则**: 编辑 `Ruleset/Direct.list`
3. **修改策略组行为**: 编辑 `mihomo.yaml` 的 `proxy-groups` 部分
4. **添加新订阅**: 在 `proxy-providers` 下添加新条目
5. **Windows 启动/管理**: 使用 `mihomo-manager.ps1` 脚本
6. **测试 URL 延迟**: 使用 `test` 命令对比不同节点的真实访问速度

### 关键配置位置

| 功能 | 文件 | 行号 |
|------|------|------|
| 订阅地址 | `mihomo.yaml` | 41-44 |
| 策略组定义 | `mihomo.yaml` | 161-195 |
| 规则列表 | `mihomo.yaml` | 197-274 |
| 规则集引用 | `mihomo.yaml` | 283-379 |
| DNS 配置 | `mihomo.yaml` | 68-86 |
| 管理脚本配置区 | `mihomo-manager.ps1` | 36-46 |

### 注意事项

- `lvbibir.ini` 已弃用, 仅供参考
- 订阅地址 (`url: '---'`) 需手动替换
- 规则顺序影响匹配优先级 (第一层优先级最高)

### 详细文档引用

- **配置特性说明**: [README.md - 配置特性](./README.md#-配置特性)
- **DNS 防泄露原理**: [README.md - DNS 配置](./README.md#dns-配置)
- **规则体系详解**: [README.md - 规则体系](./README.md#规则体系)
- **高级配置选项**: [README.md - 高级配置](./README.md#-高级配置)
- **常见问题解答**: [README.md - 常见问题](./README.md#-常见问题)
- **编码规范**: [README.md - 编码规范](./README.md#编码规范)

## 变更记录 (Changelog)

| 时间 | 操作 | 说明 |
|------|------|------|
| 2026-01-19 14:30:00 | 精简 | 移除与 README.md 重复的详细说明, 添加文档引用链接 |
| 2026-01-19 12:11:59 | 创建 | 初始化 AI 上下文文档系统 |

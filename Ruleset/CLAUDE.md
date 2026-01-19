[根目录](../CLAUDE.md) > **Ruleset**

# Ruleset 模块

> 自定义分流规则集, 用于补充 mihomo 内置规则.

## 模块职责

- 管理用户自定义的代理规则 (`Proxy.list`)
- 管理用户自定义的直连规则 (`Direct.list`)
- 优先级高于内置规则 (在 `mihomo.yaml` 规则体系中位于第二层)

## 入口与启动

本模块为静态规则文件, 无需启动. 被 `mihomo.yaml` 通过 `rule-providers` 引用:

```yaml
# mihomo.yaml 中的引用配置
rule-providers:
  custom_proxy:
    url: "https://raw.githubusercontent.com/lvbibir/clash/.../Ruleset/Proxy.list"
    path: ./rule-providers/custom_proxy.list
  custom_direct:
    url: "https://raw.githubusercontent.com/lvbibir/clash/.../Ruleset/Direct.list"
    path: ./rule-providers/custom_direct.list
```

## 对外接口

### 规则格式

每个 `.list` 文件包含多条规则, 每行一条:

```
TYPE,VALUE[,OPTIONS]
```

### 支持的规则类型

| TYPE | 说明 | 示例 |
|------|------|------|
| `DOMAIN` | 精确域名匹配 | `DOMAIN,www.example.com` |
| `DOMAIN-SUFFIX` | 域名后缀匹配 | `DOMAIN-SUFFIX,example.com` |
| `DOMAIN-KEYWORD` | 域名关键词匹配 | `DOMAIN-KEYWORD,example` |
| `IP-CIDR` | IP 段匹配 | `IP-CIDR,192.168.1.0/24,no-resolve` |
| `PROCESS-NAME` | 进程名匹配 | `PROCESS-NAME,OneDrive.exe` |

### 可选 OPTIONS

- `no-resolve`: 跳过 DNS 解析 (用于 IP 规则)

## 关键依赖与配置

### 依赖关系

- 被 `mihomo.yaml` 的 `rule-providers` 引用
- 需要 mihomo 内核版本支持 `classical` 格式的规则集

### 配置参数

在 `mihomo.yaml` 中:
```yaml
RuleSet_classical_text: &RuleSet_classical_text
  type: http
  behavior: classical
  interval: 43200        # 12 小时更新一次
  format: text
```

## 数据模型

### Proxy.list (114 行)

当前包含的规则分类:
- 公益站点
- VSCode 同步服务
- 漫画站点 (copymanga 等)
- 机场订阅域名
- Steam 社区/登录
- 资源站 (unpkg, dmhy, bangumi 等)
- 技术网站 (kubernetes, helm, hugo 等)
- 博客站点
- OneDrive 网页端
- 订阅转换 API
- 其他

### Direct.list (5 行)

当前包含:
- `daxiaamu.com` (直连域名示例)

## 测试与质量

### 验证方法

1. 修改规则后重启 mihomo 或等待规则集自动更新
2. 使用 `log-level: debug` 查看规则匹配日志
3. 访问目标网站验证分流是否生效

### 常见问题排查

- 规则不生效: 检查规则格式是否正确, TYPE 是否支持
- 优先级问题: 确认规则在 `mihomo.yaml` 的 rules 列表中位置

## 常见问题 (FAQ)

### Q: 如何添加新的代理规则?

在 `Proxy.list` 末尾添加新行:
```
DOMAIN-SUFFIX,newsite.com
```

### Q: 如何让某个域名直连?

在 `Direct.list` 中添加:
```
DOMAIN-SUFFIX,directsite.com
```

### Q: 规则多久生效?

- 本地修改: 重启 mihomo 立即生效
- 远程更新: 默认 12 小时 (`interval: 43200`)

## 相关文件清单

| 文件 | 说明 |
|------|------|
| `Proxy.list` | 代理规则列表 (114 行) |
| `Direct.list` | 直连规则列表 (5 行) |

## 变更记录 (Changelog)

| 时间 | 操作 | 说明 |
|------|------|------|
| 2026-01-19 12:11:59 | 创建 | 初始化模块 AI 上下文文档 |

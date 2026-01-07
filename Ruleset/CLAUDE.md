# Ruleset 模块 - 自定义分流规则

[根目录](../CLAUDE.md) > **Ruleset**

> 最后更新：2026-01-07 22:06:55

## 变更记录 (Changelog)

### 2026-01-07
- 初始化模块文档

---

## 模块职责

Ruleset 模块负责提供**用户自定义分流规则**，允许用户根据个人需求定制域名和 IP 的路由策略。规则文件采用 Clash 的 Text 格式，优先级高于内置规则集。

### 核心功能

1. **自定义代理规则** (`Proxy.list`):
   - 强制特定域名/IP 走代理通道
   - 适用场景：国外网站、技术资源站、个人订阅服务等

2. **自定义直连规则** (`Direct.list`):
   - 强制特定域名/IP 直连
   - 适用场景：局域网设备、国内加速服务、特殊兼容性需求

### 在规则体系中的位置

在 `mihomo.yaml` 的 8 层规则体系中，Ruleset 位于**第二层**（仅次于特殊处理规则）：

```
规则匹配顺序:
  1. 特殊处理 (REJECT/DNS路由)
  2. 自定义规则 (Ruleset) ← 本模块
  3. 局域网/私有地址
  4. 高频直连服务
  5. 特定应用代理
  6. 通用大厂代理
  7. 国内规则
  8. 兜底规则
```

---

## 入口与启动

本模块作为配置文件被 `mihomo.yaml` 引用，无独立启动流程。

### 加载方式

在 `mihomo.yaml:286-293` 中定义：

```yaml
rule-providers:
  custom_proxy:
    <<: *RuleSet_classical_text
    url: "https://raw.githubusercontent.com/lvbibir/clash/refs/heads/master/Ruleset/Proxy.list"
    path: ./rule-providers/custom_proxy.list
  custom_direct:
    <<: *RuleSet_classical_text
    url: "https://raw.githubusercontent.com/lvbibir/clash/refs/heads/master/Ruleset/Direct.list"
    path: ./rule-providers/custom_direct.list
```

### 规则应用位置

在 `mihomo.yaml:217-218` 中应用：

```yaml
rules:
  # 第二层：自定义规则（优先级最高）
  - RULE-SET,custom_proxy,🚀 默认代理
  - RULE-SET,custom_direct,直连
```

---

## 对外接口

### 规则语法接口

支持的规则类型（Clash Classical 格式）：

1. **域名规则**:
   ```
   DOMAIN,www.example.com          # 精确匹配域名
   DOMAIN-SUFFIX,example.com       # 匹配域名及所有子域名
   DOMAIN-KEYWORD,example           # 域名包含关键词
   ```

2. **IP 规则**:
   ```
   IP-CIDR,192.168.1.0/24          # IP 段匹配
   IP-CIDR,192.168.1.0/24,no-resolve  # 不解析域名，直接匹配 IP
   ```

3. **进程规则** (部分平台支持):
   ```
   PROCESS-NAME,OneDrive.exe       # 匹配进程名称
   ```

### 注释语法

```
# 单行注释
# === 分类标题 ===
```

---

## 关键依赖与配置

### 依赖项

- **上游配置**: `mihomo.yaml` (定义 rule-providers)
- **mihomo 内核**: 版本需支持 `classical` behavior
- **网络连接**: 首次启动时从 GitHub 下载规则文件

### 配置参数

在 `mihomo.yaml:277` 定义的锚点参数：

```yaml
RuleSet_classical_text: &RuleSet_classical_text
  type: http                  # 通过 HTTP 下载规则
  behavior: classical         # 经典格式（支持所有规则类型）
  interval: 43200             # 更新间隔 12 小时
  format: text                # 文本格式
```

### 本地缓存路径

规则文件下载后缓存在：
- `./rule-providers/custom_proxy.list`
- `./rule-providers/custom_direct.list`

---

## 数据模型

### Proxy.list 数据结构

当前包含的规则类别：

1. **国外 DNS 服务器** (已注释):
   - Cloudflare, Google, Quad9 等
   - 用于确保 DNS 查询走代理

2. **公益站点**:
   - `224442.xyz`, `668556.xyz`
   - Cloudflare Insights

3. **技术开发**:
   - VSCode 设置同步
   - Jenkins, Kubernetes, Helm
   - Notion, Ghost, Traefik

4. **Steam 社区**:
   - `steamcommunity.com`
   - `api.steampowered.com`
   - `login.steampowered.com`

5. **资源站点**:
   - 动漫下载站 (dmhy.org, acg.rip)
   - 音乐数据库 (last.fm, musicbrainz.org)
   - 游戏资源 (steamdb.info, thunderstore.io)

6. **个人博客**:
   - limbopro.xyz, merlinblog.xyz
   - yattazen.com, sctux.com

7. **订阅转换 API**:
   - bianyuan.xyz, dler.io

8. **漫画/娱乐** (18+):
   - copymanga, mangafuna
   - 91porn, e-hentai, netflav

### Direct.list 数据结构

当前仅包含注释示例：
```
# onedrive
# PROCESS-NAME,OneDrive.exe
```

---

## 测试与质量

### 测试方法

1. **规则语法验证**:
   ```bash
   # 启动 mihomo 时会自动验证规则语法
   ./mihomo -t -d . -f mihomo.yaml
   ```

2. **规则匹配测试**:
   - 访问 Dashboard: `http://127.0.0.1:9090/ui`
   - 进入 Logs 标签页
   - 访问目标网站，观察日志中的规则匹配结果

3. **规则优先级测试**:
   - 添加与其他规则集冲突的规则
   - 确认自定义规则生效（应优先于内置规则）

### 质量保证

- **语法规范**: 遵循 Clash Classical 格式
- **注释规范**: 分类注释使用 `# === 类别 ===`
- **版本控制**: 通过 Git 跟踪所有变更
- **自动更新**: mihomo 每 12 小时自动更新规则集

---

## 常见问题 (FAQ)

### 1. 如何添加新规则？

编辑对应文件后，重载配置：

```bash
# Linux/macOS
curl -X PUT http://127.0.0.1:9090/configs?force=true \
  -H "Authorization: Bearer 123456"

# Windows PowerShell
.\mihomo-manager.ps1 reload
```

### 2. 规则不生效怎么办？

检查清单：
1. 确认规则语法正确（查看 mihomo 日志）
2. 确认规则位于正确的文件（Proxy.list vs Direct.list）
3. 确认规则未被后续规则覆盖（优先级问题）
4. 尝试清除 DNS 缓存：`ipconfig /flushdns` (Windows) 或 `sudo systemd-resolve --flush-caches` (Linux)

### 3. IP-CIDR 规则何时使用 no-resolve？

- **使用 no-resolve**: 已知目标 IP 段，跳过 DNS 解析，提升性能
- **不使用**: 需要先解析域名为 IP，再匹配 IP 段

示例：
```
# 局域网 IP 直连（不需要解析）
IP-CIDR,192.168.0.0/16,no-resolve

# 特定服务的 IP 段（可能需要解析）
IP-CIDR,1.1.1.0/24
```

### 4. 如何临时禁用某条规则？

在规则前添加 `#` 注释：
```
# DOMAIN-SUFFIX,example.com  # 临时禁用
```

### 5. 规则更新频率是多少？

- **本地修改**: 立即生效（需重载配置）
- **远程更新**: 12 小时自动从 GitHub 拉取
- **手动更新**: 重启 mihomo 强制更新

---

## 相关文件清单

### 核心文件

| 文件名 | 路径 | 用途 | 行数 |
|--------|------|------|------|
| `Proxy.list` | `/home/lvbibir/clash/Ruleset/Proxy.list` | 代理规则定义 | 114 |
| `Direct.list` | `/home/lvbibir/clash/Ruleset/Direct.list` | 直连规则定义 | 3 |

### 引用位置

- **规则集定义**: `mihomo.yaml:286-293`
- **规则应用**: `mihomo.yaml:217-218`

---

## 最佳实践

### 规则组织建议

1. **使用注释分类**:
   ```
   # === 技术网站 ===
   DOMAIN-SUFFIX,github.com
   DOMAIN-SUFFIX,stackoverflow.com

   # === 娱乐资源 ===
   DOMAIN-SUFFIX,youtube.com
   ```

2. **优先使用 DOMAIN-SUFFIX**:
   - 比 DOMAIN-KEYWORD 更精确
   - 性能更好

3. **敏感规则使用精确匹配**:
   ```
   # 推荐
   DOMAIN,api.example.com
   DOMAIN-SUFFIX,example.com

   # 避免（可能误匹配）
   DOMAIN-KEYWORD,example
   ```

4. **IP 规则放在域名规则后**:
   - 域名匹配更快
   - 减少不必要的 IP 解析

### 维护建议

1. **定期清理无效规则**: 移除已失效的域名
2. **测试新规则**: 添加规则后验证是否生效
3. **备份规则文件**: 重大修改前备份
4. **记录规则来源**: 在注释中说明规则的用途

---

## 扩展阅读

- [Clash 规则语法文档](https://wiki.metacubex.one/config/rules/)
- [规则集最佳实践](https://wiki.metacubex.one/config/rule-providers/)
- [DNS 泄露与规则优先级](../plans/dns-leak-analysis.md)

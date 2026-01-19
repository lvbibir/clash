# Mihomo 配置文件

个人使用的 mihomo 内核配置文件，适用于 Windows/Linux/macOS 等平台。

## 📁 项目结构

```
.
├── LICENSE
├── README.md
├── lvbibir.ini                 # ini 格式的 clash 配置文件 (⚠️已弃用, 不再更新)
├── mihomo-manager.ps1          # Windows 管理脚本 (启停/重载/延迟测试)
├── mihomo.yaml                 # mihomo 内核配置文件
└── Ruleset/                    # 自用 clash 分流规则
    ├── Direct.list             # 直连规则列表
    └── Proxy.list              # 代理规则列表
```

## ✨ 配置特性

### 核心特性

- **🔒 DNS 防泄露**: 基于 Fake-IP + respect-rules + TUN 严格路由的多重防护机制
- **🚀 性能优化**: TCP 并发、连接复用、ARC 缓存算法
- **🎯 精细分流**: 8 层规则体系，按优先级和使用频率优化
- **🌐 地区策略**: 支持美国/日本/新加坡/台湾/香港节点分组
- **⚡ 自动切换**: URL-Test 自动测速、Fallback 故障转移
- **🛡️ 智能嗅探**: HTTP/TLS/QUIC 协议嗅探，准确识别域名

### 代理模式

#### 节点策略组

| 策略组类型 | 说明 |
|-----------|------|
| ♻️ 自动选择 | URL-Test 模式，自动选择延迟最低的节点 |
| 🌐 全部节点 | 手动选择模式，可从所有节点中选择 |
| 🔯 故障转移 | Fallback 模式，自动切换到可用节点 |
| 🇺🇸/🇯🇵/🇸🇬/🇹🇼/🇭🇰 | 按地区筛选的节点组 |

#### 功能策略组

| 策略组 | 默认策略 | 说明 |
|--------|---------|------|
| 🚀 默认代理 | 优先自动选择 | 未匹配规则的流量 |
| 🤖 AIGC | 美国故障转移 | ChatGPT/Claude 等 AI 服务 |
| 🍀 Google | 美国故障转移 | Google 全家桶服务 |
| 👨🏿‍💻 GitHub | 优先代理 | GitHub 相关服务 |
| ✖️ X | 优先代理 | X (Twitter) 服务 |
| ✈️ Telegram | 优先代理 | Telegram 服务 |
| 📹 YouTube | 优先代理 | YouTube 服务 |
| 🎧 Sony | 优先代理 | Sony 娱乐服务 |
| 🎮 Steam | 优先直连 | Steam 游戏平台 |
| 🐬 OneDrive | 优先直连 | OneDrive 云存储 |
| Ⓜ️ Microsoft | 优先直连 | Microsoft 服务 |
| 🐟 漏网之鱼 | 跟随默认代理 | 白名单模式兜底 |

### DNS 配置

#### 防泄露机制

配置采用 **Fake-IP 模式 + respect-rules** 组合，实现完整的 DNS 防泄露：

1. **Fake-IP 模式**: 应用获得虚拟 IP，真实 DNS 查询由 mihomo 控制
2. **respect-rules**: DNS 查询遵循路由规则，代理域名的 DNS 通过代理发送
3. **TUN 严格路由**: 劫持所有端口 53 流量，防止 DNS 绕过
4. **分层解析器**: 代理服务器/直连域名/默认域名使用不同的 DNS 策略

#### DNS 服务器

```yaml
nameserver:
  - https://223.5.5.5/dns-query    # 阿里 DoH
  - https://doh.pub/dns-query      # 腾讯 DoH

proxy-server-nameserver:
  - https://223.5.5.5/dns-query    # 解析代理服务器域名
  - https://doh.pub/dns-query
```

**为什么可以使用国内 DNS？**

传统认知认为必须使用国外 DNS (1.1.1.1/8.8.8.8) 才能防止泄露，但在 mihomo 的 Fake-IP + respect-rules 模式下：

- DNS 查询的路由由 **rules 规则**决定，而非 DNS 服务器的位置
- 访问国外域名时，DNS 查询会通过代理隧道发送，即使目标是国内 DNS
- ISP 只能看到加密的代理流量，无法知道 DNS 查询内容
- 使用国内 DNS 的优势：延迟低、稳定性好、配置简洁

### 规则体系

8 层规则体系，按优先级从高到低：

| 层级 | 类型 | 说明 |
|-----|------|------|
| 第一层 | 特殊处理 | REJECT 规则、DNS 服务器路由 |
| 第二层 | 自定义规则 | 用户自定义的代理/直连规则 |
| 第三层 | 局域网/私有地址 | 防止回环和内网泄露 |
| 第四层 | 高频直连服务 | Apple、Speedtest 等 |
| 第五层 | 特定应用代理 | AIGC、GitHub、X、Telegram 等 |
| 第六层 | 通用大厂代理 | Google、YouTube |
| 第七层 | 国内规则 | CN 域名和 IP |
| 第八层 | 兜底规则 | 非中国域名、漏网之鱼 |

### 性能优化

```yaml
# TCP 优化
tcp-concurrent: true              # TCP 并发
keep-alive-idle: 600              # TCP keepalive 空闲时间
keep-alive-interval: 15           # TCP keepalive 间隔

# DNS 优化
dns:
  cache-algorithm: arc            # ARC 缓存算法 (优于 LRU)
  enhanced-mode: fake-ip          # Fake-IP 模式，减少 DNS 查询

# 连接优化
unified-delay: true               # 统一延迟测试
find-process-mode: strict         # 严格进程匹配
```

### 嗅探配置

```yaml
sniffer:
  enable: true
  parse-pure-ip: true             # 处理纯 IP 请求
  sniff:
    HTTP:                         # HTTP 嗅探
      ports: [80, 8080-8880]
      override-destination: true
    TLS:                          # TLS/HTTPS 嗅探
      ports: [443, 8443]
    QUIC:                         # QUIC 嗅探
      ports: [443, 8443]
```

**嗅探作用**:
- 从 HTTP/TLS/QUIC 流量中提取真实域名
- 即使应用使用 IP 直连，也能应用域名规则
- 提高规则匹配的准确性

## 🚀 快速开始

### 1. 下载配置文件

```bash
# 下载主配置
wget https://raw.githubusercontent.com/lvbibir/clash/master/mihomo.yaml

# 或使用 git clone
git clone https://github.com/lvbibir/clash.git
cd clash
```

### 2. 修改订阅

编辑 [`mihomo.yaml`](mihomo.yaml:41-44)，替换为你的订阅地址：

```yaml
proxy-providers:
  150G_Mouth:
    <<: *NodeParam
    url: '你的订阅地址'  # 修改此处
    path: './proxy-providers/providers-1.yaml'
```

### 3. 启动 mihomo

#### Linux/macOS

```bash
# 下载 mihomo 内核
wget https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-amd64 -O mihomo
chmod +x mihomo

# 启动
./mihomo -d . -f mihomo.yaml
```

#### Windows

**使用管理脚本 (推荐)**

本项目提供了 PowerShell 管理脚本，支持交互菜单和命令行两种模式：

```powershell
# 交互菜单模式
.\mihomo-manager.ps1

# 命令行模式
.\mihomo-manager.ps1 start     # 启动服务
.\mihomo-manager.ps1 stop      # 停止服务
.\mihomo-manager.ps1 restart   # 重启服务
.\mihomo-manager.ps1 status    # 查看状态
.\mihomo-manager.ps1 reload    # 重载配置
.\mihomo-manager.ps1 test https://www.google.com  # 测试 URL 延迟

# 环境变量 (可选)
$env:MIHOMO_SECRET = "your_secret"  # 设置 API 密钥
```

**延迟测试功能**

`test` 命令可以测试指定 URL 在不同策略组下的实际访问延迟：

- 自动测试直连和各地区代理节点 (美国/日本/狮城/台湾/香港)
- 使用 Mihomo 内置延迟测试 API，测量真实连接延迟
- 自动识别最快节点并提供推荐
- 支持自定义测试 URL

```powershell
# 测试示例
.\mihomo-manager.ps1 test https://www.google.com
.\mihomo-manager.ps1 test https://www.youtube.com
.\mihomo-manager.ps1 test https://github.com
```

**手动部署**

详细的手动部署步骤请参考博客文章: [mihomo 裸核部署 - Windows 端](https://www.lvbibir.cn/posts/tech/mihomo-core-only-setup)

### 4. 配置系统代理

- **HTTP/HTTPS 代理**: `127.0.0.1:7890`
- **SOCKS5 代理**: `127.0.0.1:7890` (mixed-port 同时支持)
- **Web Dashboard**: `http://127.0.0.1:9090/ui` (密码: `123456`)

## 📝 自定义规则

### 添加自定义代理规则

编辑 [`Ruleset/Proxy.list`](Ruleset/Proxy.list)：

```yaml
# 域名规则
DOMAIN-SUFFIX,example.com
DOMAIN,www.example.com
DOMAIN-KEYWORD,example

# IP 规则
IP-CIDR,192.168.1.0/24
```

### 添加自定义直连规则

编辑 [`Ruleset/Direct.list`](Ruleset/Direct.list)：

```yaml
# 国内域名
DOMAIN-SUFFIX,baidu.com
DOMAIN,www.taobao.com

# 局域网
IP-CIDR,192.168.0.0/16
IP-CIDR,10.0.0.0/8
```

## 🔧 高级配置

### 启用 GeoDat 模式

如需使用 `GEOSITE` / `GEOIP` 规则，取消 [`mihomo.yaml:29-34`](mihomo.yaml:29-34) 的注释：

```yaml
geodata-mode: true
geodata-loader: memconservative
geo-update-interval: 24
geox-url:
  geosite: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
  geoip: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
```

### 添加备用订阅

取消 [`mihomo.yaml:47-52`](mihomo.yaml:47-52) 的注释：

```yaml
500G_LongTerm:
  <<: *NodeParam
  url: '备用订阅地址'
  path: './proxy-providers/providers-2.yaml'
  override:
    additional-prefix: "1.备 "
```

### 调整日志级别

修改 [`mihomo.yaml:9`](mihomo.yaml:9) 的 `log-level`:

- `silent`: 静默
- `error`: 仅错误
- `warning`: 警告 (默认)
- `info`: 信息
- `debug`: 调试

### 修改 Web Dashboard

配置使用 Zashboard 作为 Web UI，可替换为其他 UI：

```yaml
external-ui-name: metacubexd  # 或其他 UI
external-ui-url: https://github.com/metacubex/metacubexd/archive/refs/heads/gh-pages.zip
```

## 📊 规则集来源

分流规则配置使用 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) 的规则集
Fake-IP 过滤黑名单使用 [ShellCrash](https://github.com/juewuy/ShellCrash/blob/dev/public/fake_ip_filter.list) 规则集

### 域名规则集 (MRS 格式)

- `private_domain`: 私有域名
- `cn_domain`: 中国域名
- `geolocation-!cn_domain`: 非中国域名
- `ai_domain`: AI 服务 (ChatGPT/Claude/Gemini 等)
- `google_domain`: Google 全家桶
- `youtube_domain`: YouTube
- `github_domain`: GitHub
- `microsoft_domain`: Microsoft
- `apple_domain`: Apple
- `x_domain`: X (Twitter)
- `telegram_domain`: Telegram
- `steam_domain`: Steam
- `sony_domain`: Sony
- `onedrive_domain`: OneDrive
- `speedtest_domain`: Speedtest

### IP 规则集 (MRS 格式)

- `private_ip`: 私有 IP 段
- `cn_ip`: 中国 IP 段
- `google_ip`: Google IP
- `apple_ip`: Apple IP
- `telegram_ip`: Telegram IP

### 自定义规则集 (Text 格式)

- `custom_proxy`: 自定义代理规则 ([`Ruleset/Proxy.list`](Ruleset/Proxy.list))
- `custom_direct`: 自定义直连规则 ([`Ruleset/Direct.list`](Ruleset/Direct.list))

## 🔍 常见问题

### 1. 为什么使用国内 DNS 也不会泄露？

因为 Fake-IP + respect-rules 机制：
- 应用获得的是虚拟 IP，不会直接触发 DNS 查询
- 真实 DNS 查询由 mihomo 根据规则路由
- 代理域名的 DNS 查询会通过代理隧道发送
- ISP 只能看到加密的代理流量

详细分析见 [`plans/dns-leak-analysis.md`](plans/dns-leak-analysis.md)

### 2. 如何验证 DNS 是否泄露？

访问以下网站测试：
- https://dnsleaktest.com/
- https://www.dnsleak.com/
- https://ipleak.net/

**预期结果**: 应显示代理服务器所在地的 DNS，而非本地 ISP 的 DNS

### 3. 为什么某些网站无法访问？

可能是 Fake-IP 模式的兼容性问题，检查 [`mihomo.yaml:79-80`](mihomo.yaml:79-80) 的 `fake-ip-filter`。

需要直连的域名可添加到 [`Ruleset/Direct.list`](Ruleset/Direct.list)。

### 4. 如何查看当前使用的节点？

访问 Web Dashboard: `http://127.0.0.1:9090/ui`

或使用 API:
```bash
curl http://127.0.0.1:9090/proxies
```

### 5. 节点自动切换的逻辑是什么？

- **URL-Test 模式**: 每 300 秒测速，选择延迟最低的节点 (容差 50ms)
- **Fallback 模式**: 主节点失败后自动切换到备用节点
- **健康检查**: 超时 2 秒判定失败，连续失败 3 次触发主动检查

详见 [`mihomo.yaml:138-139`](mihomo.yaml:138-139)

### 6. 如何测试不同节点的实际访问速度？

**Windows 用户**可以使用管理脚本的 `test` 命令：

```powershell
.\mihomo-manager.ps1 test https://www.google.com
```

该命令会：
- 测试指定 URL 在直连和各地区代理下的延迟
- 使用 Mihomo 内置 API 进行真实连接测试
- 自动识别并推荐最快的节点

**Linux/macOS 用户**可以使用 Mihomo API：

```bash
# 测试指定策略组的延迟
curl "http://127.0.0.1:9090/proxies/♻️%20美国自动/delay?url=https://www.google.com&timeout=10000" \
  -H "Authorization: Bearer 123456"
```

## 📚 参考资料

本仓库配置参考了以下链接内容，以及 [sparkle](https://github.com/xishang0128/sparkle) / [FlClash](https://github.com/chen08209/FlClash) TG 群组各位大佬：

### 官方文档

- [mihomo wiki](https://wiki.metacubex.one/)

### 配置参考

- [mihomo.yaml 来源 - 1](https://github.com/qichiyuhub/rule/blob/main/config/mihomo/config.yaml)
- [mihomo.yaml 来源 - 2](https://iyyh.net/posts/mihomo-self-config)
- [mihomo.yaml 来源 - 3](https://gist.github.com/MoDistortion/219a6beeb0002e5804de80d6e6b47599)

### 规则集

- [Fakeipfilter-blacklist.list 来源](https://github.com/juewuy/ShellCrash/blob/dev/public/fake_ip_filter.list)
- [lvbibir.ini 来源](https://yattazen.com/tutorial/clash-custom-config.html)

### 订阅转换

- <https://acl4ssr-sub.github.io/>
- <https://bianyuan.xyz/>
- <https://sub.dler.io/>

## 📄 License

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## ⚠️ 免责声明

本项目仅供学习交流使用，请勿用于非法用途。使用本配置文件造成的任何后果由使用者自行承担。

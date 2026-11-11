# Mihomo 配置文件

个人使用的 mihomo 内核配置文件，适用于 Windows/Linux/macOS 等平台。

## 📁 项目结构

```
.
├── LICENSE
├── README.md
├── AGENTS.md                   # AI 上下文文档
├── lvbibir.ini                 # ini 格式的 clash 配置文件 (⚠️已弃用, 不再更新)
├── mihomo-manager.ps1          # Windows 管理脚本 (启停/重载/延迟测试)
├── mihomo.yaml                 # mihomo 内核配置文件
├── scripts/                    # Git 自动脱敏工具
│   ├── setup-git-filter.sh     # 安装脱敏 filter
│   └── mihomo_git_filter.py    # clean/smudge 过滤逻辑
└── Ruleset/                    # 自用 clash 分流规则
    ├── AGENTS.md               # 规则集 AI 上下文文档
    ├── Direct.list             # 直连规则列表
    └── Proxy.list              # 代理规则列表
```

## ✨ 配置特性

### 核心特性

- **🔒 DNS 防泄露**: 基于 Fake-IP (IPv4/IPv6) + respect-rules + TUN 严格路由的多重防护机制
- **🚀 性能优化**: TCP 并发、连接复用、ARC 缓存算法
- **🎯 精细分流**: 8 层规则体系，按优先级和使用频率优化
- **🌐 地区策略**: 美国/日本/狮城/台湾/香港节点分组，各自独立自动测速
- **⚡ 自动切换**: URL-Test 自动测速 (Fallback/负载均衡锚点已备好, 按需启用)
- **🛡️ 智能嗅探**: HTTP/TLS/QUIC 协议嗅探，准确识别域名
- **🏠 局域网接入**: `allow-lan` 已启用，局域网内其他设备也可直接使用本机代理

### 代理模式

#### 节点策略组

**当前启用:**

| 策略组 | 类型 | 说明 |
|-----------|------|------|
| ♻️ 自动选择 | URL-Test | 全局自动测速，选择延迟最低的节点 (容差 50ms) |
| ♻️ 美国/日本/狮城/台湾/香港 自动 | URL-Test | 各地区独立自动测速 |
| 🌐 全部节点 | Select | 手动选择模式，可从所有节点中选择 |
| 直连 / 内网代理 | 节点 | 内置直连节点，以及局域网 HTTP 代理节点 (可用 `interface-name` 指定出口网卡) |

**可取消注释启用** (锚点已预置在配置中):

| 策略组 | 类型 | 说明 |
|-----------|------|------|
| 🇺🇸/🇯🇵/🇸🇬/🇹🇼/🇭🇰 地区节点 | Select | 按地区筛选的节点组，手动选择 |
| 🔯 地区故转 | Fallback | 故障转移模式，自动切换到可用节点 |
| 负载均衡 | LoadBalance | 一致性哈希负载均衡 |

#### 功能策略组

| 策略组 | 默认策略 | 说明 |
|--------|---------|------|
| 🚀 默认代理 | 优先自动选择 | 未匹配规则的流量 |
| 🤖 AIGC | 优先自动选择 | ChatGPT/Claude 等 AI 服务 |
| 🍀 Google | 优先自动选择 | Google 全家桶服务 |
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
5. **IPv6 Fake-IP**: 为 AAAA 查询分配 fake IPv6 (非空应答)，避免 Windows DNS 客户端收到空应答后重试导致解析卡 11 秒

#### DNS 服务器

```yaml
enhanced-mode: fake-ip
fake-ip-range: 198.18.0.1/16       # Fake IPv4
fake-ip-range6: fd00::/8           # Fake IPv6 (配套 ipv6: true)
fake-ip-filter-mode: blacklist
fake-ip-filter:
  - rule-set:fakeipfilter          # ShellCrash 黑名单, 局域网域名绕过 Fake-IP

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
| 第一层 | 特殊处理 | REJECT 规则 (云元数据/Windows 小组件)、DNS 服务器路由 |
| 第二层 | 自定义规则 | 用户自定义的代理/直连规则 |
| 第三层 | 局域网/私有地址 | 防止回环和内网泄露 |
| 第四层 | 高频直连服务 | Apple、Speedtest 等 |
| 第五层 | 特定应用代理 | AIGC、GitHub、X、Telegram 等 |
| 第六层 | 通用大厂代理 | Google、YouTube |
| 第七层 | 国内规则 | CN 域名和 IP |
| 第八层 | 兜底规则 | 非中国域名、漏网之鱼 |

### 性能优化

```yaml
# 入站与局域网
mixed-port: 7890                  # 混合代理端口 (HTTP/SOCKS5)
allow-lan: true                   # 允许局域网接入
ipv6: true                        # 启用 IPv6

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

# 状态持久化
profile:
  store-selected: true            # 记住策略组选择
  store-fake-ip: true             # 记住 Fake-IP 映射
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
  skip-domain:                    # 跳过嗅探的域名 (如 Mijia Cloud、Apple 推送)
  skip-src-address:                # 跳过嗅探的源地址段
  skip-dst-address:               # 跳过嗅探的目标地址段 (如 Telegram 自身 IP)
```

**嗅探作用**:
- 从 HTTP/TLS/QUIC 流量中提取真实域名
- 即使应用使用 IP 直连，也能应用域名规则
- 提高规则匹配的准确性
- `skip-*` 列表中的流量跳过嗅探，避免干扰自有 IP 直连的场景 (如 Telegram 走官方 IP 时)

## 🚀 快速开始

### 1. 下载配置文件

```bash
# 下载主配置
wget https://raw.githubusercontent.com/lvbibir/clash/master/mihomo.yaml

# 或使用 git clone
git clone https://github.com/lvbibir/clash.git
cd clash
```

> 仓库中的 `mihomo.yaml` 是脱敏占位版本 (`secret: 123456` / `url: '---'`)，克隆后需要按第 2 步填入自己的订阅地址。

### 2. 修改订阅

编辑 [`mihomo.yaml`](mihomo.yaml:36-39)，替换为你的订阅地址 (provider 名称可随意改, 不影响策略组):

```yaml
proxy-providers:
  xsus:
    <<: *NodeParam
    url: '你的订阅地址'  # 修改此处
    path: './proxy-providers/providers-1.yaml'
```

#### (可选) Git 自动脱敏, 提交不带敏感信息

如果你希望把本地真实可用的 `"mihomo.yaml"`(包含 `secret` 和订阅链接) 同步到 GitHub, 但仓库里只保留脱敏后的占位符版本, 可以使用 git filter:

1. 安装本仓库的 filter(只写入本地 `.git/config`):

```bash
bash "scripts/setup-git-filter.sh"
```

2. 首次启用后, 建议对已跟踪的文件做一次 renormalize, 确保暂存区立即变成脱敏内容:

```bash
git add --renormalize "mihomo.yaml"
```

完成后, 你可以正常把你的配置复制到仓库里的 `"mihomo.yaml"` 并提交, git 会在 `add/commit` 时自动把以下内容清洗成占位符(仓库里默认是 `secret: 123456` / `url: '---'`), 你的工作区文件本身不受影响:

- `secret: ...`
- `proxy-providers` 下每个 provider 的 `url: ...`

你可以用这个命令确认“暂存区里的文件已经脱敏”:

```bash
git show :"mihomo.yaml"
```

说明: clean filter 只作用于暂存区, 所以 `git status` 里 `"mihomo.yaml"` 可能长期显示为“有修改”属于正常现象. 以 `git diff --cached` / `git show` 为准.

注意: `git checkout/pull` 会把仓库里的脱敏版本写回工作区. 建议把真实可用的 `"mihomo.yaml"` 放在其他目录维护, 需要同步到 GitHub 时再复制到本仓库提交.

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

说明:
- **Secret 优先级**: `MIHOMO_SECRET` 环境变量 > `mihomo.yaml` 的 `secret` 字段 > 默认值 `123456`
- 脚本检测到非管理员权限时会自动通过 UAC 提权重启自身
- 交互菜单中还包含 **验证配置** 选项 (调用 `mihomo -t` 校验)

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
- **Web Dashboard**: `http://127.0.0.1:9090/ui` (密码为 `mihomo.yaml` 中 `secret` 字段的值, 仓库提交版本默认为 `123456`)
- **局域网设备**: `allow-lan: true` 且放行 `0.0.0.0/0`，局域网设备使用本机局域网 IP + 端口即可，如 `http://<局域网 IP>:7890`

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

当前配置未启用 `geodata-mode` (规则全部基于远程规则集)。如需使用本地 `GEOSITE` / `GEOIP` 规则，在 `mihomo.yaml` 顶层手动添加：

```yaml
geodata-mode: true
geodata-loader: memconservative
geo-update-interval: 24
geox-url:
  geosite: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
  geoip: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
```

### 添加备用订阅

取消 [`mihomo.yaml:41-46`](mihomo.yaml:41-46) 中 `500G_LongTerm` 条目的注释并替换地址：

```yaml
500G_LongTerm:
  <<: *NodeParam
  url: '备用订阅地址'
  path: './proxy-providers/providers-2.yaml'
  override:
    additional-prefix: "2. "
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

分流规则配置使用 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) 的规则集 (其中 `apple_ip` / `telegram_ip` 使用其 `geo-lite` 轻量版)
Fake-IP 过滤黑名单使用 [ShellCrash](https://github.com/juewuy/ShellCrash/blob/dev/public/fake_ip_filter.list) 规则集

更新频率: 订阅每天更新一次 (`interval: 86400`)、健康检查每 300 秒一次；规则集每 12 小时更新一次 (`interval: 43200`)

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
- `fakeipfilter`: Fake-IP 过滤黑名单 ([ShellCrash](https://github.com/juewuy/ShellCrash/blob/dev/public/fake_ip_filter.list), 域名/Text 格式)

## 🔍 常见问题

### 1. 为什么使用国内 DNS 也不会泄露？

因为 Fake-IP + respect-rules 机制：
- 应用获得的是虚拟 IP，不会直接触发 DNS 查询
- 真实 DNS 查询由 mihomo 根据规则路由
- 代理域名的 DNS 查询会通过代理隧道发送
- ISP 只能看到加密的代理流量

### 2. 如何验证 DNS 是否泄露？

访问以下网站测试：
- https://dnsleaktest.com/
- https://www.dnsleak.com/
- https://ipleak.net/

**预期结果**: 应显示代理服务器所在地的 DNS，而非本地 ISP 的 DNS

### 3. 为什么某些网站无法访问？

可能是 Fake-IP 模式的兼容性问题，检查 [`mihomo.yaml:72-74`](mihomo.yaml:72-74) 的 `fake-ip-filter`。

需要直连的域名可添加到 [`Ruleset/Direct.list`](Ruleset/Direct.list)。

### 4. 如何查看当前使用的节点？

访问 Web Dashboard: `http://127.0.0.1:9090/ui`

或使用 API:
```bash
curl http://127.0.0.1:9090/proxies
```

### 5. 节点自动切换的逻辑是什么？

- **URL-Test 模式**: 每 300 秒测速，选择延迟最低的节点 (容差 50ms)
- **Fallback 模式** (锚点已备好, 取消注释即可启用): 主节点失败后自动切换到备用节点
- **健康检查**: 超时 2 秒判定失败，连续失败 3 次触发主动检查

详见 [`mihomo.yaml:28`](mihomo.yaml:28) (订阅健康检查) 与 [`mihomo.yaml:128-131`](mihomo.yaml:128-131) (策略组锚点)

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
  -H "Authorization: Bearer <mihomo.yaml 中的 secret 值>"
```

### 7. 为什么 `git status` 显示一堆文件的 mode change (100644 => 100755)?

仓库检出在 Windows 盘 (如 WSL2 的 `/mnt/d`) 时会出现: NTFS 没有 Unix 权限位概念, WSL 的 drvfs 把所有文件映射成带执行位, 而文件当初以 644 mode 提交, git (默认 `core.filemode=true`) 于是把每个 644 文件都报成"权限变了"——**文件内容并未改变**, 纯粹是检出环境的权限位差异。

修复: 在仓库内执行 (只影响本仓库, 不改全局):

```bash
git config core.filemode false
```

git 将不再跟踪权限位变化, `git status` 恢复干净. 注意该配置写在本地 `.git/config`, **不随仓库分发**, 新环境/新 clone 后如有同样现象需重新设置.

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

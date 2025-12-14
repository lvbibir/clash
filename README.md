项目结构目录:

```
.
├── LICENSE
├── README.md
├── lvbibir.ini                 # ini 格式的 clash 配置文件 (⚠️已弃用, 不再更新)
├── mihomo-manager.ps1          # mihomo 裸核启停脚本
├── mihomo.yaml                 # mihomo 内核配置文件
└── Ruleset/                    # 自用 clash 分流规则
    ├── Direct.list             # 直连规则列表
    ├── Fakeipfilter.list       # Fake IP 过滤黑名单
    └── Proxy.list              # 代理规则列表
```

本仓库配置参考了以下链接内容, 以及 [sparkle](https://github.com/xishang0128/sparkle) [FlClash](https://github.com/chen08209/FlClash) TG 群组各位大佬:

- [mihomo wiki](https://wiki.metacubex.one/)
- [mihomo.yaml 来源 - 1](https://github.com/qichiyuhub/rule/blob/main/config/mihomo/config.yaml)
- [mihomo.yaml 来源 - 2](https://iyyh.net/posts/mihomo-self-config)
- [mihomo.yaml 来源 - 3](https://gist.github.com/MoDistortion/219a6beeb0002e5804de80d6e6b47599)
- [Fakeipfilter-blacklist.list 来源](https://github.com/juewuy/ShellCrash/blob/dev/public/fake_ip_filter.list)
- [lvbibir.ini 来源](https://yattazen.com/tutorial/clash-custom-config.html)

订阅托管 API:

- <https://acl4ssr-sub.github.io/>
- <https://bianyuan.xyz/>
- <https://sub.dler.io/>

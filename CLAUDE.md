# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a configuration and management suite for **mihomo** (Clash-compatible proxy core), focused on DNS-leak-proof network routing using Fake-IP mode, TUN interface, and an 8-layer rule system.

**Language/Format**: YAML configuration + PowerShell scripts

## Common Commands

### Windows (PowerShell)
```powershell
# Interactive menu
.\mihomo-manager.ps1

# CLI operations
.\mihomo-manager.ps1 start     # Start service
.\mihomo-manager.ps1 stop      # Stop service
.\mihomo-manager.ps1 restart   # Restart service
.\mihomo-manager.ps1 status    # Check status
.\mihomo-manager.ps1 reload    # Hot-reload config (requires running service)
```

### Validate Configuration
```powershell
# Windows
.\mihomo-manager.ps1           # Then select option 6

# Linux/macOS
./mihomo -t -d . -f mihomo.yaml
```

### Start Service (Linux/macOS)
```bash
./mihomo -d . -f mihomo.yaml
```

### Reload Config via API
```bash
curl -X PUT "http://127.0.0.1:9090/configs?force=true" -H "Authorization: Bearer 123456"
```

## Architecture

### Core Configuration (`mihomo.yaml`)

- **Inbound**: TUN mode with `strict-route: true` and DNS hijacking (captures all system traffic)
- **DNS**: Fake-IP mode + `respect-rules: true` (DNS queries route through proxy when needed)
- **Nameservers**: Domestic DoH (Alibaba/Tencent) - safe due to respect-rules routing
- **Uses YAML anchors** (`&NodeParam`, `*NodeParam`) for DRY configuration of proxy providers

### 8-Layer Rule Hierarchy (priority high to low)

1. **Special/REJECT**: Block rules, DNS server routing
2. **Custom rules**: User-defined in `Ruleset/Proxy.list` and `Ruleset/Direct.list`
3. **LAN/Private**: Prevent internal network leaks
4. **High-frequency direct**: Apple, Speedtest
5. **App-specific proxy**: AIGC, GitHub, X, Telegram
6. **General proxy**: Google, YouTube
7. **China rules**: CN domains and IPs
8. **Catch-all**: Non-CN domains, fallback

### Custom Rule Files

- `Ruleset/Proxy.list` - Domains/IPs that should always use proxy
- `Ruleset/Direct.list` - Domains/IPs that should bypass proxy

Rule format:
```
DOMAIN-SUFFIX,example.com
DOMAIN,www.example.com
DOMAIN-KEYWORD,example
IP-CIDR,192.168.1.0/24
```

### Management Script (`mihomo-manager.ps1`)

Windows-only PowerShell script with:
- CLI mode: `.\mihomo-manager.ps1 <action>`
- Interactive menu mode: `.\mihomo-manager.ps1` (no args)
- Config validation via `mihomo -t`
- API secret from `$env:MIHOMO_SECRET` or defaults to `123456`

## Key Settings

- **API**: `http://127.0.0.1:9090` (secret: `123456`)
- **Mixed Proxy Port**: `7890`
- **Web Dashboard**: `http://127.0.0.1:9090/ui` (Zashboard)
- **Subscription**: Edit `proxy-providers` section in `mihomo.yaml`

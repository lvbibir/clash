<#
.SYNOPSIS
    Mihomo 裸核控制脚本 (支持交互菜单 + 命令行参数)

.DESCRIPTION
    用于管理 Mihomo 代理核心的 PowerShell 脚本，支持启动、停止、重启、状态查看和配置重载。
    
.PARAMETER Action
    要执行的操作: start, stop, restart, status, reload, help
    如果不提供参数，将进入交互菜单模式。

.EXAMPLE
    .\mihomo-manager.ps1
    进入交互菜单模式

.EXAMPLE
    .\mihomo-manager.ps1 start
    启动 Mihomo

.EXAMPLE
    .\mihomo-manager.ps1 status
    查看运行状态

.LINK
    https://github.com/lvbibir/clash/blob/master/mihomo-manager.ps1
#>

param(
    [Parameter(Position = 0)]
    [string]$Action = ""
)

# 有效的操作列表
$ValidActions = @("start", "stop", "restart", "status", "reload", "help", "")

# ====================== 配置区域 ======================
# 自动检测脚本所在目录，也可手动指定
$CorePath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$ExeName    = "mihomo-windows-amd64.exe"
$ConfigFile = "mihomo.yaml"
$ApiPort    = 9090

# Secret 配置：优先从环境变量读取，否则使用默认值
$Secret = if ($env:MIHOMO_SECRET) { $env:MIHOMO_SECRET } else { "123456" }
# =====================================================

$FullExe     = Join-Path $CorePath $ExeName
$FullConfig  = Join-Path $CorePath $ConfigFile
$ProcessName = [IO.Path]::GetFileNameWithoutExtension($ExeName)
$ApiUrl      = "http://127.0.0.1:$ApiPort"
$Headers     = if ($Secret) { @{ Authorization = "Bearer $Secret" } } else { @{} }

# ====================== 工具函数 ======================

# 等待条件满足
function Wait-ForCondition {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Condition,
        [int]$TimeoutSeconds = 10,
        [int]$IntervalMs = 300
    )
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        if (& $Condition) {
            $stopwatch.Stop()
            return $true
        }
        Start-Sleep -Milliseconds $IntervalMs
    }
    $stopwatch.Stop()
    return $false
}

# 判断进程是否运行
function Get-MihomoProcess {
    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
}

# 测试 API 是否可用
function Test-Api {
    try {
        Invoke-RestMethod "$ApiUrl/version" -Headers $Headers -TimeoutSec 5 -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# 验证配置文件
function Test-Config {
    if (-not (Test-Path $FullConfig)) {
        Write-Host "配置文件不存在: $FullConfig" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path $FullExe)) {
        Write-Host "可执行文件不存在: $FullExe" -ForegroundColor Red
        return $false
    }
    
    # 调用 mihomo 验证配置
    try {
        $result = & $FullExe -t -d $CorePath -f $ConfigFile 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        else {
            Write-Host "配置文件验证失败:" -ForegroundColor Red
            Write-Host $result -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "配置验证出错: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 显示帮助信息
function Show-Help {
    Write-Host @"

Mihomo Manager - 使用说明
========================

用法: .\mihomo-manager.ps1 [命令]

命令:
  start    启动 Mihomo
  stop     停止 Mihomo
  restart  重启 Mihomo
  status   查看运行状态
  reload   重载配置文件
  help     显示此帮助信息

示例:
  .\mihomo-manager.ps1 start
  .\mihomo-manager.ps1 status

环境变量:
  MIHOMO_SECRET  设置 API 密钥 (可选)

配置文件位置: $FullConfig

"@ -ForegroundColor Cyan
}

# ====================== 核心操作函数 ======================

function Start-Mihomo {
    $proc = Get-MihomoProcess
    if ($proc) {
        Write-Host "Mihomo 已经在运行 (PID $($proc.Id))" -ForegroundColor Yellow
        return
    }
    
    # 验证配置
    Write-Host "正在验证配置文件..." -ForegroundColor Cyan
    if (-not (Test-Config)) {
        return
    }
    
    Write-Host "正在启动 Mihomo 裸核..." -ForegroundColor Cyan
    
    Push-Location $CorePath
    try {
        Start-Process -FilePath $FullExe -ArgumentList "-d", ".", "-f", $ConfigFile -WindowStyle Hidden
    }
    finally {
        Pop-Location
    }
    
    # 等待进程启动
    $started = Wait-ForCondition -Condition { Get-MihomoProcess } -TimeoutSeconds 6 -IntervalMs 300
    
    if ($started) {
        $proc = Get-MihomoProcess
        Write-Host "启动成功！PID: $($proc.Id)" -ForegroundColor Green
        
        # 等待 API 就绪
        Write-Host "等待 API 就绪..." -ForegroundColor Cyan
        $apiReady = Wait-ForCondition -Condition { Test-Api } -TimeoutSeconds 15 -IntervalMs 1000
        
        if ($apiReady) {
            Write-Host "API 已就绪 → $ApiUrl" -ForegroundColor Green
        }
        else {
            Write-Host "API 未能在预期时间内就绪，请检查配置" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "启动失败！请检查路径和配置文件" -ForegroundColor Red
    }
}

function Stop-Mihomo {
    $proc = Get-MihomoProcess
    if (-not $proc) {
        Write-Host "Mihomo 当前未运行" -ForegroundColor Yellow
        return
    }
    
    Write-Host "正在停止 Mihomo (PID $($proc.Id))..." -ForegroundColor Cyan
    
    try {
        Stop-Process -Id $proc.Id -Force -ErrorAction Stop
        
        # 等待进程完全退出
        $stopped = Wait-ForCondition -Condition { -not (Get-MihomoProcess) } -TimeoutSeconds 5 -IntervalMs 200
        
        if ($stopped) {
            Write-Host "已停止" -ForegroundColor Green
        }
        else {
            Write-Host "进程可能未完全退出" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "停止失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Restart-Mihomo {
    Write-Host "正在重启 Mihomo..." -ForegroundColor Cyan
    
    Stop-Mihomo
    Start-Sleep -Seconds 2
    Start-Mihomo
}

function Get-MihomoStatus {
    $proc = Get-MihomoProcess
    if ($proc) {
        $apiStatus = if (Test-Api) { "正常" } else { "不可达" }
        $uptime = (Get-Date) - $proc.StartTime
        $uptimeStr = "{0}天 {1}小时 {2}分钟" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        
        Write-Host ""
        Write-Host "Mihomo 正在运行" -ForegroundColor Green
        Write-Host "  PID        : $($proc.Id)"
        Write-Host "  启动时间   : $($proc.StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        Write-Host "  运行时长   : $uptimeStr"
        Write-Host "  内存占用   : $([math]::Round($proc.WorkingSet64 / 1MB, 2)) MB"
        Write-Host "  API 地址   : $ApiUrl"
        Write-Host "  API 状态   : $apiStatus"
        Write-Host "  配置文件   : $FullConfig"
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "Mihomo 未运行" -ForegroundColor Red
        Write-Host "  配置文件   : $FullConfig"
        Write-Host "  可执行文件 : $FullExe"
        Write-Host ""
    }
}

function Invoke-ConfigReload {
    if (-not (Test-Api)) {
        Write-Host "API 不可达，请先启动核心" -ForegroundColor Red
        return
    }
    
    Write-Host "正在重载配置文件..." -ForegroundColor Cyan
    
    try {
        $body = @{} | ConvertTo-Json -Compress
        Invoke-RestMethod "$ApiUrl/configs?force=true" -Method Put -Headers $Headers -Body $body -ContentType "application/json" -TimeoutSec 10 | Out-Null
        Write-Host "配置重载成功！" -ForegroundColor Green
    }
    catch {
        Write-Host "重载失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ====================== 主逻辑 ======================

if ($Action) {
    # 命令行模式 - 验证参数
    $normalizedAction = $Action.ToLower()
    
    if ($normalizedAction -notin $ValidActions) {
        Write-Host "错误: 未知命令 '$Action'" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
    
    switch ($normalizedAction) {
        "start" { Start-Mihomo }
        "stop" { Stop-Mihomo }
        "restart" { Restart-Mihomo }
        "status" { Get-MihomoStatus }
        "reload" { Invoke-ConfigReload }
        "help" { Show-Help }
    }
}
else {
    # 交互菜单模式
    while ($true) {
        Clear-Host
        Write-Host "===========================================" -ForegroundColor Cyan
        Write-Host "        Mihomo 裸核控制面板" -ForegroundColor White
        Write-Host "===========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # 显示当前状态
        $proc = Get-MihomoProcess
        if ($proc) {
            Write-Host "  当前状态: " -NoNewline
            Write-Host "运行中 (PID $($proc.Id))" -ForegroundColor Green
        }
        else {
            Write-Host "  当前状态: " -NoNewline
            Write-Host "未运行" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "  [1] 启动 Mihomo"
        Write-Host "  [2] 停止 Mihomo"
        Write-Host "  [3] 重启 Mihomo"
        Write-Host "  [4] 查看状态"
        Write-Host "  [5] 重载配置"
        Write-Host "  [6] 验证配置"
        Write-Host "  [7] 帮助信息"
        Write-Host ""
        Write-Host "  [Q] 退出" -ForegroundColor Gray
        Write-Host ""
        $choice = Read-Host "请选择操作"

        switch ($choice.ToUpper()) {
            "1" { Start-Mihomo; Read-Host "`n按回车键继续..." }
            "2" { Stop-Mihomo; Read-Host "`n按回车键继续..." }
            "3" { Restart-Mihomo; Read-Host "`n按回车键继续..." }
            "4" { Get-MihomoStatus; Read-Host "`n按回车键继续..." }
            "5" { Invoke-ConfigReload; Read-Host "`n按回车键继续..." }
            "6" {
                Write-Host ""
                if (Test-Config) {
                    Write-Host "配置文件验证通过！" -ForegroundColor Green
                }
                Read-Host "`n按回车键继续..."
            }
            "7" { Show-Help; Read-Host "`n按回车键继续..." }
            "Q" { Write-Host "再见！" -ForegroundColor Cyan; exit }
            default { Write-Host "无效选择，请重试" -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
        }
    }
}
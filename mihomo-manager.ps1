<#
 Mihomo 裸核控制脚本 (支持交互菜单 + 命令行参数) 
 使用方式: 
   1. 直接双击或 powershell -File Mihomo.ps1          → 弹出菜单选择
   2. .\Mihomo.ps1 start / stop / restart / status / reload   → 直接执行
#>

# ====================== 请在这里修改你的实际路径 ======================
$CorePath   = "D:\software\1-portable\mihomo"
$ExeName    = "mihomo-windows-amd64.exe"
$ConfigFile = "mihomo.yaml"
$Secret     = "123456"                          # 如果没设置 secret 留空即可
# =====================================================================

$FullExe     = Join-Path $CorePath $ExeName
$ProcessName = [IO.Path]::GetFileNameWithoutExtension($ExeName)
$ApiUrl      = "http://127.0.0.1:9090"
$Headers     = if ($Secret) { @{ Authorization = "Bearer $Secret" } } else { @{} }

# 判断进程是否运行
function Get-MihomoProcess { Get-Process -Name $ProcessName -ErrorAction SilentlyContinue }

# 测试 API 是否可用
function Test-Api {
    try {
        $res = Invoke-RestMethod "$ApiUrl/version" -Headers $Headers -TimeoutSec 5 -ErrorAction Stop
        # v1.19+ 会先输出一行 "meta version"，再输出表格，只要没抛异常就说明成功
        return $true
    } catch {
        return $false
    }
}

# 真正的操作函数
function Start-Mihomo {
    if (Get-MihomoProcess) { Write-Host "Mihomo 已经在运行 (PID $((Get-MihomoProcess).Id)) " -ForegroundColor Yellow; return }
    Write-Host "正在启动 Mihomo 裸核..." -ForegroundColor Cyan
    Set-Location $CorePath
    Start-Process -FilePath $FullExe -ArgumentList "-d", ".", "-f", $ConfigFile -WindowStyle Hidden
    1..20 | ForEach-Object { if (Get-MihomoProcess) { break }; Start-Sleep -Milliseconds 300 }
    if (Get-MihomoProcess) {
        Write-Host "启动成功！PID: $((Get-MihomoProcess).Id)" -ForegroundColor Green
        1..15 | ForEach-Object { if (Test-Api) { break }; Start-Sleep -Seconds 1 }
        if (Test-Api) { Write-Host "API 已就绪 → http://127.0.0.1:9090" -ForegroundColor Green }
    } else { Write-Host "启动失败！请检查路径和配置文件" -ForegroundColor Red }
}

function Stop-Mihomo {
    $p = Get-MihomoProcess
    if (!$p) { Write-Host "Mihomo 当前未运行" -ForegroundColor Yellow; return }
    Write-Host "正在停止 Mihomo (PID $($p.Id)) ..." -ForegroundColor Cyan
    Stop-Process -Id $p.Id -Force
    Write-Host "已停止" -ForegroundColor Green
}

function Restart-Mihomo {
    Write-Host "正在重启 Mihomo..." -ForegroundColor Cyan
    Stop-Mihomo
    Start-Sleep -Seconds 2
    Start-Mihomo
    Write-Host "重启完成" -ForegroundColor Green
}

function Status-Mihomo {
    $p = Get-MihomoProcess
    if ($p) {
        $api = if (Test-Api) { "正常" } else { "不可达" }
        Write-Host "Mihomo 正在运行" -ForegroundColor Green
        Write-Host "  PID        : $($p.Id)"
        Write-Host "  启动时间   : $($p.StartTime)"
        Write-Host "  API 状态   : $api"
    } else {
        Write-Host "Mihomo 未运行" -ForegroundColor Red
    }
}

function Reload-Mihomo {
    if (-not (Test-Api)) { Write-Host "API 不可达，请先启动核心" -ForegroundColor Red; return }
    Write-Host "正在重载配置文件..." -ForegroundColor Cyan
    try {
        # 官方规范: PUT /configs?force=true，必须发送数据 (空对象 {} 即可) 
        $body = @{} | ConvertTo-Json -Compress  # 空 JSON 对象
        Invoke-RestMethod "$ApiUrl/configs?force=true" -Method Put -Headers $Headers -Body $body -ContentType "application/json" -TimeoutSec 10 | Out-Null
        Write-Host "配置重载成功！" -ForegroundColor Green
    } catch {
        Write-Host "重载失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ====================== 主逻辑 ======================
if ($args.Count -gt 0) {
    # 命令行传参模式
    $Action = $args[0].ToLower()
    switch ($Action) {
        "start"   { Start-Mihomo }
        "stop"    { Stop-Mihomo }
        "restart" { Restart-Mihomo }
        "status"  { Status-Mihomo }
        "reload"  { Reload-Mihomo }
        default   { Write-Host "未知参数: $Action`n支持: start stop restart status reload" -ForegroundColor Red }
    }
} else {
    # 交互菜单模式
    while ($true) {
        Clear-Host
        Write-Host "===========================================" -ForegroundColor Cyan
        Write-Host "        Mihomo 裸核控制面板" -ForegroundColor White
        Write-Host "===========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] 启动 Mihomo"
        Write-Host "  [2] 停止 Mihomo"
        Write-Host "  [3] 重启 Mihomo"
        Write-Host "  [4] 查看状态"
        Write-Host "  [5] 重载配置"
        Write-Host "  [0] 退出"
        Write-Host ""
        $choice = Read-Host "请选择操作 (0-5)"

        switch ($choice) {
            "1" { Start-Mihomo;  Read-Host "`n按回车键继续..." }
            "2" { Stop-Mihomo;   Read-Host "`n按回车键继续..." }
            "3" { Restart-Mihomo; Read-Host "`n按回车键继续..." }
            "4" { Status-Mihomo; Read-Host "`n按回车键继续..." }
            "5" { Reload-Mihomo; Read-Host "`n按回车键继续..." }
            "0" { Write-Host "再见！" -ForegroundColor Cyan; exit }
            default { Write-Host "输入无效，请重新选择" -ForegroundColor Red; Start-Sleep -Seconds 2 }
        }
    }
}
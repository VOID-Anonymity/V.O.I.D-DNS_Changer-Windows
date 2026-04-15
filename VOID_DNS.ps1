# Смена кодировки, чтобы кириллица не превратилась в кашу
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Функция центровки текста
function Write-Center {
    param([string]$text, [string]$color = "Cyan")
    $width = $Host.UI.RawUI.WindowSize.Width
    $padding = [Math]::Max(0, [Math]::Floor(($width - $text.Length) / 2))
    Write-Host (" " * $padding + $text) -ForegroundColor $color
}

# 0. ПРОВЕРКА ПРАВ АДМИНИСТРАТОРА
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ОШИБКА: Запустите терминал от имени АДМИНИСТРАТОРА!" -ForegroundColor Red
    pause
    exit
}

Clear-Host
Write-Center "Загрузка протоколов Свободной Цитадели... [OK]" "Cyan"
Start-Sleep -Seconds 1
Clear-Host

Write-Center "===========================================" "Cyan"
Write-Center "=== V.O.I.D™ DNS COMMANDER (WINDOWS) v1.0 ===" "Cyan"
Write-Center "Лицензия: Манифест Свободной Цитадели" "Cyan"
Write-Center "===========================================" "Cyan"
Write-Host ""

# 1. БАЗА DNS
$dnsNames = @("Xbox-DNS", "Malw-Link", "Google", "Cloudflare", "Quad9", "AdGuard")
$dnsIPs = @("176.99.11.77", "176.103.130.130", "8.8.8.8", "1.1.1.1", "9.9.9.9", "94.140.14.14")

# 2. ЗАМЕР ПИНГА
Write-Host "[*] Анализ задержки узлов..." -ForegroundColor Cyan
$bestPing = 9999
$bestName = ""
$bestIP = ""

for ($i = 0; $i -lt $dnsNames.Count; $i++) {
    Write-Host -NoNewline "Тестирую $($dnsNames[$i]) ($($dnsIPs[$i]))... "
    $ping = Test-Connection -ComputerName $dnsIPs[$i] -Count 2 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average
    
    if ($null -ne $ping.Average) {
        $avg = [Math]::Round($ping.Average)
        Write-Host "$($avg)ms" -ForegroundColor Green
        if ($avg -lt $bestPing) {
            $bestPing = $avg
            $bestName = $dnsNames[$i]
            $bestIP = $dnsIPs[$i]
        }
    } else {
        Write-Host "OFFLINE" -ForegroundColor Red
    }
}

Write-Host "`n--- РЕКОМЕНДАЦИЯ V.O.I.D ---" -ForegroundColor Cyan
Write-Center "Оптимальный узел: $bestName ($bestPing ms)" "Green"
Write-Host ""

# 3. ПРИМЕНЕНИЕ
$choice = Read-Host "Применить эти настройки? (y/n)"
if ($choice -eq "y") {
    # Ищем активный сетевой адаптер (Ethernet или Wi-Fi)
    $interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    
    if ($null -eq $interface) {
        Write-Host "Ошибка: Активный сетевой адаптер не найден!" -ForegroundColor Red
    } else {
        Write-Host "Настройка интерфейса: $($interface.Name)..." -ForegroundColor Cyan
        Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses ($bestIP)
        Write-Host "[SUCCESS] DNS успешно изменен. Роутер проигнорирован." -ForegroundColor Green
    }
}

Write-Host "`nНажмите любую клавишу для выхода..."
$null = [Console]::ReadKey($true)
Clear-Host
Write-Host "Спасибо за использование софта от V.O.I.D™" -ForegroundColor Cyan

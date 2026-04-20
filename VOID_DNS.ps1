# Установка кодировки для корректного вывода кириллицы
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Функция центрирования текста
function Write-Center {
    param([string]$text, [string]$color = "Cyan")
    $width = $Host.UI.RawUI.WindowSize.Width
    if ($width -le 0) { $width = 80 }
    $padding = [Math]::Max(0, [Math]::Floor(($width - $text.Length) / 2))
    Write-Host (" " * $padding + $text) -ForegroundColor $color
}

# 0. Проверка прав администратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host " ОШИБКА: Запустите скрипт от имени АДМИНИСТРАТОРА! " -ForegroundColor Red -BackgroundColor Black
    Write-Host " Нажми любую клавишу для выхода..."
    $null = [Console]::ReadKey($true)
    exit
}

Clear-Host
Write-Center "Проверка системных параметров... [OK]" "Green"
Start-Sleep -Seconds 1
Clear-Host

Write-Center "===========================================" "Cyan"
Write-Center "===        V.O.I.D DNS COMMANDER        ===" "Cyan"
Write-Center "===========================================" "Cyan"
Write-Host ""

# 1. База DNS (Расширенная)
$dnsNames = @("Xbox-DNS", "Malw-Link", "Google", "Cloudflare", "Quad9", "AdGuard", "OpenDNS", "G-Core", "Mullvad", "Comodo", "Level3")
$dnsIPs   = @("176.99.11.77", "176.103.130.130", "8.8.8.8", "1.1.1.1", "9.9.9.9", "94.140.14.14", "208.67.222.222", "95.161.10.10", "194.242.2.2", "8.26.56.26", "4.2.2.1")

# 2. Поиск лучшего пинга
Write-Host "[*] Анализ сетевых узлов..." -ForegroundColor Cyan
$bestPing = 9999
$bestName = ""
$bestIP = ""

for ($i = 0; $i -lt $dnsNames.Count; $i++) {
    Write-Host -NoNewline " Тест $($dnsNames[$i].PadRight(12)) ($($dnsIPs[$i].PadRight(15)))... "
    
    # Пинг 2 пакетами для скорости
    $ping = Test-Connection -ComputerName $dnsIPs[$i] -Count 2 -ErrorAction SilentlyContinue | Measure-Object -Property ResponseTime -Average
    
    if ($null -ne $ping.Average) {
        $avg = [Math]::Round($ping.Average)
        if ($avg -lt 50) { $pColor = "Green" } elseif ($avg -lt 100) { $pColor = "Yellow" } else { $pColor = "Red" }
        
        Write-Host "$($avg)ms" -ForegroundColor $pColor
        
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
if ($bestName -ne "") {
    Write-Center "ОПТИМАЛЬНЫЙ УЗЕЛ: $bestName ($bestPing ms)" "Green"
} else {
    Write-Host " Не удалось найти активные DNS. Проверьте интернет-соединение." -ForegroundColor Red
    pause
    exit
}
Write-Host ""

# 3. Установка параметров
$choice = Read-Host " Применить настройки для текущего адаптера? (y/n)"
if ($choice -eq "y") {
    # Берем активный сетевой адаптер (Ethernet или Wi-Fi)
    $interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    
    if ($null -eq $interface) {
        Write-Host " [!] ОШИБКА: Активный сетевой адаптер не найден!" -ForegroundColor Red
    } else {
        Write-Host " Настройка адаптера: $($interface.Name)..." -ForegroundColor Cyan
        
        try {
            # Установка DNS
            Set-DnsClientServerAddress -InterfaceAlias $interface.Name -ServerAddresses ($bestIP)
            
            # Очистка кэша для вступления в силу
            Clear-DnsClientCache
            
            Write-Host " [SUCCESS] Конфигурация обновлена. Кэш DNS очищен." -ForegroundColor Green
        } catch {
            Write-Host " [!] ОШИБКА при записи параметров: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n Нажми любую клавишу для выхода..."
$null = [Console]::ReadKey($true)
Clear-Host
Write-Center "Спасибо за использование софта от V.O.I.D" "Cyan"
Start-Sleep -Seconds 2

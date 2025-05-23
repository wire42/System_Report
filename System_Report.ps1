# System_Report.ps1

# --- CONFIGURATION ---
$Servers = @("SERVER01") # Add more servers as needed
$SmtpServer = "smtp.example.com"
$To = "admin@example.com"
$From = "reports@example.com"

# --- STYLE FOR HTML REPORT ---
$style = @"
<style>
    body { font-family: Segoe UI, Tahoma; }
    table { border-collapse: collapse; width: 100%; }
    th { background: #4CAF50; color: white; }
    td, th { padding: 8px; text-align: left; border: 1px solid #ddd; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    .alert { color: #dc3545; font-weight: bold; }
    .warn { color: #ffc107; }
</style>
"@

$systemReport = @()
$vmReport = @()
$securityReport = @()
$cpuTrendReport = @()
$hardwareReport = @()
$backupReport = @()
$networkReport = @()

foreach ($server in $Servers) {
    try {
        # --- System Health ---
        $os = Get-WmiObject Win32_OperatingSystem -ComputerName $server -ErrorAction Stop
        $driveSpace = Get-WmiObject Win32_LogicalDisk -ComputerName $server -Filter "DriveType=3" | 
            Select-Object DeviceID, 
                @{n="SizeGB";e={[math]::Round($_.Size/1GB,2)}}, 
                @{n="FreeGB";e={[math]::Round($_.FreeSpace/1GB,2)}},
                @{n="Free%";e={[math]::Round(($_.FreeSpace/$_.Size)*100,2)}}

        $systemReport += [PSCustomObject]@{
            Server = $server
            Uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
            OS = $os.Caption
            "Memory Used (GB)" = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB,2)
            "Low Disk Space" = ($driveSpace | Where-Object { $_."Free%" -lt 20 }).DeviceID -join ", "
        }

        # --- Hyper-V VM Monitoring ---
        try {
            $vms = Get-VM -ComputerName $server -ErrorAction Stop
            if ($vms) {
                $vmStats = $vms | Select-Object Name, State, Uptime,
                    @{n='CPUUsage';e={$_.CPUUsage}},
                    @{n='MemoryAssignedGB';e={[math]::Round($_.MemoryAssigned/1GB,2)}}
                $vmReport += $vmStats | ConvertTo-Html -Fragment -PreContent "<h3>VM Performance - $server</h3>"
            }
        } catch {}

        # --- Security Events (last 24h) ---
        # Failed logons (4625)
        $failedLogons = Get-WinEvent -ComputerName $server -FilterHashtable @{
            LogName = 'Security'
            Id = 4625
            StartTime = (Get-Date).AddDays(-1)
        } | Select-Object TimeCreated,
            @{n="User";e={($_.Properties[5].Value)}},
            @{n="Source";e={($_.Properties[18].Value)}}

        # Account lockouts (4740)
        $lockouts = Get-WinEvent -ComputerName $server -FilterHashtable @{
            LogName = 'Security'
            Id = 4740
            StartTime = (Get-Date).AddDays(-1)
        } | Select-Object TimeCreated,
            @{n="User";e={($_.Properties[0].Value)}},
            @{n="Source";e={($_.Properties[1].Value)}}

        # Privilege escalations (4672)
        $privEsc = Get-WinEvent -ComputerName $server -FilterHashtable @{
            LogName = 'Security'
            Id = 4672
            StartTime = (Get-Date).AddDays(-1)
        } | Select-Object TimeCreated,
            @{n="User";e={($_.Properties[1].Value)}}

        $securityReport += "<h3>Security Events - $server</h3>"
        $securityReport += "<b>Failed Logons (last 24h):</b>"
        if ($failedLogons) {
            $securityReport += $failedLogons | ConvertTo-Html -Fragment
        } else {
            $securityReport += "<p>None</p>"
        }
        $securityReport += "<b>Account Lockouts (last 24h):</b>"
        if ($lockouts) {
            $securityReport += $lockouts | ConvertTo-Html -Fragment
        } else {
            $securityReport += "<p>None</p>"
        }
        $securityReport += "<b>Privilege Escalations (last 24h):</b>"
        if ($privEsc) {
            $securityReport += $privEsc | ConvertTo-Html -Fragment
        } else {
            $securityReport += "<p>None</p>"
        }

        # --- CPU Usage Trends and Peak Loads ---
        $cpuSamples = @()
        for ($i=0; $i -lt 6; $i++) {
            $usage = Get-Counter -ComputerName $server '\Processor(_Total)\% Processor Time'
            $cpuSamples += [PSCustomObject]@{
                Time = (Get-Date).ToString("HH:mm:ss")
                CPU = [math]::Round($usage.CounterSamples[0].CookedValue,2)
            }
            Start-Sleep -Seconds 10
        }
        $avgCPU = ($cpuSamples | Measure-Object -Property CPU -Average).Average
        $peakCPU = ($cpuSamples | Measure-Object -Property CPU -Maximum).Maximum

        $cpuTrendReport += "<h3>CPU Usage Trend - $server</h3>"
        $cpuTrendReport += "<b>Average CPU (last 1 min):</b> $avgCPU %<br>"
        $cpuTrendReport += "<b>Peak CPU (last 1 min):</b> $peakCPU %<br>"
        $cpuTrendReport += $cpuSamples | ConvertTo-Html -Fragment

        # --- Hardware Health ---
        $hardwareHealth = @()
        $hardwareHealth += Get-WmiObject Win32_Fan -ComputerName $server | Select-Object Name, Status, DesiredSpeed, CurrentSpeed
        $hardwareHealth += Get-WmiObject Win32_TemperatureProbe -ComputerName $server | Select-Object Name, Status, CurrentReading
        $hardwareHealth += Get-WmiObject Win32_Battery -ComputerName $server | Select-Object Name, Status, EstimatedChargeRemaining
        $hardwareHealth += Get-WmiObject Win32_DiskDrive -ComputerName $server | Select-Object Model, Status

        $hardwareReport += "<h3>Hardware Health - $server</h3>"
        if ($hardwareHealth) {
            $hardwareReport += $hardwareHealth | ConvertTo-Html -Fragment
        } else {
            $hardwareReport += "<p>No hardware health data available (requires vendor tools or agents).</p>"
        }

        # --- Backup Job Summaries ---
        $backupResults = Get-WinEvent -ComputerName $server -LogName 'Microsoft-Windows-Backup' -MaxEvents 20 |
            Where-Object { $_.Id -in 4,5,7,9 } | Select-Object TimeCreated, Id, Message

        $backupReport += "<h3>Backup Jobs - $server</h3>"
        if ($backupResults) {
            $backupReport += $backupResults | ConvertTo-Html -Fragment
        } else {
            $backupReport += "<p>No backup job events found.</p>"
        }

        # --- Network Utilization and Errors ---
        # Errors
        try {
            $netStats = Get-NetAdapterStatistics -CimSession $server | Select-Object Name, OutboundErrors, InboundErrors
            $networkReport += "<h3>Network Errors - $server</h3>"
            $networkReport += $netStats | ConvertTo-Html -Fragment
        } catch {
            $networkReport += "<h3>Network Errors - $server</h3><p>Could not retrieve network statistics.</p>"
        }
        # Utilization
        try {
            $netPerf = Get-Counter -ComputerName $server '\Network Interface(*)\Bytes Total/sec'
            $utilData = $netPerf.CounterSamples | Select-Object InstanceName, @{n="Bytes/sec";e={"{0:N0}" -f $_.CookedValue}}
            $networkReport += "<h3>Network Utilization - $server</h3>"
            $networkReport += $utilData | ConvertTo-Html -Fragment
        } catch {
            $networkReport += "<h3>Network Utilization - $server</h3><p>Could not retrieve network utilization data.</p>"
        }

    } catch {
        Write-Warning "Failed to connect to $server : $_"
    }
}

# --- BUILD HTML REPORT ---
$htmlBody = @()
$htmlBody += $systemReport | ConvertTo-Html -Fragment -PreContent "<h2>System Health Report</h2>"
$htmlBody += $vmReport
$htmlBody += $securityReport
$htmlBody += $cpuTrendReport
$htmlBody += $hardwareReport
$htmlBody += $backupReport
$htmlBody += $networkReport

$fullReport = ConvertTo-Html -Head $style -Body ($htmlBody -join "") -Title "Daily System Report" |
    ForEach-Object {
        $_ -replace '<td>Stopped</td>', '<td class="alert">Stopped</td>' `
           -replace '<td>(Off)</td>', '<td class="alert">$1</td>' `
           -replace '<td>(9\d\.\d{2})</td>', '<td class="warn">$1</td>'
    }

# --- SEND EMAIL ---
$mailParams = @{
    SmtpServer = $SmtpServer
    To = $To
    From = $From
    Subject = "System Report - $(Get-Date -Format 'yyyy-MM-dd')"
    Body = $fullReport
    BodyAsHtml = $true
    ErrorAction = 'Stop'
}

Send-MailMessage @mailParams
Write-Output "Report sent successfully!"

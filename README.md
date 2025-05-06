PowerShell Advanced System Report Script
Overview
This PowerShell script collects and emails a comprehensive daily report on the health and status of your Windows servers.
It includes:

System Health (uptime, OS, memory, disk space)

Hyper-V VM Monitoring (state, uptime, CPU/memory usage)

Security Events (failed logons, account lockouts, privilege escalations)

CPU Usage Trends (average and peak loads)

Hardware Health (fans, temperature, battery, disk status)

Backup Job Summaries (Windows Server Backup)

Network Utilization and Errors

HTML-formatted Email Report with visual highlights

Features
Multi-server support (edit the $Servers array)

HTML email with tables and color-coded alerts

Vendor-agnostic hardware monitoring (limited by available WMI data)

Extensible: add your own checks or integrate with vendor tools

Prerequisites
PowerShell 5.1 or later

Run as Administrator

Remote management enabled (WinRM, WMI, CIM sessions) on target servers

SMTP server for sending email reports

For Hyper-V monitoring: script must run on a Hyper-V host or with remoting enabled

For detailed hardware health: vendor management tools/agents may be required

Configuration
Edit the following variables at the top of the script:

powershell
$Servers = @("SERVER01", "SERVER02")   # Add your server names here
$SmtpServer = "smtp.example.com"       # Your SMTP server
$To = "admin@example.com"              # Recipient email
$From = "reports@example.com"          # Sender email
Usage
Save the script as System_Report.ps1.

Open PowerShell as Administrator.

Run the script:

powershell
.\System_Report.ps1
Check your email for the report!

Customization
Add more servers:
Add server names to the $Servers array.

Change sampling intervals:
Adjust the CPU/network sampling loops for longer or shorter trend data.

Backup software:
For non-Windows Server Backup, adapt the backup job summary section to your backup solution’s logs or APIs.

Hardware health:
For more detailed info, integrate vendor PowerShell modules (e.g., Dell OMSA, HP iLO, Lenovo XClarity).

Troubleshooting
No hardware health data:
Most WMI classes (fans, temperature, power, RAID) require vendor agents. See your hardware vendor’s documentation.

Remote access errors:
Ensure WinRM and WMI are enabled and accessible on all target servers.

Hyper-V errors:
Script must run on a Hyper-V host or with appropriate remoting permissions.

Email not sent:
Verify SMTP server settings and network connectivity.

Security
The script reads security event logs for failed logons, lockouts, and privilege escalations.

Ensure only authorized admins can run or modify the script.

License
This script is provided as-is, without warranty or support.
You are free to modify and use it in your environment.

Feel free to adapt this README for your environment or internal documentation!


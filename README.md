How to Use:

Edit the $Servers array with your server names.
Set your SMTP server and email addresses.
Run the script in PowerShell as an administrator.

What’s Included:

System Health: Uptime, OS, memory, low disk space
VM Monitoring: VM name, state, uptime, CPU, memory
Security Events: Failed logons, lockouts, privilege escalations (last 24h)
CPU Trends: Samples every 10 seconds for 1 minute, reports average and peak
HTML Email: Nicely formatted, with alerts and highlights

Tips:

For more servers, add their names to the $Servers array.
For longer CPU trend sampling, increase the loop count and sleep interval.
For production, consider running this as a scheduled task.
You may need to adjust permissions and firewall settings for remote WMI/WinRM/Hyper-V access.
Let me know if you’d like further customization!

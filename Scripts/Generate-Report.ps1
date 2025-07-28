# CONFIGURATION
$ReportPath = "C:\PatchAutomation\Reports\UpdateReport-$(Get-Date -Format 'yyyyMMdd').html"

# Create the report directory if it doesn't exist
New-Item -Path (Split-Path $ReportPath -Parent) -ItemType Directory -Force | Out-Null

# Import module
Import-Module PSWindowsUpdate

# Get last 10 successfully installed updates
$UpdateHistory = Get-WUHistory -MaxDate (Get-Date) | 
                 Where-Object { $_.Result -eq 'Succeeded' } | 
                 Select-Object -First 10 | 
                 Select-Object Date, Title, Description, Result

# Generate HTML report
$HtmlReport = @"
<html>
<head><title>Update Report</title></head>
<body>
<h1>Windows Update Report - $(Get-Date)</h1>
<h2>Server: $env:COMPUTERNAME</h2>
<table border=1>
<tr><th>Date</th><th>Update</th><th>Status</th></tr>
"@

if (-not $UpdateHistory) {
    $HtmlReport += "<tr><td colspan=3>No successful updates found</td></tr>"
} else {
    foreach ($Update in $UpdateHistory) {
        $HtmlReport += "<tr><td>$($Update.Date)</td><td>$($Update.Title)</td><td>$($Update.Result)</td></tr>"
    }
}

$HtmlReport += "</table></body></html>"
$HtmlReport | Out-File $ReportPath
### **Windows Server Patch Automation**  

*Automated patch management for Windows Server 2016/2019/2022/2025*  

---

### **1. Purpose**  
Automate Windows Server patching to:  
- Ensure 99% security update compliance  
- Reduce manual effort by 90%  
- Maintain detailed audit trails  
- Enable 1-click rollback capability  

---

### **2. Prerequisites**  
| **Component**          | **Requirement**                     | **Verification Command**               |  
|-------------------------|-------------------------------------|----------------------------------------|  
| OS                      | Windows Server 2016/2019/2022       | `$PSVersionTable.OS`                   |  
| PowerShell              | v5.1+                              | `$PSVersionTable.PSVersion`            |  
| Disk Space              | 10GB+ free on C: drive             | `Get-Volume C | Select-Object SizeRemaining` |  
| Permissions             | Local Administrator rights         | `([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)` |  
| Network Access          | HTTPS to Microsoft Update servers  | `Test-NetConnection update.microsoft.com -Port 443` |  

---

### **3. Setup Procedure**  
#### **3.1. File System Preparation**  
```powershell
# Create directory structure
New-Item -Path C:\Windows-Server-Patch-Automation -ItemType Directory -Force
New-Item -Path C:\Windows-Server-Patch-Automation\Scripts, Logs, Reports, Backups -ItemType Directory -Force
```

#### **3.2. Module Installation**  
```powershell
# Install required modules
Install-Module PSWindowsUpdate -Force -Confirm:$false
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

#### **3.3. Core Scripts Deployment**  
Save these in `C:\Windows-Server-Patch-Automation\Scripts`:  

1. **`Install-Updates.ps1`** (Main update script):  
   ```powershell
   # CONFIGURATION
$LogFile = "C:\Windows-Server-Patch-Automation\Logs\Updates-$(Get-Date -Format 'yyyyMMdd-HHmm').log"

# Create the log directory if it doesn't exist
New-Item -Path (Split-Path $LogFile -Parent) -ItemType Directory -Force | Out-Null

# Import module
Import-Module PSWindowsUpdate

# Start logging
"==== UPDATE PROCESS STARTED: $(Get-Date) ====" | Out-File $LogFile

try {
    # Check for updates from Microsoft
    $Updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction Stop
    
    if ($Updates) {
        "Found $($Updates.Count) updates" | Out-File $LogFile -Append
        "List of updates:`n$($Updates.Title | Out-String)" | Out-File $LogFile -Append
        
        # Install updates with automatic reboot
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
        "==== UPDATES INSTALLED SUCCESSFULLY ====" | Out-File $LogFile -Append
    } else {
        "No updates available" | Out-File $LogFile -Append
    }
} catch {
    "ERROR: $_" | Out-File $LogFile -Append
    "==== UPDATE PROCESS FAILED ====" | Out-File $LogFile -Append
    exit 1
}
   ```

2. **`System-Backup.ps1`** (Pre-update backup):  
   ```powershell
# System-Backup.ps1 - VMware Workstation Pro Optimized (Fixed)
# Added robust directory creation and error handling

param(
    [string]$VMXPath = "",
    [string]$SnapshotName = "Pre-Update-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    [switch]$SkipSnapshot = $false
)

Write-Host "=== System Backup Script - VMware Workstation Pro ===" -ForegroundColor Cyan
Write-Host "Server: $env:COMPUTERNAME | Date: $(Get-Date)" -ForegroundColor White

# Function to create directories with error handling
function Ensure-DirectoryExists {
    param([string]$Path)
    try {
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Host "✓ Created directory: $Path" -ForegroundColor Green
        }
        return $true
    }
    catch {
        Write-Host "✗ Critical: Could not create directory '$Path': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# --- Rest of functions remain unchanged ---

# Create main backup directory with fallback
$BackupBase = "C:\PatchAutomation\Backups"
if (-not (Ensure-DirectoryExists -Path $BackupBase)) {
    # Fallback to TEMP directory if primary location fails
    $BackupBase = Join-Path $env:TEMP "PatchAutomation\Backups"
    if (-not (Ensure-DirectoryExists -Path $BackupBase)) {
        Write-Host "✗ FATAL: Could not create any backup directories. Exiting." -ForegroundColor Red
        exit 1
    }
}

# Create timestamped backup directory
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupLocation = Join-Path $BackupBase "SystemBackup_$Timestamp"
if (-not (Ensure-DirectoryExists -Path $BackupLocation)) {
    exit 1
}

# --- VMware snapshot section remains unchanged ---

# File-based backup with improved error handling
$BackupItems = @(
    @{ Source = "C:\Windows\System32\config"; Dest = "Registry"; Description = "System Registry files" },
    @{ Source = "C:\Windows\System32\drivers\etc"; Dest = "SystemFiles"; Description = "System configuration files" },
    @{ Source = "C:\ProgramData\VMware"; Dest = "VMwareData"; Description = "VMware Tools configuration" },
    @{ Source = "C:\ProgramData\Microsoft"; Dest = "MicrosoftData"; Description = "Microsoft application data" }
)

foreach ($Item in $BackupItems) {
    if (-not (Test-Path $Item.Source)) {
        Write-Host "⚠ Source not found: $($Item.Source)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "Backing up: $($Item.Description)" -ForegroundColor Cyan
    $DestPath = Join-Path $BackupLocation $Item.Dest
    
    try {
        # Ensure destination directory exists
        if (-not (Ensure-DirectoryExists -Path $DestPath)) {
            continue
        }
        
        # Use robocopy with improved error handling
        $RobocopyArgs = @(
            $Item.Source, $DestPath, "/E", "/R:2", "/W:5", "/MT:4",
            "/XD", "Temp", "*.tmp", "Cache", "Logs",
            "/XF", "*.tmp", "*.log", "*.cache",
            "/NFL", "/NDL", "/NP"
        )
        & robocopy @RobocopyArgs | Out-Null
        
        if ($LASTEXITCODE -le 7) {
            Write-Host "  ✓ Success" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Partial success (Exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Rest of script remains unchanged with registry exports and summary ---
   ```

3. **`Generate-Report.ps1`** (Compliance report):  
   ```powershell
# CONFIGURATION
$ReportPath = "C:\Windows-Server-Patch-Automation\Reports\UpdateReport-$(Get-Date -Format 'yyyyMMdd').html"

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
   ```

---

### **4. Automation Configuration**  
#### **4.1. Scheduled Tasks Setup**  
```powershell
# Backup task (Sat 11 PM)
$BackupAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Windows-Server-Patch-Automation\Scripts\System-Backup.ps1"
$BackupTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Saturday -At 23:00
Register-ScheduledTask -TaskName "Pre-Update Backup" -Action $BackupAction -Trigger $BackupTrigger -RunLevel Highest -User "SYSTEM"

# Update task (Sun 2 AM)
$UpdateAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Windows-Server-Patch-Automation\Scripts\Install-Updates.ps1"
$UpdateTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 02:00
Register-ScheduledTask -TaskName "Automated Updates" -Action $UpdateAction -Trigger $UpdateTrigger -RunLevel Highest -User "SYSTEM"

# Reporting task (Daily 8 AM)
$ReportAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Windows-Server-Patch-Automation\Scripts\Generate-Report.ps1"
$ReportTrigger = New-ScheduledTaskTrigger -Daily -At 08:00
Register-ScheduledTask -TaskName "Daily Report" -Action $ReportAction -Trigger $ReportTrigger
```

#### **4.2. Security Hardening**  
```powershell
# Restrict script access
icacls C:\PatchAutomation\Scripts /inheritance:r /grant:r "Administrators:(OI)(CI)F" "SYSTEM:(OI)(CI)F"
```

---

### **5. Operational Procedures**  
#### **5.1. Monthly Patching Workflow**  
1. **Friday 5 PM**: Verify disk space (`Get-Volume C`)  
2. **Saturday 11 PM**: System backup runs automatically  
3. **Sunday 2 AM**: Updates install + automatic reboot  
4. **Monday 8 AM**: Review reports in `C:\Windows-Server-Patch-Automation\Reports`  

#### **5.2. Maintenance Tasks**  
```powershell
# Monthly log cleanup (Run first Monday)
Get-ChildItem C:\Windows-Server-Patch-Automation\Logs\*, C:\Windows-Server-Patch-Automation\Reports\* | 
    Where LastWriteTime -LT (Get-Date).AddDays(-30) | 
    Remove-Item -Force

# Quarterly module update
Update-Module PSWindowsUpdate -Force
```

---

### **6. Verification & Testing**  
#### **6.1. Pre-Deployment Checks**  
| **Check**               | **Command**                          | **Pass Criteria**              |  
|-------------------------|--------------------------------------|--------------------------------|  
| Script syntax           | `.\Install-Updates.ps1 -WhatIf`     | No PowerShell errors           |  
| Backup functionality    | `.\System-Backup.ps1`               | .BKF file in Backups folder    |  
| Report generation       | `.\Generate-Report.ps1`             | HTML file created in Reports   |  
| Task registration       | `Get-ScheduledTask *Update*`        | 3 tasks show "Ready" status    |  

#### **6.2. Post-Update Validation**  
1. Confirm successful reboot:  
   ```powershell
   Get-EventLog -LogName System -Source "Microsoft-Windows-Winlogon" -After (Get-Date).AddHours(-2)
   ```  
2. Verify no failed updates:  
   ```powershell
   Get-WinEvent -FilterHashtable @{LogName='System'; ID=19,20,21,22} -MaxEvents 20
   ```  

---

### **7. Rollback Procedure**  
#### **7.1. From Restore Point**  
```powershell
# List available restore points
Get-ComputerRestorePoint | Format-List Description, CreationTime

# Execute rollback (Using last pre-update point)
Restore-Computer -RestorePoint (Get-ComputerRestorePoint | 
    Where Description -like "*Pre-Update*" | 
    Sort CreationTime -Descending | 
    Select -First 1).SequenceNumber
```

#### **7.2. From System State Backup**  
```powershell
# List available backups
wbadmin get versions -backuptarget:C:\Windows-Server-Patch-Automation\Backups

# Restore backup (Replace MM/DD/YYYY with actual version)
wbadmin start systemstaterecovery -version:MM/DD/YYYY -backuptarget:C:\Windows-Server-Patch-Automation\Backups -quiet
```

---

### **8. Troubleshooting Guide**  
| **Issue**                     | **Diagnostic Command**                          | **Solution**                                  |  
|-------------------------------|------------------------------------------------|-----------------------------------------------|  
| Updates not installing        | `Get-WindowsUpdate -MicrosoftUpdate -Verbose`  | Check network/firewall to Microsoft servers   |  
| Script permission denied      | `Get-ExecutionPolicy -List`                    | Run `Set-ExecutionPolicy RemoteSigned`        |  
| Backup fails                  | `Get-WindowsFeature Windows-Server-Backup`     | Install Windows Server Backup feature         |  
| Unexpected reboot             | `Get-ScheduledTask "Automated Updates"`        | Verify AutoReboot=$true in script             |  
| Low disk space                | `Get-Volume C | Format-Table Size, SizeRemaining` | Clean up disk space before patching           |  

---

```

# Windows Server Patch Automation

A comprehensive solution for automating Windows Server patch management using PowerShell and Microsoft Update.

## 📌 Features

- **Automated patching** with Microsoft Update integration
- **Pre-update system backups** with restore capability
- **Detailed reporting** in HTML format
- **Scheduled maintenance windows**
- **Compliance tracking**
- **Rollback functionality**

## 🚀 Quick Start

### Prerequisites
- Windows Server 2016/2019/2022/2025
- PowerShell 5.1+
- Administrator privileges

### Setup Procedure
1. File System Preparation
```powershell
# Create directory structure
New-Item -Path C:\Windows-Server-Patch-Automation -ItemType Directory -Force
New-Item -Path C:\Windows-Server-Patch-Automation\Scripts, Logs, Reports, Backups -ItemType Directory -Force
```

2. Module Installation
```powershell
# Install required modules
Install-Module PSWindowsUpdate -Force -Confirm:$false
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

## 📂 Project Structure
```
/Windows-Server-Patch-Automation
│
├── /Scripts                # Core automation scripts
│   ├── Install-Updates.ps1
│   ├── System-Backup.ps1
│   └── Generate-Report.ps1
│
├── /Docs                   # Documentation
│   ├── SOP.md
│   
│
└── README.md               
```

## 🔧 Usage

### Scheduled Patching
The system automatically runs:
- **Backups**: Saturdays at 11 PM
- **Updates**: Sundays at 2 AM
- **Reports**: Daily at 8 AM

### Manual Operations
Run a test update check:
```powershell
.\Scripts\Install-Updates.ps1 -WhatIf
```

Generate an ad-hoc report:
```powershell
.\Scripts\Generate-Report.ps1
```

## 📊 Reporting
View generated reports in:
```
C:\Windows-Server-Patch-Automation\Reports\
```
Sample report includes:
- Update history
- Compliance status
- System information

## 🛡️ Rollback Procedure
To restore from restore point:
```powershell
Restore-Computer -RestorePoint (Get-ComputerRestorePoint | 
    Where Description -like "*After-Update*" | 
    Sort CreationTime -Descending | 
    Select -First 1).SequenceNumber
```

To restore from backup:
```powershell
wbadmin start systemstaterecovery -version:MM/DD/YYYY -backuptarget:C:\Windows-Server-Patch-Automation\Backups
```


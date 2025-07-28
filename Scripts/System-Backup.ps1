# System-Backup.ps1 - VMware Workstation Pro Optimized
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
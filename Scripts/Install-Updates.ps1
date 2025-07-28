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
<#
.SYNOPSIS
    Cleans up duplicate and stale devices in Microsoft Entra ID (Azure AD).

.DESCRIPTION
    This script helps maintain a clean Entra ID environment by:
    1. Finding devices with duplicate DisplayNames and removing stale entries
    2. Finding devices not seen in the last N days and marking them for removal
    3. Exporting a full removal list to CSV for audit purposes

.PARAMETER AuditOnly
    When specified, runs in audit mode - identifies devices but doesn't delete them.

.PARAMETER StaleDays
    Number of days of inactivity before a device is considered stale. Default: 180

.EXAMPLE
    .\Remove-EntraDeviceDuplicates.ps1 -AuditOnly

.EXAMPLE
    .\Remove-EntraDeviceDuplicates.ps1 -StaleDays 90

.NOTES
    Author: Dakota McCurdy
    Requires: Microsoft.Graph modules, Device.ReadWrite.All permission
#>

param(
    [switch]$AuditOnly,
    [int]$StaleDays = 180
)

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement

# Import required modules
'Microsoft.Graph.Authentication', 'Microsoft.Graph.Identity.DirectoryManagement' |
    ForEach-Object { 
        if (-not (Get-Module $_)) { 
            Import-Module $_ -ErrorAction SilentlyContinue 
        } 
    }

# Install ImportExcel if not available
if (-not (Get-Command Export-Csv -ErrorAction SilentlyContinue)) {
    Write-Host "Installing ImportExcel module..." -ForegroundColor Yellow
    Install-Module ImportExcel -Scope CurrentUser -Force -Confirm:$false
}

# Connect to Microsoft Graph
if (-not (Get-MgContext)) {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes Device.ReadWrite.All -NoWelcome
}

# Get all devices
Write-Host "Retrieving all devices from Entra ID..." -ForegroundColor Cyan
$allDevices = Get-MgDevice -All

# Initialize removal list
$removalList = [System.Collections.Generic.List[psobject]]::new()

# Process duplicate devices
$dupeGroups = $allDevices | Group-Object DisplayName | Where-Object Count -gt 1

if ($dupeGroups) {
    Write-Host "`nFound $($dupeGroups.Count) device name(s) with duplicates." -ForegroundColor Yellow
    
    foreach ($grp in $dupeGroups) {
        $instances = $grp.Group
        
        # Prefer managed devices, then most recent
        $managed = $instances | Where-Object IsManaged
        if ($managed) {
            $keep = $managed | Sort-Object { [DateTime]$_.ApproximateLastSignInDateTime } -Descending | Select-Object -First 1
        }
        else {
            $keep = $instances | Sort-Object { [DateTime]$_.ApproximateLastSignInDateTime } -Descending | Select-Object -First 1
        }

        Write-Host "  Keeping: $($keep.DisplayName) (ID: $($keep.Id))" -ForegroundColor Green

        # Mark others for removal
        $toRemove = $instances | Where-Object Id -ne $keep.Id
        foreach ($d in $toRemove) {
            $removalList.Add([pscustomobject]@{
                DisplayName = $d.DisplayName
                Id          = $d.Id
                LastSignIn  = $d.ApproximateLastSignInDateTime
                Category    = 'Duplicate'
            })

            if ($AuditOnly) {
                Write-Host "    [AUDIT] Would remove: $($d.DisplayName)" -ForegroundColor Yellow
            }
            else {
                Write-Host "    Removing: $($d.DisplayName)" -ForegroundColor Red
                Remove-MgDevice -DeviceId $d.Id -ErrorAction Stop
            }
        }
    }
}

# Process stale devices
$cutoff = (Get-Date).AddDays(-$StaleDays)
Write-Host "`nFinding stale devices (not seen in $StaleDays days)..." -ForegroundColor Cyan

$stale = $allDevices | Where-Object {
    $_.ApproximateLastSignInDateTime -and 
    [DateTime]$_.ApproximateLastSignInDateTime -lt $cutoff
}

if ($stale) {
    Write-Host "Found $($stale.Count) stale device(s)." -ForegroundColor Yellow
    
    foreach ($d in $stale) {
        $removalList.Add([pscustomobject]@{
            DisplayName = $d.DisplayName
            Id          = $d.Id
            LastSignIn  = $d.ApproximateLastSignInDateTime
            Category    = 'Stale'
        })
        
        if ($AuditOnly) {
            Write-Host "  [AUDIT] Would remove: $($d.DisplayName)" -ForegroundColor Yellow
        }
        else {
            Write-Host "  Removing: $($d.DisplayName)" -ForegroundColor Red
            Remove-MgDevice -DeviceId $d.Id -ErrorAction Stop
        }
    }
}

# Export results
if ($removalList.Count) {
    $csvPath = "DevicesToRemove_$(Get-Date -Format yyyyMMdd).csv"
    $removalList | Export-Csv -Path $csvPath -NoTypeInformation -Force
    Write-Host "`nExported removal list to: $csvPath" -ForegroundColor Cyan
    Write-Host "Total: $($removalList.Count) devices" -ForegroundColor Cyan
}
else {
    Write-Host "`nNo devices to remove!" -ForegroundColor Green
}

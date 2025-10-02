# Entra ID Device Cleanup

A PowerShell script to identify and remove duplicate and stale device registrations in Microsoft Entra ID (formerly Azure AD), helping maintain a clean device inventory.

## Problem Statement

In enterprise environments, duplicate and stale device entries accumulate in Entra ID due to:
- Device re-imaging without proper cleanup
- Multiple enrollment attempts
- Devices rejoining after connectivity issues
- Incomplete offboarding processes

These duplicates cause:
- Confusion in device management dashboards
- Inaccurate compliance reporting
- Difficulty identifying active devices
- Increased administrative overhead

## Features

- **Smart Duplicate Detection**: Automatically identifies devices with the same DisplayName
- **Intelligent Preservation**: Keeps the most recently active managed device
- **Stale Device Cleanup**: Removes devices inactive for a configurable period (default: 180 days)
- **Audit Mode**: Preview changes before execution with `-AuditOnly` parameter
- **CSV Export**: Generates detailed removal report for compliance and auditing
- **Safe by Design**: Requires explicit permissions and confirmation

## Prerequisites

### Required Modules
```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
Install-Module ImportExcel -Scope CurrentUser
Required Permissions

Device.ReadWrite.All - Read and delete device objects in Entra ID

Minimum Role Requirements

Cloud Device Administrator
Global Administrator

Usage
Basic Examples
Audit Mode (Safe Preview)
powershell.\Remove-EntraDeviceDuplicates.ps1 -AuditOnly
Shows what would be removed without making any changes.
Remove Duplicates and Stale Devices (Default: 180 days)
powershell.\Remove-EntraDeviceDuplicates.ps1
Custom Stale Threshold (90 days)
powershell.\Remove-EntraDeviceDuplicates.ps1 -StaleDays 90
Audit with Custom Threshold
powershell.\Remove-EntraDeviceDuplicates.ps1 -StaleDays 90 -AuditOnly
How It Works

Authentication: Connects to Microsoft Graph with required permissions
Duplicate Detection:

Groups devices by DisplayName
For each duplicate set, keeps the most recently active managed device
Marks others for removal


Stale Device Detection:

Identifies devices not seen within the threshold period
Marks for removal


Action: Removes marked devices (or reports in audit mode)
Export: Generates CSV report of all removals

Sample Output
Connecting to Microsoft Graph...
Retrieving all devices from Entra ID...

Found 3 device name(s) with duplicates.
  Keeping: LAPTOP-ABC123 (ID: 12345..., LastSeen: 10/01/2024 09:30:00 AM)
    Removing: LAPTOP-ABC123 (ID: 98765...)
    Removing: LAPTOP-ABC123 (ID: 45678...)

Finding devices last seen before 04/15/2024 (~180 days ago)...
Found 12 stale device(s).
  Removing: OLD-DEVICE-001 (LastSeen: 03/10/2024 02:15:00 PM)
  ...

Removal list exported to: DevicesToRemove_20241010.csv
Total devices removed: 15
Important Notes
Before Running in Production

Always run with -AuditOnly first to preview changes
Review the CSV export to ensure correct devices will be removed
Test in a non-production tenant if available
Communicate with your team about the cleanup

Limitations

Devices can be recovered from Entra ID recycle bin for 30 days
Large tenants may require extended execution time
Does not handle Intune-specific device configurations

Troubleshooting
Module Import Errors
powershell# Run in a fresh PowerShell session or manually import
Get-Module Microsoft.Graph* | Remove-Module -Force
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.DirectoryManagement
Permission Denied

Ensure you have Cloud Device Administrator or Global Administrator role
Re-authenticate: Connect-MgGraph -Scopes Device.ReadWrite.All

Contributing
Contributions are welcome! Please feel free to submit a Pull Request.
License
This project is licensed under the MIT License - see the LICENSE file for details.
Author
Dakota McCurdy - GitHub | LinkedIn

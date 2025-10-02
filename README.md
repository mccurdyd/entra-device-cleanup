# Entra ID Device Cleanup

A PowerShell script to identify and remove duplicate and stale device registrations in Microsoft Entra ID (formerly Azure AD).

## Features

- **Smart Duplicate Detection** - Automatically identifies devices with the same DisplayName
- **Intelligent Preservation** - Keeps the most recently active managed device
- **Stale Device Cleanup** - Removes devices inactive for a configurable period (default: 180 days)
- **Audit Mode** - Preview changes before execution
- **CSV Export** - Generates detailed removal report

## Prerequisites

### Required Modules
```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
Install-Module ImportExcel -Scope CurrentUser
Required Permissions

Device.ReadWrite.All

Required Roles

Cloud Device Administrator or Global Administrator

Usage
Audit Mode
powershell.\Remove-EntraDeviceDuplicates.ps1 -AuditOnly
Remove Duplicates and Stale Devices
powershell.\Remove-EntraDeviceDuplicates.ps1
Custom Stale Threshold
powershell.\Remove-EntraDeviceDuplicates.ps1 -StaleDays 90
Author
Dakota McCurdy - GitHub | LinkedIn

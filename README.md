# SQL Database Backup Script

PowerShell script for backing up SQL Server databases with cloud storage support.

## Features

- SQL Server database backup with compression
- ZIP compression of backup files
- Multiple cloud storage support (configured via JSON)
- Local backup retention
- Detailed logging
- Modular design
- Automatic cleanup of old backups
- Support for multiple cloud providers simultaneously

## Prerequisites

- PowerShell 5.1 or later
- SQL Server PowerShell module (`SqlServer`)
- 7-Zip installed (default path: `C:\Program Files\7-Zip\7z.exe`)
- Rclone installed and configured (default path: `C:\Program Files\rclone\rclone.exe`)

## Installation

1. Install required PowerShell module:

```powershell
Install-Module -Name SqlServer
```

For PowerShell version 5:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name SqlServer -Force -AllowClobber
```

2. Install [7-Zip](https://7-zip.org/)
3. Install and configure [Rclone](https://rclone.org/) for your cloud providers

## Configuration

The script uses a configuration hashtable. Here's an example configuration:

```powershell
$config = @{
    # Database settings
    DatabaseName = "YourDatabase"
    SqlServer = "localhost"
    SqlUser = "sa"
    SqlPassword = "YourPassword"

    # Paths
    TempBackupDir = "D:\Backup\Temp\YourDB"
    BackupDir = "D:\Backup\Backup\YourDB"
    LogPath = "D:\Backup\Logs\backup.log"
    
    # Tools paths
    SevenZipPath = "C:\Program Files\7-Zip\7z.exe"
    RclonePath = "C:\Program Files\rclone\rclone.exe"
    
    # Backup settings
    MaxBackups = 4  # Number of backups to keep locally
    
    # Cloud storage configurations
    CloudStorages = @(
        @{
            Name = "Provider1"
            Provider = "provider1"
            Path = "backup/path1/"
        },
        @{
            Name = "Provider2"
            Provider = "provider2"
            Path = "backup/path2/"
        }
    )
}
```

## Usage

1. Configure the script by modifying the `$config` hashtable
2. Run the script:
```powershell
.\backup_sql_universal.ps1
```

## Logging

The script creates detailed logs including:
- Backup process start/end
- SQL backup status
- Compression operations
- Cloud upload status for each provider
- Cleanup operations
- Any errors or warnings

Logs are separated by a line of dashes for each script run for better readability.

## Error Handling

- The script includes comprehensive error handling
- If a cloud upload fails, the script continues with other providers
- All errors are logged to the specified log file
- The script maintains the backup file even if cloud uploads fail

## Maintenance

The script automatically:
- Cleans up temporary files after backup
- Maintains only the specified number of recent backups (controlled by `MaxBackups`)
- Creates necessary directories if they don't exist


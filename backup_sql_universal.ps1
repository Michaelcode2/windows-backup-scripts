# Script configuration
$config = @{
    # Database settings
    DatabaseName = "RDM3"
    SqlServer = "localhost"
    SqlUser = "sa"
    SqlPassword = "XXXXX" 

    # Paths
    TempBackupDir = "D:\Backup\Temp\RDM3"
    BackupDir = "D:\Backup\Backup\RDM3"
    LogPath = "D:\Backup\Logs\RDM_backup.log"
    
    # Tools paths
    SevenZipPath = "C:\Program Files\7-Zip\7z.exe"
    RclonePath = "C:\Program Files\rclone\rclone.exe"
    
    # Backup settings
    MaxBackups = 4
    
    # Cloud storage configurations
    CloudStorages = @(
        @{
            Name = "Hetzner"
            Provider = "hetzner"
            Path = "backup/RDM/"
        },
        @{
            Name = "AWS S3"
            Provider = "aws"
            Path = "s3-bucket-name/foldername/"
        }
    )
}

# Helper function for consistent logging
function Write-BackupLog {
    param($Message)
    & $LogFunction $Message
}

# Function to execute SQL backup
function Invoke-SqlBackup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Server,
        [Parameter(Mandatory = $true)]
        [string]$Database,
        [Parameter(Mandatory = $true)]
        [string]$BackupFile,
        [Parameter(Mandatory = $true)]
        [string]$Username,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $false)]
        [scriptblock]$LogFunction = { param($Message) Write-Output $Message }
    )

    # Helper function for consistent logging
    function Write-BackupLog {
        param($Message)
        & $LogFunction $Message
    }

    # Find SQL command-line tool
    $possiblePaths = @(
        "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\osql.exe",
        "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.exe",
        "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.exe"
    )

    $sqlTool = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $sqlTool = $path
            Write-BackupLog "Found SQL tool at: $sqlTool"
            break
        }
    }

    if (-not $sqlTool) {
        throw "SQL command-line tools not found. Checked paths: $($possiblePaths -join ', ')"
    }

    # Execute backup
    Write-BackupLog "Starting SQL backup using command-line tool"
    $result = & $sqlTool -S $Server -U $Username -P $Password -Q "BACKUP DATABASE [$Database] TO DISK='$BackupFile' WITH COMPRESSION"
    
    if ($LASTEXITCODE -ne 0) {
        throw "SQL Backup failed with exit code $LASTEXITCODE. Output: $result"
    }

    Write-BackupLog "SQL Backup completed successfully"
    return $true
}

try {
    # Add separator for new script run
    Write-Log ("-" * 80)
    Write-Log "Starting new backup process"

    # Create timestamp for backup files
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $bakFile = Join-Path $config.TempBackupDir "$timestamp-$($config.DatabaseName).bak"
    $zipFile = Join-Path $config.TempBackupDir "$timestamp-$($config.DatabaseName).zip"

    # Ensure directories exist
    @($config.TempBackupDir, $config.BackupDir, (Split-Path $config.LogPath -Parent)) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force
        }
    }

    # SQL Backup
    Write-Log "Starting SQL Backup for database $($config.DatabaseName)"
    Invoke-SqlBackup -Server $config.SqlServer `
                    -Database $config.DatabaseName `
                    -BackupFile $bakFile `
                    -Username $config.SqlUser `
                    -Password $config.SqlPassword `
                    -LogFunction ${function:Write-Log}
    Write-Log "SQL Backup completed"

    # Create ZIP archive
    Write-Log "Creating ZIP archive"
    & $config.SevenZipPath a $zipFile -tzip -mx5 $bakFile
    if ($LASTEXITCODE -ne 0) { throw "7-Zip compression failed" }
    Remove-Item $bakFile -Force
    Write-Log "ZIP archive created"

    # Upload to configured cloud storages
    foreach ($storage in $config.CloudStorages) {
        Write-Log "Uploading to $($storage.Name)"
        #$rcloneCommand = "&'$($config.RclonePath)' copyto `"$zipFile`" `"$($storage.Provider):$($storage.Path)$(Split-Path $zipFile -Leaf)`""
        #Write-Log "Executing command: $rcloneCommand"
        try {
            & "$($config.RclonePath)" copyto "$zipFile" "$($storage.Provider):$($storage.Path)$(Split-Path $zipFile -Leaf)"
            if ($LASTEXITCODE -ne 0) {
                Write-Log "WARNING: Upload to $($storage.Name) failed with exit code $LASTEXITCODE"
                continue
            }
            Write-Log "$($storage.Name) upload completed"
        }
        catch {
            Write-Log "ERROR: Upload to $($storage.Name) failed: $_"
            continue
        }
    }

    # Move to archive folder
    Write-Log "Moving to archive folder"
    Move-Item $zipFile $config.BackupDir -Force
    Write-Log "Archive moved"

    # Cleanup old backups
    Write-Log "Cleaning up old backups"
    Get-ChildItem $config.BackupDir -Filter "*.zip" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -Skip $config.MaxBackups | 
        Remove-Item -Force
    Write-Log "Old backups cleaned up"

    # Clean temp directory
    Write-Log "Cleaning temporary directory"
    Get-ChildItem $config.TempBackupDir | Remove-Item -Force -Recurse
    Write-Log "Temporary directory cleaned"

    Write-Log "Backup process completed successfully"
}
catch {
    $errorMessage = "Backup failed: $_"
    Write-Log $errorMessage
    throw $errorMessage
}

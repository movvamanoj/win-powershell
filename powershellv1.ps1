# Dynamically retrieve all disk numbers
$diskNumbers = Get-Disk | Where-Object { $_.IsOffline -eq $false } | Select-Object -ExpandProperty Number

Write-Host "Step 1: Checking and initializing disks if needed"
# Check if each disk is already initialized
foreach ($diskNumber in $diskNumbers) {
    $disk = Get-Disk -Number $diskNumber

    # Check if the disk is not online or not initialized
    if ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW')) {
        # Initialize the disk with GPT partition style
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT
        Write-Host "Disk $diskNumber initialized."
    }
    else {
        Write-Host "Disk $diskNumber is already initialized. Skipping initialization."
    }
}

Write-Host "Step 2: Creating partitions on each disk with specific drive letters"
# Create a new partition on each disk with specific drive letters
$nextAvailableDriveLetters = @()

foreach ($diskNumber in $diskNumbers) {
    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter
    $nextAvailableDriveLetters += $nextAvailableDriveLetter

    $driveLetterInUse = Get-Volume -DriveLetter $nextAvailableDriveLetter -ErrorAction SilentlyContinue

    if ($driveLetterInUse) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."
    }
}

Write-Host "Step 3: Formatting the volumes with the NTFS file system"
# Format the volumes with the NTFS file system, but only if they are not already formatted
foreach ($volume in Get-Volume -DriveLetter $nextAvailableDriveLetters -ErrorAction SilentlyContinue) {
    if ($volume.FileSystem -ne 'NTFS') {
        Format-Volume -DriveLetter $volume.DriveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $($volume.DriveLetter -as [int])" -AllocationUnitSize 65536 -ErrorAction Stop
        Write-Host "Volume $($volume.DriveLetter) formatted."
    }
    else {
        Write-Host "Volume $($volume.DriveLetter) is already formatted with NTFS. Skipping formatting."
    }
}

Write-Host "Script execution completed."

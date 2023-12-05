# Step 1: Initialization - Get a list of disks with attached volumes and initialize them if needed
$attachedDisks = Get-Disk | Where-Object { $_.IsOffline -eq $false -and $_.PartitionStyle -ne 'RAW' }

foreach ($disk in $attachedDisks) {
    $diskNumber = $disk.Number

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

# Step 2: Formatting - Format the volumes with NTFS file system
foreach ($disk in $attachedDisks) {
    $diskNumber = $disk.Number
    $volume = Get-Partition -DiskNumber $diskNumber | Get-Volume

    # Format the volume with NTFS file system
    Format-Volume -DriveLetter $volume.DriveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALL" -AllocationUnitSize 65536 -ErrorAction Stop
    Write-Host "Volume on Disk $diskNumber formatted and labeled."
}

# Step 3: Drive Letter Allocation - Allocate drive letters dynamically
$nextAvailableDriveLetters = @()

foreach ($disk in $attachedDisks) {
    $diskNumber = $disk.Number
    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter
    $nextAvailableDriveLetters += $nextAvailableDriveLetter

    if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping allocation."
    }
    else {
        # Assign the drive letter to the volume
        $volume = Get-Partition -DiskNumber $diskNumber | Get-Volume
        $volume | Set-Volume -NewDriveLetter $nextAvailableDriveLetter
        Write-Host "Drive letter $nextAvailableDriveLetter allocated for Disk $diskNumber."
    }
}

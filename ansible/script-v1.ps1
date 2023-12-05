# Collect disk numbers with allocated drive letters
$allocatedDisks = Get-Disk | Where-Object {
    $_.IsOffline -eq $false -and $_.PartitionStyle -ne 'RAW' -and (Get-Partition -DiskNumber $_.Number | Get-Volume).DriveLetter -ne $null
} | Select-Object -ExpandProperty Number

# Step 1: Initialization - Get a list of unallocated disks with attached volumes and initialize them if needed
$unallocatedDisks = Get-Disk | Where-Object { $_.IsOffline -eq $false -and $_.PartitionStyle -ne 'RAW' -and $_.Number -notin $allocatedDisks }

foreach ($disk in $unallocatedDisks) {
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

# Step 2: Formatting - Format the volumes with NTFS file system and set the label to "SC1CALL" for unallocated disks
foreach ($disk in $unallocatedDisks) {
    $diskNumber = $disk.Number
    $volume = Get-Partition -DiskNumber $diskNumber | Get-Volume

    # Check if the volume has a drive letter and is formatted
    if ($volume.DriveLetter -ne $null -and $volume.FileSystem -eq 'NTFS') {
        Write-Host "Volume on Disk $diskNumber is already formatted. Skipping formatting."
    }
    else {
        # Format the volume with NTFS file system and set the label to "SC1CALL"
        Format-Volume -DriveLetter $volume.DriveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALL" -AllocationUnitSize 65536 -ErrorAction Stop
        Write-Host "Volume on Disk $diskNumber formatted and labeled."
    }
}

# Step 3: Drive Letter Allocation - Allocate drive letters dynamically for unallocated disks
$nextAvailableDriveLetters = @()

foreach ($disk in $unallocatedDisks) {
    $diskNumber = $disk.Number
    $volume = Get-Partition -DiskNumber $diskNumber | Get-Volume

    # Check if the volume has a drive letter
    if ($volume.DriveLetter -ne $null) {
        Write-Host "Drive letter $($volume.DriveLetter) is already allocated for Disk $diskNumber. Skipping allocation."
    }
    else {
        $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

        # Assign the drive letter to the volume
        $volume | Set-Volume -NewDriveLetter $nextAvailableDriveLetter
        Write-Host "Drive letter $nextAvailableDriveLetter allocated for Disk $diskNumber."
    }
}

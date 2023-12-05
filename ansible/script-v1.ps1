# Check if any disk has already been allocated a drive letter
$allocatedDisks = Get-Disk | Where-Object { $_.IsOffline -eq $false -and $_.PartitionStyle -ne 'RAW' } | ForEach-Object {
    $volume = Get-Partition -DiskNumber $_.Number | Get-Volume
    if ($volume.DriveLetter -ne $null) {
        $_.Number
    }
}

if ($allocatedDisks.Count -gt 0) {
    Write-Host "Skipping the process for the following disks as they already have allocated drive letters: $($allocatedDisks -join ', ')"
}
else {
    # Step 1: Initialization - Get a list of disks with attached volumes and initialize them if needed
    $attachedDisks = Get-Disk | Where-Object { $_.IsOffline -eq $false -and $_.PartitionStyle -ne 'RAW' }

    foreach ($disk in $attachedDisks) {
        $diskNumber = $disk.Number

        # Debug information
        Write-Host "Checking Disk $diskNumber"

        # Check if the disk already has a drive letter allocated
        $volume = Get-Partition -DiskNumber $diskNumber | Get-Volume
        Write-Host "Drive Letter: $($volume.DriveLetter)"

        if ($volume.DriveLetter -ne $null) {
            Write-Host "Skipping Disk $diskNumber as it already has an allocated drive letter: $($volume.DriveLetter)"
        }
        else {
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
    }


# Step 2: Formatting - Format the volumes with NTFS file system for disks that are initialized
foreach ($disk in $attachedDisks) {
    $diskNumber = $disk.Number
    $volume = Get-Partition -DiskNumber $diskNumber | Get-Volume

    # Check if the volume has a drive letter and is formatted
    if ($volume.DriveLetter -ne $null -and $volume.FileSystem -eq 'NTFS') {
        Write-Host "Volume on Disk $diskNumber is already formatted. Skipping formatting."
    }
    else {
        # Format the volume with NTFS file system
        Format-Volume -DriveLetter $volume.DriveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALL" -AllocationUnitSize 65536 -ErrorAction Stop
        Write-Host "Volume on Disk $diskNumber formatted and labeled."
    }
}

# Step 3: Drive Letter Allocation - Allocate drive letters dynamically for disks that are initialized
$nextAvailableDriveLetters = @()

foreach ($disk in $attachedDisks) {
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
}

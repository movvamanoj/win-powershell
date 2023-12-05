# Specify the disk numbers
$diskNumbers = Get-Disk | Where-Object { $_.IsOffline -eq $false } | Select-Object -ExpandProperty Number

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $alphabet = [char[]]([int][char]'D'..[int][char]'Z')
   
    foreach ($letter in $alphabet) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
}

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
        $volumeName = "SC1CALL$diskNumber"  # Customize the volume name here
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter and custom name '$volumeName'."
    }
}

# Format the volumes with the NTFS file system, but only if they are not already formatted
foreach ($volume in Get-Volume -DriveLetter $nextAvailableDriveLetters -ErrorAction SilentlyContinue) {
    if ($volume.FileSystem -ne 'NTFS') {
        Format-Volume -DriveLetter $volume.DriveLetter -FileSystem NTFS -NewFileSystemLabel $volumeName -AllocationUnitSize 65536 -ErrorAction Stop
        Write-Host "Volume $($volume.DriveLetter) formatted with custom name '$volumeName'."
    }
    else {
        Write-Host "Volume $($volume.DriveLetter) is already formatted with NTFS. Skipping formatting."
    }
}

Write-Host "Script execution completed."

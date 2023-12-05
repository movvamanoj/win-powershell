# Dynamically retrieve all disk numbers
$diskNumbers = Get-Disk | Where-Object { $_.IsOffline -eq $false } | Select-Object -ExpandProperty Number

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | Select-Object -ExpandProperty DriveLetter
    $alphabet = [char[]]('D'..'Z')
   
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

# Create a new partition on each disk with specific drive letters and volume label
foreach ($diskNumber in $diskNumbers) {
    $driveLetterInUse = Get-Partition -DiskNumber $diskNumber | Get-Volume | Select-Object -ExpandProperty DriveLetter

    if ($driveLetterInUse) {
        Write-Host "Drive letter $driveLetterInUse is already in use for Disk $diskNumber. Skipping partition creation."
        # Display current drive letter and label
        $currentVolume = Get-Volume -DriveLetter $driveLetterInUse
        Write-Host "Current Drive Letter: $($currentVolume.DriveLetter), Label: $($currentVolume.FileSystemLabel)"
    }
    else {
        $nextAvailableDriveLetter = Get-NextAvailableDriveLetter
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter -DriveLetter $nextAvailableDriveLetter
        $volumeLabel = "SC1CALL$($diskNumber)"
        Format-Volume -DriveLetter $nextAvailableDriveLetter -FileSystem NTFS -NewFileSystemLabel $volumeLabel -AllocationUnitSize 65536 -ErrorAction Stop
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter and label $volumeLabel."
    }
}

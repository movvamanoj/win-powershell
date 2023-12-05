# Dynamically get the disk numbers
$diskNumbers = Get-Disk | Where-Object { $_.OperationalStatus -eq 'Online' } | Select-Object -ExpandProperty Number

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
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

# Create a new partition on each disk with specific drive letters and dynamic volume label
foreach ($diskNumber in $diskNumbers) {
    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter
    $volumeLabel = "SC1CALL$diskNumber"
    
    if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."
        
        # Format the volume with NTFS file system and dynamic volume label
        Format-Volume -DriveLetter $nextAvailableDriveLetter -FileSystem NTFS -NewFileSystemLabel $volumeLabel -AllocationUnitSize 65536 -ErrorAction Stop
    }
}

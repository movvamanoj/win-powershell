# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $availableDriveLetters = [char[]]('D'..'Z' | Where-Object { $usedDriveLetters -notcontains $_ })
    
    if ($availableDriveLetters.Count -eq 0) {
        throw "No available drive letters found."
    }

    return $availableDriveLetters[0]
}

# Function to check if a drive letter is in use
function Test-DriveLetterInUse {
    param (
        [string]$DriveLetter
    )

    return Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
}

# Get a list of disk numbers dynamically
$diskNumbers = Get-Disk | Where-Object { $_.IsOffline -or ($_.PartitionStyle -eq 'RAW') } | Select-Object -ExpandProperty Number

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

    if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."
    }

    $nextAvailableDriveLetters += $nextAvailableDriveLetter
}

# Format the volumes with NTFS file system and set the volume label
for ($i = 0; $i -lt $diskNumbers.Count; $i++) {
    $volumeLabel = "SC1CALL$($i + 1)"
    Format-Volume -DriveLetter $nextAvailableDriveLetters[$i] -FileSystem NTFS -NewFileSystemLabel $volumeLabel -AllocationUnitSize 65536 -ErrorAction Stop
}

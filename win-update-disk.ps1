# Specify the disk numbers
$diskNumbers = 4, 5, 6, 7  # Add more disk numbers as needed

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

# Format the volumes with the NTFS file system
for ($i = 0; $i -lt $diskNumbers.Count; $i++) {
    Format-Volume -DriveLetter $nextAvailableDriveLetters[$i] -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $i" -AllocationUnitSize 65536 -ErrorAction Stop
}

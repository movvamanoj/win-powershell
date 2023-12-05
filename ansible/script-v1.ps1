# Specify the disk numbers
$diskNumbers = (Get-Disk).Number

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $alphabet = 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'

    foreach ($letter in $alphabet) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
}

# Function to test if a drive letter is in use
function Test-DriveLetterInUse {
    param (
        [string]$DriveLetter
    )

    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    return $usedDriveLetters -contains $DriveLetter
}

# Check if each disk is already initialized and has a drive letter
foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping initialization for Disk 0 (OS disk)."
        continue
    }

    $disk = Get-Disk -Number $diskNumber

    # Skip if the disk is already initialized or has a drive letter
    if ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW') -or (Test-DriveLetterInUse -DriveLetter $disk | Where-Object { $_.DriveLetter })) {
        Write-Host "Skipping initialization for Disk $diskNumber (Already initialized or has a drive letter)."
        continue
    }

    # Initialize the disk with GPT partition style
    Initialize-Disk -Number $diskNumber -PartitionStyle GPT
    Write-Host "Disk $diskNumber initialized."
}

# Create a new partition on each disk with specific drive letters
$nextAvailableDriveLetterCounter = 1

foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping partition creation for Disk 0 (OS disk)."
        continue
    }

    $disk = Get-Disk -Number $diskNumber

    # Skip if the disk already has a drive letter
    $existingDriveLetters = $disk | Get-Partition | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    if ($existingDriveLetters.Count -gt 0) {
        Write-Host "Skipping partition creation for Disk $diskNumber (Already has drive letters: $($existingDriveLetters -join ', '))."
        continue
    }

    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

    if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."
        $nextAvailableDriveLetterCounter++
    }
}

# Format the volumes with NTFS file system and specific label
foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping formatting for Disk 0 (OS disk)."
        continue
    }

    $driveLetter = Get-Partition -DiskNumber $diskNumber | Select-Object -ExpandProperty DriveLetter

    Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $diskNumber" -AllocationUnitSize 65536 -Confirm:$false
    Write-Host "Formatted volume with drive letter $driveLetter and label SC1CALLS $diskNumber."
}

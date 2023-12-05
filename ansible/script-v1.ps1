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

    # Check if the disk is already formatted
    if ($disk | Get-Partition | Where-Object { $_.DriveLetter }) {
        $existingDriveLetter = ($disk | Get-Partition | Where-Object { $_.DriveLetter }).DriveLetter
        Write-Host "Disk $diskNumber is already formatted with drive letter $existingDriveLetter. Skipping initialization."
    }
    else {
        # Initialize the disk with GPT partition style
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT
        Write-Host "Disk $diskNumber initialized."
    }
}

# Format the volumes with NTFS file system and specific label
foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping formatting for Disk 0 (OS disk)."
        continue
    }

    $disk = Get-Disk -Number $diskNumber

    # Skip if the disk already has a drive letter
    if (Test-DriveLetterInUse -DriveLetter ($disk | Get-Partition | Where-Object { $_.DriveLetter })) {
        Write-Host "Skipping formatting for Disk $diskNumber (Already has a drive letter)."
        continue
    }

    # Check if the disk is already formatted
    if ($disk | Get-Partition | Where-Object { $_.DriveLetter }) {
        $existingDriveLetter = ($disk | Get-Partition | Where-Object { $_.DriveLetter }).DriveLetter
        Write-Host "Disk $diskNumber is already formatted with drive letter $existingDriveLetter. Skipping formatting."
    }
    else {
        $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

        if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
            Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping formatting."
        }
        else {
            New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
            Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."
            
            Format-Volume -DriveLetter $nextAvailableDriveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $diskNumber" -AllocationUnitSize 65536 -Confirm:$false
            Write-Host "Formatted volume with drive letter $nextAvailableDriveLetter and label SC1CALLS $diskNumber."
        }
    }
}

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

# Function to check if a drive letter is assigned to a disk
function Test-DriveLetterAssigned {
    param (
        [int]$DiskNumber
    )

    $assignedDriveLetter = Get-Partition -DiskNumber $DiskNumber | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    return [bool]($assignedDriveLetter -ne $null)
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
    if ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW') -or (Test-DriveLetterAssigned -DiskNumber $diskNumber)) {
        Write-Host "Skipping initialization for Disk $diskNumber (Already initialized or has a drive letter)."
        continue
    }

    # Initialize the disk with GPT partition style
    Initialize-Disk -Number $diskNumber -PartitionStyle GPT
    Write-Host "Disk $diskNumber initialized."
}

# Format the volumes with NTFS file system and specific label
foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping formatting for Disk 0 (OS disk)."
        continue
    }

    # Skip if a drive letter is already assigned
    if (Test-DriveLetterAssigned -DiskNumber $diskNumber) {
        $assignedDriveLetter = Get-Partition -DiskNumber $diskNumber | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
        Write-Host "Drive letter $assignedDriveLetter is already assigned to Disk $diskNumber. Skipping formatting."
        continue
    }

    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

    Format-Volume -DriveLetter $nextAvailableDriveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $diskNumber" -AllocationUnitSize 65536 -Confirm:$false
    Write-Host "Formatted volume with drive letter $nextAvailableDriveLetter and label SC1CALLS $diskNumber."
}

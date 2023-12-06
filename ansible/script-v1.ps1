# Step 1: Collect existing disk letters along with disk numbers
$diskNumbersLetter = Get-Disk | Where-Object { $_.IsOffline -eq $false -and $_.PartitionStyle -ne 'RAW' } | ForEach-Object {
    [PSCustomObject]@{
        DiskNumber = $_.Number
        DriveLetter = $_ | Get-Partition | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
    }
}

# Step 2: Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    param (
        [string[]]$UsedDriveLetters
    )
    $alphabet = 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'

    foreach ($letter in $alphabet) {
        if ($UsedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
}

# Step 3: Function to test if a drive letter is in use
function Test-DriveLetterInUse {
    param (
        [string]$DriveLetter
    )

    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    return $usedDriveLetters -contains $DriveLetter
}

# Step 4: Initialize and create partitions for each disk
foreach ($diskInfo in $diskNumbersLetter) {
    $diskNumber = $diskInfo.DiskNumber
    $driveLetter = $diskInfo.DriveLetter

    # Skip if the disk is already initialized or has a drive letter
    if ($diskNumber -eq 0 -or $driveLetter) {
        Write-Host "Skipping initialization for Disk $diskNumber (Already initialized or has a drive letter)."
        continue
    }

    # Initialize the disk with GPT partition style
    Initialize-Disk -Number $diskNumber -PartitionStyle GPT
    Write-Host "Disk $diskNumber initialized."

    # Get the next available drive letter
    $usedDriveLetters = $diskNumbersLetter | Where-Object { $_.DiskNumber -ne $diskNumber } | Select-Object -ExpandProperty DriveLetter
    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter -UsedDriveLetters $usedDriveLetters

    if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        # Create a new partition on the disk
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."
    }
}

# Step 5: Format the volumes with NTFS file system and specific label
$nextAvailableDriveLetters = $diskNumbersLetter | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter

for ($i = 0; $i -lt $nextAvailableDriveLetters.Count; $i++) {
    $driveLetter = $nextAvailableDriveLetters[$i]

    # Skip Disk 0 (OS disk)
    if ($i -eq 0) {
        Write-Host "Skipping formatting for Disk 0 (OS disk)."
        continue
    }

    Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $i" -AllocationUnitSize 65536 -Confirm:$false
    Write-Host "Formatted volume with drive letter $driveLetter and label SC1CALLS $i."
}

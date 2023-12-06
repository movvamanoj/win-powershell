# Step 1: Collect existing disk letters along with disk numbers
$diskNumbersLetter = Get-Disk | ForEach-Object {
    [PSCustomObject]@{
        DiskNumber = $_.Number
        DriveLetter = (Get-Partition -DiskNumber $_.Number | Get-Volume).DriveLetter
    }
}

# Step 2: Define Function to Get Next Available Drive Letter
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

# Step 3: Define Function to Test if Drive Letter is in Use
function Test-DriveLetterInUse {
    param (
        [string]$DriveLetter
    )

    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    return $usedDriveLetters -contains $DriveLetter
}

# Step 4: Create Partitions on Disks
foreach ($diskNumber in (Get-Disk).Number) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping partition creation for Disk 0 (OS disk)."
        continue
    }

    $existingDisk = $diskNumbersLetter | Where-Object { $_.DiskNumber -eq $diskNumber }

    # Skip if the disk already has a drive letter
    if ($existingDisk.DriveLetter -ne $null) {
        Write-Host "Skipping partition creation for Disk $diskNumber (Already has a drive letter $($existingDisk.DriveLetter))."
        continue
    }

    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

    if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        $partition = New-Partition -DiskNumber $diskNumber -UseMaximumSize
        $volume = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $diskNumber" -AllocationUnitSize 65536 -Confirm:$false
        Write-Host "Formatted volume with drive letter $($volume.DriveLetter) and label SC1CALLS $diskNumber."
    }
}

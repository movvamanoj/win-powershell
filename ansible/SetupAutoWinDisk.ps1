i# Specify the disk numbers
$diskNumbers = (Get-Disk).Number

# Create a variable to store allocated disk letters along with their disk numbers
$diskNumbersLetter = @{}

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $alphabet = 'G', 'D', 'E', 'F', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'

    foreach ($letter in $alphabet) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
}

# Function to test if a drive letter is in use for a specific disk
function Test-DriveLetterInUse {
    param (
        [int]$DiskNumber,
        [string]$DriveLetter
    )

    $usedDriveLetters = $diskNumbersLetter[$DiskNumber]
    return $usedDriveLetters -contains $DriveLetter
}

# Check if each disk is already initialized and has a drive letter
foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping initialization for Disk 0 (OS disk)."
        continue
    }

    # Skip if the disk is already initialized or has a drive letter
    if ($diskNumber -in $diskNumbersLetter.Keys) {
        Write-Host "Skipping initialization for Disk $diskNumber (Already initialized or has a drive letter)."
        continue
    }

    $disk = Get-Disk -Number $diskNumber

    # Check if the disk is already initialized
    if ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW')) {
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT
        Write-Host "Disk $diskNumber initialized."
    }
    else {
        Write-Host "Disk $diskNumber is already initialized. Skipping initialization."
    }

    # Add the disk number to the diskNumbersLetter with an empty array for drive letters
    $diskNumbersLetter[$diskNumber] = @()
}

# Create a new partition on each disk with specific drive letters
foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping partition creation for Disk 0 (OS disk)."
        continue
    }

    # Skip if the disk already has a drive letter
    if ($diskNumber -in $diskNumbersLetter.Keys -and $diskNumbersLetter[$diskNumber]) {
        Write-Host "Skipping partition creation for Disk $diskNumber (Already has a drive letter)."
        continue
    }

    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

    # Check if the drive letter is already in use
    if ($diskNumber -in $diskNumbersLetter.Keys -and $nextAvailableDriveLetter -in $diskNumbersLetter[$diskNumber]) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."
        $diskNumbersLetter[$diskNumber] += $nextAvailableDriveLetter
    }
}

# Format the volumes with NTFS file system and specific label
foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping formatting for Disk 0 (OS disk)."
        continue
    }

    foreach ($driveLetter in $diskNumbersLetter[$diskNumber]) {
        # Check if the partition exists before formatting
        if (Get-Partition -DiskNumber $diskNumber | Where-Object { $_.DriveLetter -eq $driveLetter }) {
            Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS" -AllocationUnitSize 65536 -Confirm:$false
            Write-Host "Formatted volume with drive letter $driveLetter and label SC1CALLS."
        }
        else {
            Write-Host "Partition with drive letter $driveLetter not found on Disk $diskNumber. Skipping formatting."
        }
    }
}

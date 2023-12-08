# Specify the desired drive letter
$desiredDriveLetter = 'P'

# Specify the disk numbers
$diskNumbers = (Get-Disk).Number

# Create a variable to store allocated disk letters along with their disk numbers
$diskNumbersLetter = @{}

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $alphabet = 'G'#, 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'

    foreach ($letter in $alphabet) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
}

# Function to check if a drive letter is in use for a specific disk
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

# Check if Disk 1 has a partition with drive letter G and change it to P
$diskNumberToChange = 1
$partitionsOnDisk = Get-Partition -DiskNumber $diskNumberToChange
$partitionWithDriveG = $partitionsOnDisk | Where-Object { $_.DriveLetter -eq 'G' }

if ($partitionWithDriveG) {
    # Change drive letter G to P for the partition on Disk 1
    $partitionWithDriveG | Set-Partition -NewDriveLetter $desiredDriveLetter -Confirm:$false
    Write-Host "Drive letter on Disk $diskNumberToChange changed from G to $desiredDriveLetter."
    $diskNumbersLetter[$diskNumberToChange] = $desiredDriveLetter
}
else {
    Write-Host "Disk $diskNumberToChange does not have drive letter G. Skipping drive letter change."
}

# Check for drive letter G and change it to P for all disks
foreach ($diskNumber in $diskNumbers) {
    # Check if Disk has a partition with drive letter G
    $partitionsOnDisk = Get-Partition -DiskNumber $diskNumber
    $partitionWithDriveG = $partitionsOnDisk | Where-Object { $_.DriveLetter -eq 'G' }

    if ($partitionWithDriveG) {
        # Change drive letter G to P for the partition on the current Disk
        $partitionWithDriveG | Set-Partition -NewDriveLetter $desiredDriveLetter -Confirm:$false
        Write-Host "Drive letter on Disk $diskNumber changed from G to $desiredDriveLetter."
        $diskNumbersLetter[$diskNumber] = $desiredDriveLetter
    }
    else {
        Write-Host "Disk $diskNumber does not have drive letter G. Skipping drive letter change."
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
        $partitionToFormat = Get-Partition -DiskNumber $diskNumber | Where-Object { $_.DriveLetter -eq $driveLetter }

        if ($partitionToFormat) {
            Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS" -AllocationUnitSize 65536 -Confirm:$false
            Write-Host "Formatted volume with drive letter $driveLetter and label SC1CALLS."
        }
        else {
            Write-Host "Partition with drive letter $driveLetter not found on Disk $diskNumber. Skipping formatting."
        }
    }
}

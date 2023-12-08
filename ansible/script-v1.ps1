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

     # Print drive letters before attempting to change
    Write-Host "Drive letters on Disk $diskNumber before change: $($diskNumbersLetter[$diskNumber] -join ', ')"

    # Check if the disk already has a drive letter G
    $partitionsOnDisk = Get-Partition -DiskNumber $diskNumber
    $partitionsInfo = $partitionsOnDisk | Select-Object DiskNumber, PartitionNumber, Size, DriveLetter, Type, FileSystem, Status | Format-Table | Out-String
    Write-Host ("Partitions on Disk {0}: {1}" -f $diskNumber, $partitionsInfo)

    if ($diskNumber -in $diskNumbersLetter.Keys -and 'G' -in $diskNumbersLetter[$diskNumber]) {
        # Change drive letter from G to P
        $partition = $partitionsOnDisk | Where-Object { $_.DriveLetter -eq 'G' }

        if ($partition) {
            $partition | Set-Partition -NewDriveLetter $desiredDriveLetter
            Write-Host "Drive letter on Disk $diskNumber changed from G to $desiredDriveLetter."
            $diskNumbersLetter[$diskNumber] = $diskNumbersLetter[$diskNumber] -replace 'G', $desiredDriveLetter

            # Refresh the disk information
            $disk = Get-Disk -Number $diskNumber
            if ($disk.IsOffline) {
                Online-Disk -Number $diskNumber
            }
        }
        else {
            Write-Host "Partition with drive letter G not found on Disk $diskNumber. Skipping drive letter change."
        }
    }
    else {
        Write-Host "Disk $diskNumber does not have drive letter G. Skipping drive letter change."
    }

    # Print drive letters after any changes
    Write-Host "Drive letters on Disk $diskNumber after any changes: $($diskNumbersLetter[$diskNumber] -join ', ')"
}

# Continue with other processes (e.g., initialization, partition creation, formatting) as usual
# ...

# For example, initialization
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

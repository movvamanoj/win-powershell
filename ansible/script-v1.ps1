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

# Dynamically find the disk number with the drive letter G
# Find the disk number with drive letter G
$diskNumberToChange = ($diskNumbersLetter.GetEnumerator() | Where-Object { $_.Value -contains 'G' }).Key

# Check if Disk 1 has a partition with drive letter G and change it to P
if ($diskNumberToChange) {
    $partitionsOnDisk = Get-Partition -DiskNumber $diskNumberToChange
    $partitionWithDriveG = $partitionsOnDisk | Where-Object { $_.DriveLetter -eq 'G' -or $_.AccessPaths -contains 'G:\' }

    if ($partitionWithDriveG) {
        # Change drive letter G to P for the partition on the specified disk
        $partitionWithDriveG | Set-Partition -NewDriveLetter $desiredDriveLetter -Confirm:$false
        Write-Host "Drive letter on Disk $diskNumberToChange changed from G to $desiredDriveLetter."
        $diskNumbersLetter[$diskNumberToChange] = $desiredDriveLetter
    }
    else {
        Write-Host "Disk $diskNumberToChange does not have drive letter G. Skipping drive letter change."
    }
}
else {
    Write-Host "No disk found with drive letter G. Skipping drive letter change."
}
# Continue with other processes (e.g., initialization, partition creation, formatting) as usual
# ...


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
    if (Test-DriveLetterInUse -DiskNumber $diskNumber -DriveLetter $nextAvailableDriveLetter) {
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

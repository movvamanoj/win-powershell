# Step 1: Specify Disk Numbers
$diskNumbersLetter = @()

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

# Step 4: Check if Disks are Initialized and Have Drive Letters
foreach ($diskNumber in $diskNumbers) {
    # Skip if the disk has already been processed
    if ($diskNumbersLetter -contains $diskNumber) {
        Write-Host "Skipping partition creation for Disk $diskNumber (Already processed)."
        continue
    }

    # Get the next available drive letter
    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

    # Initialize the disk with GPT partition style if needed
    if ($diskNumber -eq 0) {
        Write-Host "Skipping initialization for Disk 0 (OS disk)."
    }
    elseif ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW') -or (Test-DriveLetterInUse -DriveLetter $disk | Where-Object { $_.DriveLetter })) {
        Write-Host "Skipping initialization for Disk $diskNumber (Already initialized or has a drive letter)."
    }
    else {
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT
        Write-Host "Disk $diskNumber initialized."

        # Add the new drive letter and number to the processed list
        $diskNumbersLetter += "$($diskNumber):$($nextAvailableDriveLetter)"
    }
}

# Step 5: Create Partitions on Disks
foreach ($diskNumber in $diskNumbers) {
    # Skip if the disk has already been processed
    if ($diskNumbersLetter -contains $diskNumber) {
        Write-Host "Skipping partition creation for Disk $diskNumber (Already processed)."
        continue
    }

    # Get the next available drive letter
    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

    # Check if the next available drive letter is already in use
    if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."

        # Add the new drive letter and number to the processed list
        $diskNumbersLetter += "$($diskNumber):$($nextAvailableDriveLetter)"
    }
}

# Step 6: Format Volumes
foreach ($diskInfo in $diskNumbersLetter) {
    $diskNumber, $driveLetter = $diskInfo -split ":"

    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping formatting for Disk 0 (OS disk)."
        continue
    }

    Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALL$diskNumber" -AllocationUnitSize 65536 -Confirm:$false
    Write-Host "Formatted volume with drive letter $driveLetter and label SC1CALL$diskNumber."
}

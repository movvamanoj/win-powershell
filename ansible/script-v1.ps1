# Function to get disk numbers associated with existing drive letters
function Get-ExistingDiskNumbers {
    $existingDiskNumbers = @()

    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter

    foreach ($driveLetter in $usedDriveLetters) {
        $partition = Get-Partition -DriveLetter $driveLetter
        $existingDiskNumbers += $partition.DiskNumber
    }

    return $existingDiskNumbers | Sort-Object -Unique
}

# Specify the disk numbers
$allDiskNumbers = 0..15  # Adjust the range based on your system's disk numbers
$existingDiskNumbers = Get-ExistingDiskNumbers
$diskNumbersToProcess = $allDiskNumbers | Where-Object { $_ -notin $existingDiskNumbers }

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    param (
        [char]$StartLetter = 'D'
    )

    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $alphabet = [char[]]($StartLetter..'Z')
   
    foreach ($letter in $alphabet) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
}

# Check if each disk is already initialized
foreach ($diskNumber in $diskNumbersToProcess) {
    try {
        $disk = Get-Disk -Number $diskNumber

        # Check if the disk is not online or not initialized
        if ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW')) {
            # Initialize the disk with GPT partition style
            Initialize-Disk -Number $diskNumber -PartitionStyle GPT
            Write-Host "Disk $($diskNumber) initialized."
        }
        else {
            Write-Host "Disk $($diskNumber) is already initialized. Skipping initialization."
        }
    } catch {
        Write-Host "Error initializing Disk $($diskNumber): $_"
    }
}

# Create a new partition on each disk with specific drive letters
$nextAvailableDriveLetters = @()

foreach ($diskNumber in $diskNumbersToProcess) {
    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter
    $nextAvailableDriveLetters += $nextAvailableDriveLetter

    if (Test-DriveLetterInUse -DriveLetter $nextAvailableDriveLetter) {
        Write-Host "Drive letter $($nextAvailableDriveLetter) is already in use for Disk $($diskNumber). Skipping partition creation."
    }
    else {
        try {
            New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
            Write-Host "Partition on Disk $($diskNumber) created with drive letter $($nextAvailableDriveLetter)."
        } catch {
            Write-Host "Error creating partition on Disk $($diskNumber): $_"
        }
    }
}

# Format the volumes with NTFS file system
for ($i = 0; $i -lt $diskNumbersToProcess.Count; $i++) {
    try {
        Format-Volume -DriveLetter $nextAvailableDriveLetters[$i] -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $i" -AllocationUnitSize 65536 -ErrorAction Stop
        Write-Host "Volume on Drive $nextAvailableDriveLetters[$i] formatted."
    } catch {
        Write-Host "Error formatting volume on Drive $nextAvailableDriveLetters[$i]: $_"
    }
}

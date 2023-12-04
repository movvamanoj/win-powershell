# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $alphabet = [char[]]('D'..'Z')
   
    foreach ($letter in $alphabet) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
}

# Get all disk numbers from Get-Disk
$allDiskNumbers = Get-Disk | Where-Object { $_.OperationalStatus -eq 'Online' -and $_.PartitionStyle -ne 'RAW' } | Select-Object -ExpandProperty Number

# Use all available disks
$diskNumbers = $allDiskNumbers

# Create a new partition on each disk with dynamically assigned drive letters
foreach ($diskNumber in $diskNumbers) {
    $nextAvailableDriveLetter = Get-NextAvailableDriveLetter

    # Check if the drive letter is already in use for the disk
    $driveLetterInUse = Get-Volume -DriveLetter $nextAvailableDriveLetter -ErrorAction SilentlyContinue

    if ($driveLetterInUse) {
        Write-Host "Drive letter $nextAvailableDriveLetter is already in use for Disk $diskNumber. Skipping partition creation."
    }
    else {
        # Check if the disk is not online or not initialized
        $disk = Get-Disk -Number $diskNumber
        if ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW')) {
            # Initialize the disk with GPT partition style
            Initialize-Disk -Number $diskNumber -PartitionStyle GPT
            Write-Host "Disk $diskNumber initialized."
        }
        else {
            Write-Host "Disk $diskNumber is already initialized. Skipping initialization."
        }

        # Create a new partition with the dynamically assigned drive letter
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter | Out-Null
        $driveLetter = (Get-Partition -DiskNumber $diskNumber).DriveLetter
        Write-Host "Partition on Disk $diskNumber created with dynamically assigned drive letter $driveLetter."

        # Set the volume label to "SC1CALL"
        Get-Partition -DiskNumber $diskNumber | Set-Volume -NewFileSystemLabel "SC1CALL" -Confirm:$false
        Write-Host "Volume label for Disk $diskNumber set to SC1CALL."
    }
}

# Format the volumes with the NTFS file system  
foreach ($diskNumber in $diskNumbers) {
    # Get the dynamically assigned drive letter of the formatted partition
    $driveLetter = (Get-Partition -DiskNumber $diskNumber).DriveLetter

    # Format the volume only if it's not an existing EBS volume
    if (-not (Get-Volume -DriveLetter $driveLetter | Where-Object FileSystemLabel -eq "SC1CALL" -ErrorAction SilentlyContinue)) {
        Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALL" -AllocationUnitSize 65536 -ErrorAction Stop
        Write-Host "Volume on Disk $diskNumber formatted with dynamically assigned drive letter $driveLetter and labeled as SC1CALL."
    }
    else {
        Write-Host "Volume on Disk $diskNumber is an existing EBS volume. Skipping formatting."
    }
}
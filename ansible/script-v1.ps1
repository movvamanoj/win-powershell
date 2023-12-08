# Specify the disk numbers
$diskNumbers = (Get-Disk).Number

# Create a hashtable to store allocated disk letters for each disk
$diskNumbersLetter = @{}

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter

    if ($usedDriveLetters -notcontains 'G') {
        return 'G'
    }

    throw "No available drive letters found."
}

# Loop through each disk number and check if 'G' is present in the drive letters
foreach ($diskNumber in $diskNumbers) {
    if ($diskNumber -eq 0) {
        Write-Host "Skipping Disk 0 (OS disk)."
        continue
    }

    $driveLetters = $diskNumbersLetter[$diskNumber]

    if ($driveLetters -contains 'G') {
        # Change 'G' to 'P'
        $newDriveLetters = $driveLetters -replace 'G', 'P'

        # Update the stored drive letters with the modified ones
        $diskNumbersLetter[$diskNumber] = $newDriveLetters

        Write-Host "Drive letter 'G' found for Disk $diskNumber. Changing it to 'P' without formatting."

        # Get the partition information for the drive letter 'G' on the current disk
        $partition = Get-Partition -DiskNumber $diskNumber | Where-Object { $_.DriveLetter -eq 'G' }

        if ($partition) {
            # Set the new drive letter 'P' for the partition
            Set-Partition -InputObject $partition -NewDriveLetter 'P'
            Write-Host "Drive letter changed to 'P' for Disk $diskNumber without formatting."

            # Remove 'G' from the list of drive letters for the current disk
            $diskNumbersLetter[$diskNumber] = $newDriveLetters -ne 'G'
        } else {
            Write-Host "Partition with drive letter 'G' not found on Disk $diskNumber. Skipping drive letter change."
        }
    }
}

# Create a new partition on each disk with specific drive letters
foreach ($diskNumber in $diskNumbers) {
    if ($diskNumber -eq 0) {
        Write-Host "Skipping Disk 0 (OS disk)."
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
    } else {
        New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $nextAvailableDriveLetter
        Write-Host "Partition on Disk $diskNumber created with drive letter $nextAvailableDriveLetter."
        $diskNumbersLetter[$diskNumber] += $nextAvailableDriveLetter
    }
}

# Format the volumes with the NTFS file system and specific label
foreach ($diskNumber in $diskNumbers) {
    if ($diskNumber -eq 0) {
        Write-Host "Skipping formatting for Disk 0 (OS disk)."
        continue
    }

    foreach ($driveLetter in $diskNumbersLetter[$diskNumber]) {
        # Check if the partition exists before formatting
        if (Get-Partition -DiskNumber $diskNumber | Where-Object { $_.DriveLetter -eq $driveLetter }) {
            Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS" -AllocationUnitSize 65536 -NoFormatting -Confirm:$false
            Write-Host "Formatted volume with drive letter $driveLetter and label SC1CALLS."
        } else {
            Write-Host "Partition with drive letter $driveLetter not found on Disk $diskNumber. Skipping formatting."
        }
    }
}

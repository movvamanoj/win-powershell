# Specify the disk numbers
$diskNumbers = (Get-Disk).Number

# Function to check if the drive letter 'G' is present for a specific disk
function Test-DriveLetterGPresent {
    param (
        [string[]]$DriveLetters
    )

    return $DriveLetters -contains 'G'
}

# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $alphabet = 'G'
    
    foreach ($letter in $alphabet) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
}

# Check if any disk has the letter "G" and update it to "P" in $diskNumbersLetter
foreach ($diskNumber in $diskNumbers) {
    # Check if $diskNumbersLetter has an entry for the current disk number
    if ($diskNumbersLetter.ContainsKey($diskNumber)) {
        $driveLetters = $diskNumbersLetter[$diskNumber]

        # Check if "G" is present in the drive letters for the current disk
        if (Test-DriveLetterGPresent -DriveLetters $driveLetters) {
            foreach ($driveLetter in $driveLetters) {
                if ($driveLetter -eq 'G') {
                    # Change the drive letter from "G" to "P" without formatting
                    Set-Partition -DriveLetter 'G' -NewDriveLetter 'P' -NoFormatting -Confirm:$false

                    # Update $diskNumbersLetter with the new drive letter
                    $diskNumbersLetter[$diskNumber] = $diskNumbersLetter[$diskNumber] -replace 'G', 'P'

                    # Output a message about the change
                    Write-Host "Drive letter for Disk $diskNumber changed from 'G' to 'P'. No formatting performed."
                }
            }

            # Continue with the rest of the code for the specific disk
            # You can add the remaining code here or call other functions as needed
        } else {
            # Output a message indicating that "G" is not present for the current disk
            Write-Host "Drive letter 'G' not present for Disk $diskNumber. Skipping modification and continuing with the rest of the code."
        }
    } else {
        # Output a message indicating that there is no entry for the current disk number
        Write-Host "No entry found for Disk $diskNumber in $diskNumbersLetter. Skipping modification and continuing with the rest of the code."
    }
}


# Function to get the next available drive letter
function Get-NextAvailableDriveLetter {
    $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
    $alphabet = 'G'
    
    foreach ($letter in $alphabet) {
        if ($usedDriveLetters -notcontains $letter) {
            return $letter
        }
    }

    throw "No available drive letters found."
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

# Format the volumes with the NTFS file system and specific label
foreach ($diskNumber in $diskNumbers) {
    # Skip Disk 0 (OS disk)
    if ($diskNumber -eq 0) {
        Write-Host "Skipping formatting for Disk 0 (OS disk)."
        continue
    }

    foreach ($driveLetter in $diskNumbersLetter[$diskNumber]) {
        # Check if the partition exists before formatting
        if (Get-Partition -DiskNumber $diskNumber | Where-Object { $_.DriveLetter -eq $driveLetter }) {
            Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS" -AllocationUnitSize 65536 -NoFormatting -Confirm:$false
            Write-Host "Formatted volume with drive letter $driveLetter and label SC1CALLS."
        }
        else {
            Write-Host "Partition with drive letter $driveLetter not found on Disk $diskNumber. Skipping formatting."
        }
    }
}

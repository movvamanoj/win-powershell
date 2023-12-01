# Specify the disk numbers
$diskNumbers = 1


# Check if each disk is already initialized
foreach ($diskNumber in $diskNumbers) {
    $disk = Get-Disk -Number $diskNumber

    # Check if the disk is not online or not initialized
    if ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW')) {
        # Initialize the disk with GPT partition style
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT
        Write-Host "Disk $diskNumber initialized."
    }
    else {
        Write-Host "Disk $diskNumber is already initialized. Skipping initialization."
    }
}

<#
change drive letter of an existing drive
$script = @"
select volume P
assign letter=E
exit
"@

$script | diskpart
#>


# Create a new partition on each disk with specific drive letters
$drive_name1 = 'P'
# $drive_name2 = 'Q'


# Function to check if a drive letter is in use
function Test-DriveLetterInUse {
    param (
        [string]$DriveLetter
    )
   
    $existingDrive = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
    return [bool]($existingDrive -ne $null)
}

if (Test-DriveLetterInUse -DriveLetter $drive_name1) {
    Write-Host "Drive letter $drive_name1 is already in use. Skipping partition creation."
}
else {
    New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter $drive_name1
    Write-Host "Partition on Disk 1 created with drive letter $drive_name1."
}

<#
if (Test-DriveLetterInUse -DriveLetter $drive_name2) {
    Write-Host "Drive letter $drive_name2 is already in use. Skipping partition creation."
}
# else {
    New-Partition -DiskNumber 2 -UseMaximumSize -DriveLetter $drive_name2
    Write-Host "Partition on Disk 2 created with drive letter $drive_name2."
}
#>

# Format the volumes with NTFS file system

Format-Volume -DriveLetter $drive_name1 -FileSystem NTFS -NewFileSystemLabel "SC1CALLS" -AllocationUnitSize 65536 -ErrorAction Stop
# Format-Volume -DriveLetter $drive_name2 -FileSystem NTFS -NewFileSystemLabel "Local Disk" -AllocationUnitSize 65536 -ErrorAction Stop


# Get all volumes
$volumes = Get-Volume -ErrorAction SilentlyContinue

# Find the volume with DriveLetter G
$gDrive = $volumes | Where-Object DriveLetter -eq "G"

# Check if the G drive exists
if ($gDrive) {
    # Get the disk number of the G drive
    $diskNumber = $gDrive.DriveNumber

    # Change the drive letter to P
    Set-Partition -DriveLetter "G" -NewDriveLetter "P" -DiskNumber $diskNumber

    Write-Host "Successfully changed drive letter from G to P for disk number $diskNumber."
} else {
    Write-Host "Drive letter G is not assigned to any volume."
}


# Specify the current and desired drive letters
$oldDriveLetter = "G"
$newDriveLetter = "P"

try {
    # Get the partition that corresponds to the current drive letter
    $partition = Get-Partition -DriveLetter $oldDriveLetter -ErrorAction Stop

    # Change the drive letter to the new one
    Set-Partition -DriveLetter $oldDriveLetter -NewDriveLetter $newDriveLetter -Confirm:$false -ErrorAction Stop

    Write-Host "Drive letter changed successfully from $oldDriveLetter to $newDriveLetter." -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}


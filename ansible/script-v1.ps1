# Specify the desired drive letter
$desiredDriveLetter = 'P'

# Get all disks except the OS disk (Disk 0)
$disks = Get-Disk | Where-Object { $_.Number -gt 0 }

# Loop through each disk
foreach ($disk in $disks) {
  # Check for partitions with drive letter G
  $partitionsWithDriveG = $disk.Partitions | Where-Object { $_.DriveLetter -eq 'G' }

  # If any partition has G, change it and all others to desired letter
  if ($partitionsWithDriveG) {
    Write-Host "Changing drive letter for disk $disk.Number from G to $desiredDriveLetter..."

    foreach ($partition in $disk.Partitions) {
      Set-Partition -DriveLetter $desiredDriveLetter -Confirm:$false -InputObject $partition
    }

    Write-Host "Drive letter changed successfully."
    break
  }
}

# Report if no disk with G was found
if (!$partitionsWithDriveG) {
  Write-Host "No disk found with drive letter G."
}

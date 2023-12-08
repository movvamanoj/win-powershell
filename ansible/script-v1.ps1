# Get all disks
$disks = Get-Disk | Where-Object { $_.DriveLetter -ne $null }

# Find the disk with letter G
$gDisk = $disks | Where-Object { $_.DriveLetter -eq "G" }

# Check if G exists
if ($gDisk) {
  # Get the disk number
  $diskNumber = $gDisk.Number

  # Change the drive letter to P
  Set-Partition -DriveLetter "G" -NewDriveLetter "P" -DiskNumber $diskNumber
  Write-Host "Disk G successfully changed to P."
} else {
  Write-Host "Disk G not found."
}

$diskNumbers = (Get-Disk).Number

function Get-NextAvailableDriveLetter {
  $usedDriveLetters = Get-Volume | Select-Object -ExpandProperty DriveLetter
  $availableDriveLetters = 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'

  foreach ($letter in $availableDriveLetters) {
    if ($usedDriveLetters -notcontains $letter) {
      $usedDriveLetters += $letter
      return $letter
    }
  }

  throw "No available drive letters found."
}

foreach ($diskNumber in $diskNumbers) {
  if ($diskNumber -eq 0) {
    Write-Host "Skipping initialization for Disk 0 (OS disk)."
    continue
  }

  $disk = Get-Disk -Number $diskNumber

  if ($disk.IsOffline -or ($disk.PartitionStyle -eq 'RAW') -or (Test-DriveLetterInUse -DriveLetter $disk | Where-Object { $_.DriveLetter })) {
    Write-Host "Skipping initialization for Disk $diskNumber (Already initialized or has a drive letter)."
    continue
  }

  Initialize-Disk -Number $diskNumber -PartitionStyle GPT
  Write-Host "Disk $diskNumber initialized."
}

$assignedDriveLetters = @()

foreach ($diskNumber in $diskNumbers) {
  if ($diskNumber -eq 0) {
    Write-Host "Skipping partition creation for Disk 0 (OS disk)."
    continue
  }

  if (Test-DriveLetterInUse -DriveLetter ($disk | Get-Partition | Where-Object { $_.DriveLetter })) {
    Write-Host "Skipping partition creation for Disk $diskNumber (Already has a drive letter)."
    continue
  }

  $driveLetter = Get-NextAvailableDriveLetter

  if (Test-DriveLetterInUse -DriveLetter $driveLetter) {
    Write-Host "Drive letter $driveLetter is already in use for Disk $diskNumber. Skipping partition creation."
  }
  else {
    New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $driveLetter
    Write-Host "Partition on Disk $diskNumber created with drive letter $driveLetter."
    $assignedDriveLetters += $driveLetter
  }
}

for ($i = 0; $i -lt $assignedDriveLetters.Count; $i++) {
  $driveLetter = $assignedDriveLetters[$i]

  if ($i -eq 0) {
    Write-Host "Skipping formatting for Disk 0 (OS disk)."
    continue
  }

  Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -NewFileSystemLabel "SC1CALLS $i" -AllocationUnitSize 65536 -Confirm:$false
  Write-Host "Formatted volume with drive letter $driveLetter and label SC1CALLS $i."
}

# Get information about volumes
$volumes = Get-Volume

# Check if there is a volume with drive letter G
$targetVolume = $volumes | Where-Object { $_.DriveLetter -eq 'G' }

if ($targetVolume) {
    # Check if the volume is formatted
    if ($targetVolume.FileSystemType -ne 'RAW') {
        try {
            # Attempt to change the drive letter to P using Win32_Volume
            $volume = Get-WmiObject Win32_Volume -Filter "DriveLetter = 'G'"
            $volume.DriveLetter = 'P'
            $volume.Put()

            Write-Host "Drive letter changed from G to P successfully."
        } catch {
            Write-Host "Error changing drive letter: $_"
        }
    } else {
        Write-Host "The volume is not formatted. Cannot change the drive letter."
    }
} else {
    Write-Host "No volume with drive letter G found."
}

# Get information about volumes
$volumes = Get-Volume

# Check if there is a volume with drive letter G
$targetVolume = $volumes | Where-Object { $_.DriveLetter -eq 'G' }

if ($targetVolume) {
    try {
        # Attempt to change the drive letter to P
        $targetVolume | Set-Volume -NewDriveLetter P -Confirm:$false

        Write-Host "Drive letter changed from G to P successfully."
    } catch {
        Write-Host "Error changing drive letter: $_"
    }
} else {
    Write-Host "No volume with drive letter G found."
}

# Check if each disk is already initialized
foreach ($diskNumber in $diskNumbers) {
    $disk = Get-Disk -Number $diskNumber

    # Check if the disk is offline
    if ($disk.IsOffline) {
        # Try to clear the read-only attribute to bring the disk online
        Clear-Disk -Number $diskNumber -RemoveData -Confirm:$false
        Write-Host "Attempting to bring Disk $diskNumber online."
        
        # Wait for a moment to ensure the disk is online
        Start-Sleep -Seconds 5

        # Check if the disk is still offline
        $disk = Get-Disk -Number $diskNumber
        if ($disk.IsOffline) {
            Write-Host "Failed to bring Disk $diskNumber online."
        } else {
            Write-Host "Disk $diskNumber is brought online."
        }
    }

    # Check if the disk is not initialized
    if ($disk.PartitionStyle -eq 'RAW') {
        # Initialize the disk with GPT partition style
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT
        Write-Host "Disk $diskNumber initialized."
    }
    else {
        Write-Host "Disk $diskNumber is already initialized. Skipping initialization."
    }
}

# Ensure ADB is in your PATH or provide the full path to adb.exe
$adbPath = "adb" # Adjust if needed to full path like "C:\path\to\adb.exe"

# Set the maximum command length (adjust as needed)
$maxCommandLength = 4096

# Function to split commands into chunks
function Split-Command {
    param (
        [string[]]$commands,
        [int]$maxLength
    )
    $chunks = @()
    $currentChunk = ""
    
    foreach ($command in $commands) {
        if (($currentChunk.Length + $command.Length) -lt $maxLength) {
            $currentChunk += "$command "
        } else {
            $chunks += $currentChunk.TrimEnd()
            $currentChunk = "$command "
        }
    }
    
    if ($currentChunk) {
        $chunks += $currentChunk.TrimEnd()
    }

    return $chunks
}

Write-Host "Retrieving list of third-party packages..."

# Get the list of third-party packages
$packages = & $adbPath shell pm list packages -3

# Initialize a list to hold package names
$packageNames = @()

# Split the output into lines and process each package
$packages.Split("`n") | ForEach-Object {
    # Extract the package name (remove the "package:" prefix)
    $packageName = $_.Trim() -replace '^package:'

    if ($packageName) {
        $packageNames += $packageName
    }
}

Write-Host "$($packageNames.Count) third-party packages found."

# Split the batch command into smaller chunks if necessary
$commands = $packageNames | ForEach-Object { "am force-stop $_;" }
$commandChunks = Split-Command -commands $commands -maxLength $maxCommandLength

Write-Host "Executing force-stop commands..."

# Execute each chunk
foreach ($index in 0..($commandChunks.Count - 1)) {
    $chunk = $commandChunks[$index].Trim()
    if ($chunk) {
        Write-Host "Executing chunk $($index + 1) of $($commandChunks.Count)..."
        Start-Process -FilePath $adbPath -ArgumentList "shell $chunk" -NoNewWindow -Wait
    }
}

Write-Host "All third-party packages have been force stopped."

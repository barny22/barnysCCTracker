param(
    [string]$ApiToken,
    [int]$AddonId,
    [string]$Title,
    [string]$Version,
    [string]$FilePath,
    [string]$ChangelogFilePath,
    [string]$Compatible,
    [string]$ReadmeFilePath,
    [string]$Archive,
    [string]$TestOnly
)

    # Debugging-Ausgaben
    Write-Host "API Token: $ApiToken"
    Write-Host "AddOn Id: $AddonId"
    Write-Host "Title: $Title"
    Write-Host "Version: $Version"
    Write-Host "ZIP File Path: $FilePath"
    Write-Host "Changelog File Path: $ChangelogFilePath"
    Write-Host "Compatible: $Compatible"
    Write-Host "Readme File Path: $ReadmeFilePath"
    Write-Host "Archive: $Archive"
    Write-Host "Test: $TestOnly"

function Upload-Addon {
    param (
        [string]$ApiToken,
        [int]$AddonId,
        [string]$Title,
        [string]$Version,
        [string]$FilePath,
        [string]$ChangelogFilePath,
        [string]$Compatible,
        [string]$ReadmeFilePath,
        [string]$Archive,
        [string]$TestOnly
    )

    $url = if ($TestOnly -eq "true") {
        "https://api.esoui.com/addons/updatetest"
    } else {
        "https://api.esoui.com/addons/update"
    }

    $headers = @{
        "x-api-token" = $ApiToken
    }

    Write-Host "ZIP File Path: $FilePath"
    
    # Prepare the multipart form data
    $formData = @{
        "archive" = $Archive  # Set to "Yes" or "No" as required
        "updatefile" = Get-Item $FilePath
        "id" = $AddonId
        "title" = $Title  # Optional
        "version" = $Version
        "changelog" = $ChangelogFilePath
        "compatible" = $Compatible
        "description" = $description
    }

    # Debugging-Ausgaben
    Write-Host "Request Data: $($formData | Out-String)"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Form $formData
        Write-Host "Response code: $($response.StatusCode)"
        Write-Host "Response text: $($response.Content)"
    } catch {
        Write-Host "An error occurred: $_"
    }
}

# Changelog und Beschreibung aus den Dateien einlesen
$changelog = Get-Content $ChangelogFilePath -Raw
$description = Get-Content $ReadmeFilePath -Raw

# Call the function with parameters
Upload-Addon -ApiToken $ApiToken -AddonId $AddonId -Title $Title -Version $Version -FilePath $FilePath -changelog $changelog -Compatible $Compatible -description $description -Archive $Archive -TestOnly $TestOnly

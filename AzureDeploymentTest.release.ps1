$ProjectName = Get-ProjectName

# Create Nuspec
$NL = [System.Environment]::NewLine
$ManifestData = Import-PowerShellDataFile .\src\*.psd1
$NuspecData = (
    "<?xml version=`"1.0`"?>$NL" +
    "<package >$NL" +
    "<metadata>$NL" +
    "<id>$($ManifestData.RootModule.Split('.')[0])</id>$NL" +
    "<version>$($ManifestData.ModuleVersion)</version>$NL" +
    "<authors>$($ManifestData.Author)</authors>$NL" +
    "<owners>$($ManifestData.Author)</owners>$NL" +
    "<requireLicenseAcceptance>false</requireLicenseAcceptance>$NL" +
    "<description>$($ManifestData.Description)</description>$NL" +
    "<releaseNotes>$($ManifestData.PrivateData.PSData.ReleaseNotes)</releaseNotes>$NL" +
    "<copyright>$($ManifestData.Copyright)</copyright>$NL" +
    "<tags>$($ManifestData.PrivateData.PSData.Tags)</tags>$NL" +
    "<dependencies>$NL" +
    "</dependencies>$NL" +
    "</metadata>$NL" +
    "</package>"
)
Out-File -FilePath ".\src\$ProjectName.nuspec" -InputObject $NuspecData

# Set up Nuget
nuget sources Add -Name "AzureArtifacts" -Source "https://pkgs.dev.azure.com/natescherer/_packaging/NuGetFeed/nuget/v3/index.json"
nuget setupapikey $env:AZUREARTIFACTSPAT -Source "https://pkgs.dev.azure.com/natescherer/_packaging/NuGetFeed/nuget/v3/index.json"

# Publish Module
$NuspecPath = ".\src\$ProjectName.nuspec"
nuget pack .\src\$NuspecPath
Move-Item .\src\*.nupkg ".\src\$ProjectName.nupkg"
nuget push -Source "AzureArtifacts" ".\src\$ProjectName.nupkg"

# Clean up
Remove-Item ".\src\*.nupkg"
Remove-Item ".\src\*.nuspec"
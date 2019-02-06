[CmdletBinding()]
param (
    [parameter(Mandatory = $true)]
    [string]$AzureArtifactsPat
)

Set-Location $PSScriptRoot

Install-Module -Name BuildHelpers -Force -SkipPublisherCheck
$ProjectName = Get-ProjectName

# Create Nuspec
$NL = [System.Environment]::NewLine
$ManifestData = Import-PowerShellDataFile .\src\*.psd1
$FullVersion = $ManifestData.ModuleVersion
if ($ManifestData.PrivateData.PSData.Prerelease) {
    $FullVersion += "-" + $ManifestData.PrivateData.PSData.Prerelease
}
$NuspecData = (
    "<?xml version=`"1.0`"?>$NL" +
    "<package xmlns=`"http://schemas.microsoft.com/packaging/2011/10/nuspec.xsd`">$NL" +
    "<metadata>$NL" +
    "<id>$($ManifestData.RootModule.Split('.')[0])</id>$NL" +
    "<version>$FullVersion</version>$NL" +
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
Out-File -FilePath ".\out\$ProjectName\$ProjectName.nuspec" -InputObject $NuspecData

# Publish Module
$NuspecPath = ".\out\$ProjectName\$ProjectName.nuspec"
nuget pack $NuspecPath -OutputDirectory ".\out\$ProjectName"
Move-Item ".\out\$ProjectName\*.nupkg" ".\out\$ProjectName\$ProjectName.nupkg"
nuget sources add -name "AzureArtifacts" -source "https://pkgs.dev.azure.com/natescherer/_packaging/AzureArtifacts/nuget/v2" -username user -password $AzureArtifactsPat
nuget push ".\out\$ProjectName\$ProjectName.nupkg" -Source "AzureArtifacts" -ApiKey $AzureArtifactsPat

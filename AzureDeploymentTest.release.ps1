[CmdletBinding()]
param (
    [parameter(Mandatory = $true)]
    [parameter(ParameterSetName = "Dev")]
    [parameter(ParameterSetName = "Prod")]
    [ValidateSet("Dev","Prod")]
    [string]$Mode,

    [parameter(Mandatory = $true)]
    [parameter(ParameterSetName = "Dev")]
    [ValidateNotNullOrEmpty()]
    [string]$AzureArtifactsPat,

    [parameter(Mandatory = $true)]
    [parameter(ParameterSetName = "Prod")]
    [ValidateNotNullOrEmpty()]
    [string]$GitHubUser,

    [parameter(Mandatory = $true)]
    [parameter(ParameterSetName = "Prod")]
    [ValidateNotNullOrEmpty()]
    [string]$GitHubRepo,

    [parameter(Mandatory = $true)]
    [parameter(ParameterSetName = "Prod")]
    [ValidateNotNullOrEmpty()]
    [string]$GitHubPat 
)

$NL = [System.Environment]::NewLine
Set-Location $PSScriptRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-Module -Name BuildHelpers -Force -SkipPublisherCheck
$ProjectName = Get-ProjectName
$ManifestData = Import-PowerShellDataFile .\src\*.psd1
$FullVersion = $ManifestData.ModuleVersion
if ($ManifestData.PrivateData.PSData.Prerelease) { $FullVersion += "-" + $ManifestData.PrivateData.PSData.Prerelease }

if ($Mode -eq "Dev") {
    # Create Nuspec
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
}

if ($Mode -eq "Prod") {
    # Create GitHub Release
    $Zip = Get-ChildItem "out\$ProjectName*.zip"

    $AuthHeader = "Basic {0}" -f [System.Convert]::ToBase64String([char[]]"$GitHubUser`:$GitHubPat")
    $ReleaseFile = $Zip.FullName
    $ReleaseFilePath = Resolve-Path $ReleaseFile
    $ReleaseFileName = Split-Path -Path $ReleaseFilePath -Leaf
    $ReleaseVersion = $FullVersion
    $ReleaseBody = $ManifestData.PrivateData.PSData.ReleaseNotes

    $ReleaseParams = @{
        "Headers" = @{
            "Authorization" = $AuthHeader
        }
        "Body" = ConvertTo-Json -InputObject @{
            "tag_name" = "v$ReleaseVersion"
            "name"     = "v$ReleaseVersion"
            "body"     = $ReleaseBody
        }
        "Uri"     = "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases"
        "Method"  = "Post"
    }

    if ($Proxy) {
        $ReleaseParams += @{"Proxy" = "http://$Proxy"}
        $ReleaseParams += @{"ProxyUseDefaultCredentials" = $true}       
    }

    $ReleaseResult = Invoke-RestMethod @ReleaseParams

    if ($ReleaseResult.upload_url) {
        $UploadParams = @{
            "Headers" = @{
                "Authorization" = $AuthHeader
                "Content-Type"  = "application/zip"
            }
            "Uri"     = $ReleaseResult.upload_url.split("{")[0] + "?name=$ReleaseFileName"
            "Method"  = "Post"
            "InFile"  = $Zip.FullName
        }

        if ($Proxy) {
            $UploadParams += @{"Proxy" = "http://$Proxy"}
            $UploadParams += @{"ProxyUseDefaultCredentials" = $true}       
        }

        $UploadResult = Invoke-RestMethod @UploadParams
        if ($UploadResult.state -ne "uploaded") {
            Write-Output $UploadResult
            throw "There was a problem uploading."
        }
    }
    else {
        Write-Output $ReleaseResult
        throw "There was a problem releasing"
    }
}
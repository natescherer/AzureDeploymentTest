[CmdletBinding()]
param (
    [parameter(Mandatory = $true)]
    [string]$AzureArtifactsPat
)

Set-Location $PSScriptRoot

Install-Module -Name PowerShellGet, BuildHelpers -Force -SkipPublisherCheck
$ProjectName = Get-ProjectName

$RegisterSplat = @{
    Name = "AzureArtifacts"
    SourceLocation = "https://pkgs.dev.azure.com/natescherer/_packaging/AzureArtifacts/nuget/v2"
    PublishLocation = "https://pkgs.dev.azure.com/natescherer/_packaging/AzureArtifacts/nuget/v2"
    InstallationPolicy = "Trusted"
}
Register-PSRepository @RegisterSplat

$PublishSplat = @{
    Repository = "AzureArtifacts"
    Path = "$PSScriptRoot\out\$ProjectName"
    NuGetApiKey = $AzureArtifactsPat
    ErrorAction = "Stop"
}
Publish-Module @PublishSplat
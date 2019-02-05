Deploy ChangelogManagement {
    By Task SetupAzureArtifactsRepo {
        $AzureArtifactsSplat = @{
            Name = "AzureArtifacts"
            SourceLocation = "https://pkgs.dev.azure.com/natescherer/_packaging/ChangelogManagement/nuget/v2"
            PublishLocation = "https://pkgs.dev.azure.com/natescherer/_packaging/ChangelogManagement/nuget/v2"
            InstallationPolicy = "Trusted"
        }
        Register-PSRepository @AzureArtifactsSplat
    }
    By PSGalleryModule AzureArtifacts {
        FromSource ChangelogManagement
        To AzureArtifacts
        WithOptions @{
            ApiKey = $env:AZUREARTIFACTSPAT
        }
        Tagged Dev
    }
}
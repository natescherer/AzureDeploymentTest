Deploy AzureDeploymentTest {
    By Task SetupAzureArtifactsRepo {
        $AzureArtifactsSplat = @{
            Name = "AzureArtifacts"
            SourceLocation = "https://pkgs.dev.azure.com/natescherer/_packaging/AzureDeploymentTest/nuget/v2"
            PublishLocation = "https://pkgs.dev.azure.com/natescherer/_packaging/AzureDeploymentTest/nuget/v2"
            InstallationPolicy = "Trusted"
        }
        Register-PSRepository @AzureArtifactsSplat
    }
    By PSGalleryModule AzureArtifacts {
        FromSource AzureDeploymentTest
        To AzureArtifacts
        WithOptions @{
            ApiKey = $env:AZUREARTIFACTSPAT
        }
        Tagged Dev
    }
}
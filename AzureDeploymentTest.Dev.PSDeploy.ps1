Deploy AzureDeploymentTest {
    By PSGalleryModule AzureArtifacts {
        FromSource .\src
        To AzureArtifacts
        WithOptions @{
            ApiKey = $env:AZUREARTIFACTSPAT
        }
        WithPreScript {
            $AzureArtifactsSplat = @{
                Name               = "AzureArtifacts"
                SourceLocation     = "https://pkgs.dev.azure.com/natescherer/_packaging/NuGetFeed/nuget/v2"
                PublishLocation    = "https://pkgs.dev.azure.com/natescherer/_packaging/NuGetFeed/nuget/v2"
                InstallationPolicy = "Trusted"
            }
            Register-PSRepository @AzureArtifactsSplat            
        }
    }
}
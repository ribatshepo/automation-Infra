# Example: .NET Web API Project

This example shows how to set up CI/CD for a .NET Web API project.

## Project Structure

```
my-dotnet-api/
├── src/
│   ├── MyApi/
│   │   ├── MyApi.csproj
│   │   ├── Program.cs
│   │   └── Controllers/
├── tests/
│   └── MyApi.Tests/
│       └── MyApi.Tests.csproj
├── Dockerfile
├── .github/
│   └── workflows/
│       └── ci-cd.yml
└── README.md
```

## Setup Steps

1. **Run the setup script:**
   ```bash
   /path/to/cicd-templates/setup.sh . --interactive
   # Select option 1 (dotnet)
   ```

2. **Configure GitHub secrets:**
   ```
   HARBOR_REGISTRY=10.100.10.215:8080
   HARBOR_USERNAME=admin
   HARBOR_PASSWORD=Harbor12345!
   HARBOR_PROJECT=library
   
   ARTIFACTORY_URL=http://10.100.10.215:8081
   ARTIFACTORY_USERNAME=admin
   ARTIFACTORY_PASSWORD=Admin123!
   ARTIFACTORY_NUGET_REPO=nuget-local
   ```

3. **Customize the workflow:**
   ```yaml
   # .github/workflows/ci-cd.yml
   name: 'CI/CD Pipeline'
   
   on:
     push:
       branches: [ main, develop ]
     pull_request:
       branches: [ main ]
   
   jobs:
     build-and-deploy:
       uses: ./.github/workflows/dotnet.yml
       with:
         dotnet-version: '8.0.x'
         build-configuration: 'Release'
         target-framework: 'net8.0'
         run-tests: true
         run-integration-tests: true
         security-scan: true
         deploy-package: ${{ github.ref == 'refs/heads/main' }}
         build-docker: true
         environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}
       secrets:
         HARBOR_REGISTRY: ${{ secrets.HARBOR_REGISTRY }}
         HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
         HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
         HARBOR_PROJECT: ${{ secrets.HARBOR_PROJECT }}
         ARTIFACTORY_URL: ${{ secrets.ARTIFACTORY_URL }}
         ARTIFACTORY_USERNAME: ${{ secrets.ARTIFACTORY_USERNAME }}
         ARTIFACTORY_PASSWORD: ${{ secrets.ARTIFACTORY_PASSWORD }}
         ARTIFACTORY_NUGET_REPO: ${{ secrets.ARTIFACTORY_NUGET_REPO }}
   ```

4. **Sample Dockerfile:**
   ```dockerfile
   FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
   WORKDIR /src
   COPY ["src/MyApi/MyApi.csproj", "src/MyApi/"]
   RUN dotnet restore "src/MyApi/MyApi.csproj"
   COPY . .
   WORKDIR "/src/src/MyApi"
   RUN dotnet build "MyApi.csproj" -c Release -o /app/build
   RUN dotnet publish "MyApi.csproj" -c Release -o /app/publish
   
   FROM mcr.microsoft.com/dotnet/aspnet:8.0
   WORKDIR /app
   COPY --from=build /app/publish .
   EXPOSE 8080
   ENTRYPOINT ["dotnet", "MyApi.dll"]
   ```

## What Happens When You Push

1. **Build Phase:**
   - Restore NuGet packages
   - Build the application
   - Run unit tests with coverage
   - Run integration tests

2. **Security Phase:**
   - JFrog Xray scans dependencies
   - Vulnerability report generated

3. **Package Phase:**
   - Creates NuGet package
   - Uploads to Artifactory with build metadata

4. **Docker Phase:**
   - Builds multi-platform Docker image
   - Scans image for vulnerabilities
   - Pushes to Harbor registry

5. **Deploy Phase:**
   - Generates Kubernetes manifests
   - Creates deployment summary

## Expected Output

After a successful run, you'll have:

- **NuGet Package:** `http://10.100.10.215:8081/ui/repos/tree/General/nuget-local/MyApi/1.0.0`
- **Docker Image:** `10.100.10.215:8080/library/myapi:latest`
- **Build Info:** Complete build metadata in Artifactory
- **Security Reports:** Vulnerability scan results
- **Deployment Manifests:** Ready-to-use Kubernetes YAML files

## Customization Options

```yaml
# Custom build configuration
with:
  dotnet-version: '8.0.x'
  build-configuration: 'Release'
  target-framework: 'net8.0'
  run-tests: true
  run-integration-tests: true
  security-scan: true
  
  # Environment-specific settings
  deploy-package: ${{ github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/') }}
  build-docker: true
  environment: ${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}
```

## Testing the Setup

1. **Create a simple API:**
   ```csharp
   // Program.cs
   var builder = WebApplication.CreateBuilder(args);
   builder.Services.AddControllers();
   
   var app = builder.Build();
   app.MapControllers();
   app.Run();
   ```

2. **Add a controller:**
   ```csharp
   [ApiController]
   [Route("[controller]")]
   public class HealthController : ControllerBase
   {
       [HttpGet]
       public IActionResult Get() => Ok(new { Status = "Healthy", Version = "1.0.0" });
   }
   ```

3. **Commit and push:**
   ```bash
   git add .
   git commit -m "Add .NET API with CI/CD pipeline"
   git push
   ```

The CI/CD pipeline will automatically trigger and deploy your application!
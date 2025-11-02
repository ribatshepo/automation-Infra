# .NET Project Template

A minimal, extensible .NET project template with modern tooling and CI/CD integration.

## Features

- **Modern .NET**: Latest .NET 8 with C# 12 features
- **Code Quality**: EditorConfig, StyleCop, and comprehensive analysis
- **Testing**: xUnit, FluentAssertions, and Moq for unit testing
- **Security**: Security analyzers and vulnerability scanning
- **Documentation**: XML documentation and automated API docs
- **CI/CD Integration**: GitHub Actions workflows from cicd-templates
- **Performance**: BenchmarkDotNet for performance testing
- **Extensible**: Easy to customize for web APIs, console apps, or libraries

## Quick Start

### 1. Use This Template
```bash
# Create new repository from template
gh repo create my-dotnet-project --template automation-infra/dotnet-template
cd my-dotnet-project
```

### 2. Initialize Project
```bash
# Run setup script
./scripts/setup.sh

# Build and test
dotnet build
dotnet test
```

### 3. Configure CI/CD
```bash
# Set up GitHub Actions (optional)
./scripts/setup-cicd.sh
```

## Project Structure

```
dotnet-template/
├── README.md                    # This file
├── .gitignore                   # Git ignore patterns
├── .editorconfig               # Editor configuration
├── Directory.Build.props       # MSBuild properties
├── Directory.Packages.props    # Package versions
├── global.json                 # .NET SDK version
├── .github/                    # GitHub workflows
│   └── workflows/
│       └── ci.yml              # Basic CI workflow
├── scripts/                    # Setup and utility scripts
│   ├── setup.sh               # Project initialization
│   ├── setup-cicd.sh          # CI/CD setup
│   ├── test.sh                # Run tests
│   ├── lint.sh                # Run linting
│   ├── format.sh              # Format code
│   ├── security-check.sh      # Security scanning
│   └── build.sh               # Build project
├── src/                        # Source code
│   ├── ProjectName/            # Main library/application
│   │   ├── ProjectName.csproj  # Project file
│   │   ├── Program.cs          # Main entry point
│   │   ├── Models/             # Data models
│   │   ├── Services/           # Business logic
│   │   └── Controllers/        # API controllers (if web)
│   └── ProjectName.Shared/     # Shared library
│       ├── ProjectName.Shared.csproj
│       ├── Extensions/         # Extension methods
│       └── Utilities/          # Utility classes
├── tests/                      # Test projects
│   ├── ProjectName.Tests/      # Unit tests
│   │   ├── ProjectName.Tests.csproj
│   │   └── UnitTests/          # Unit test files
│   └── ProjectName.IntegrationTests/  # Integration tests
│       ├── ProjectName.IntegrationTests.csproj
│       └── IntegrationTests/   # Integration test files
├── benchmarks/                 # Performance benchmarks
│   └── ProjectName.Benchmarks/
│       ├── ProjectName.Benchmarks.csproj
│       └── Benchmarks.cs       # Benchmark definitions
└── docs/                       # Documentation
    ├── api.md
    └── deployment.md
```

## Configuration

### Global Configuration (global.json)
```json
{
  "sdk": {
    "version": "8.0.0",
    "rollForward": "latestMinor"
  },
  "msbuild-sdks": {
    "Microsoft.Build.CentralPackageManagement": "2.1.3"
  }
}
```

### Package Management (Directory.Packages.props)
```xml
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>

  <ItemGroup>
    <PackageVersion Include="Microsoft.Extensions.Hosting" Version="8.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Configuration" Version="8.0.0" />
    <PackageVersion Include="Microsoft.Extensions.Logging" Version="8.0.0" />
    <PackageVersion Include="Serilog.Extensions.Hosting" Version="8.0.0" />
    <PackageVersion Include="Serilog.Sinks.Console" Version="5.0.1" />
    <PackageVersion Include="xunit" Version="2.6.1" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="2.5.3" />
    <PackageVersion Include="FluentAssertions" Version="6.12.0" />
    <PackageVersion Include="Moq" Version="4.20.69" />
    <PackageVersion Include="BenchmarkDotNet" Version="0.13.10" />
  </ItemGroup>
</Project>
```

### Build Properties (Directory.Build.props)
```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <LangVersion>12.0</LangVersion>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <WarningsNotAsErrors />
    <WarningsAsErrors />
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
    <Authors>Your Name</Authors>
    <Company>Your Company</Company>
    <Product>Project Name</Product>
    <Copyright>Copyright © Your Company</Copyright>
    <PackageLicenseExpression>MIT</PackageLicenseExpression>
    <RepositoryUrl>https://github.com/your-org/project-name</RepositoryUrl>
    <RepositoryType>git</RepositoryType>
  </PropertyGroup>

  <PropertyGroup Condition="'$(Configuration)' == 'Release'">
    <Optimize>true</Optimize>
    <DebugType>portable</DebugType>
    <DebugSymbols>true</DebugSymbols>
  </PropertyGroup>

  <PropertyGroup Condition="'$(Configuration)' == 'Debug'">
    <Optimize>false</Optimize>
    <DebugType>full</DebugType>
    <DebugSymbols>true</DebugSymbols>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.CodeAnalysis.Analyzers" Version="3.3.4">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.507">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>
</Project>
```

## Development Workflow

### Setup Development Environment
```bash
# Install .NET SDK
winget install Microsoft.DotNet.SDK.8
# or
sudo apt-get install -y dotnet-sdk-8.0

# Initialize project
./scripts/setup.sh

# Install additional tools
dotnet tool install --global dotnet-format
dotnet tool install --global dotnet-outdated-tool
```

### Daily Development
```bash
# Run development server
dotnet run --project src/ProjectName

# Run tests
dotnet test

# Format code
dotnet format

# Build project
dotnet build

# Run all checks
./scripts/check-all.sh
```

### Package Management
```bash
# Add package reference
dotnet add package PackageName

# Update packages
dotnet outdated --upgrade

# Remove package
dotnet remove package PackageName
```

## Testing

### Test Structure
```csharp
// ProjectName.Tests/UnitTests/ServiceTests.cs
using FluentAssertions;
using Moq;
using Xunit;

namespace ProjectName.Tests.UnitTests;

public class ServiceTests
{
    [Fact]
    public void ProcessData_WithValidInput_ReturnsExpectedResult()
    {
        // Arrange
        var service = new DataService();
        var input = "test input";

        // Act
        var result = service.ProcessData(input);

        // Assert
        result.Should().NotBeNull();
        result.Should().Contain("PROCESSED");
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public void ProcessData_WithInvalidInput_ThrowsArgumentException(string input)
    {
        // Arrange
        var service = new DataService();

        // Act & Assert
        service.Invoking(s => s.ProcessData(input))
            .Should().Throw<ArgumentException>();
    }
}
```

### Test Commands
```bash
# Run all tests
dotnet test

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage"

# Run specific test
dotnet test --filter "ProcessData_WithValidInput"

# Run tests in watch mode
dotnet watch test
```

## CI/CD Integration

This template integrates with the automation-infra CI/CD templates:

### GitHub Actions Workflow
- Uses `cicd-templates/examples/main-dotnet-deploy.yml`
- Automated testing and code analysis
- Security scanning with vulnerability checks
- NuGet package publishing
- Container building and deployment

### Workflow Configuration
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: automation-infra/cicd-templates/.github/workflows/main-dotnet-deploy.yml@main
    with:
      dotnet_version: "8.0.x"
      project_name: "my-dotnet-project"
      run_tests: true
      run_code_analysis: true
      run_security_scan: true
      publish_packages: false
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }}
```

## Customization

### Web API Application
```bash
# Add ASP.NET Core packages
dotnet add package Microsoft.AspNetCore.OpenApi
dotnet add package Swashbuckle.AspNetCore

# Update Program.cs for web API
# Add controllers and middleware
# Update tests for HTTP endpoints
```

### Console Application
```bash
# Add CommandLineParser
dotnet add package CommandLineParser

# Create command definitions
# Add argument parsing
# Update CI/CD for executable distribution
```

### Background Service
```bash
# Add hosting packages
dotnet add package Microsoft.Extensions.Hosting
dotnet add package Microsoft.Extensions.Hosting.WindowsServices

# Add background service implementation
# Configure service lifetime
# Add system service deployment
```

### Entity Framework Integration
```bash
# Add EF Core packages
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Design

# Add DbContext and models
# Configure connection strings
# Add migrations and database tests
```

## Security

### Code Analysis
- StyleCop analyzers for code style
- Security analyzers for vulnerability detection
- .NET analyzers for best practices

### Dependency Scanning
```bash
# Check for vulnerabilities
dotnet list package --vulnerable

# Audit dependencies
dotnet restore --audit
```

### Security Configuration
```bash
# Install security analyzers
dotnet add package Microsoft.CodeAnalysis.BannedApiAnalyzers
dotnet add package SonarAnalyzer.CSharp
```

## Performance

### Benchmarking
```csharp
// ProjectName.Benchmarks/Benchmarks.cs
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;

[MemoryDiagnoser]
[SimpleJob]
public class DataProcessingBenchmarks
{
    private string _testData;

    [GlobalSetup]
    public void Setup()
    {
        _testData = "benchmark test data";
    }

    [Benchmark]
    public string ProcessDataBaseline()
    {
        return _testData.ToUpper();
    }

    [Benchmark]
    public string ProcessDataOptimized()
    {
        return string.Create(_testData.Length, _testData, (chars, data) =>
        {
            data.AsSpan().ToUpperInvariant(chars);
        });
    }
}
```

### Profiling
```bash
# Install profiling tools
dotnet tool install --global dotnet-trace
dotnet tool install --global dotnet-counters

# Profile application
dotnet-trace collect --process-id <PID>
dotnet-counters monitor --process-id <PID>
```

## Deployment Options

### Container Deployment
```dockerfile
# Multi-stage build for .NET application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /source

# Copy project files
COPY *.sln .
COPY src/ src/
COPY tests/ tests/

# Restore dependencies
RUN dotnet restore

# Build application
RUN dotnet publish src/ProjectName/ProjectName.csproj \
    -c Release \
    -o /app \
    --no-restore

# Production stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Create non-root user
RUN adduser --disabled-password --gecos '' --uid 1000 appuser
USER appuser

# Copy application from build stage
COPY --from=build --chown=appuser:appuser /app .

EXPOSE 8080
ENTRYPOINT ["dotnet", "ProjectName.dll"]
```

### Azure Deployment
- Azure App Service deployment
- Azure Container Instances
- Azure Kubernetes Service
- Azure Functions (for serverless)

## Best Practices

### Code Organization
- Use proper namespace organization
- Implement dependency injection
- Follow SOLID principles
- Use async/await properly

### Error Handling
- Use structured exception handling
- Implement proper logging
- Create custom exception types
- Use Result patterns for operations

### Performance
- Use Span<T> and Memory<T> for memory efficiency
- Implement proper caching strategies
- Use async enumerable for streaming data
- Profile and benchmark critical paths

### Testing
- Follow AAA pattern (Arrange, Act, Assert)
- Use FluentAssertions for readable assertions
- Mock external dependencies
- Test both success and failure scenarios

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run all checks: `./scripts/check-all.sh`
5. Submit a pull request

## Support

- Documentation: [Project Docs](docs/)
- CI/CD Templates: [cicd-templates](../cicd-templates/)
- Issues: [GitHub Issues](https://github.com/your-org/project/issues)
- Discussions: [GitHub Discussions](https://github.com/your-org/project/discussions)
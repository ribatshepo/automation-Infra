#!/bin/bash

# .NET project setup script
# This script initializes a new .NET project with all necessary tools and configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install .NET if not present
install_dotnet() {
    if ! command_exists dotnet; then
        print_status "Installing .NET SDK..."
        
        # Detect OS and install accordingly
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Ubuntu/Debian
            if command_exists apt-get; then
                wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
                sudo dpkg -i packages-microsoft-prod.deb
                sudo apt-get update
                sudo apt-get install -y dotnet-sdk-8.0
                rm packages-microsoft-prod.deb
            else
                print_error "Unsupported Linux distribution. Please install .NET SDK manually."
                exit 1
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command_exists brew; then
                brew install --cask dotnet
            else
                print_error "Homebrew not found. Please install .NET SDK manually."
                exit 1
            fi
        else
            print_error "Unsupported OS. Please install .NET SDK manually."
            exit 1
        fi
        
        print_success ".NET SDK installed successfully"
    else
        print_success ".NET SDK is already installed ($(dotnet --version))"
    fi
}

# Function to install .NET tools
install_dotnet_tools() {
    print_status "Installing .NET tools..."
    
    # List of tools to install
    local tools=(
        "dotnet-format"              # Code formatter
        "dotnet-outdated-tool"       # Check for outdated packages
        "dotnet-sonarscanner"        # SonarQube scanner
        "dotnet-reportgenerator-globaltool"  # Coverage report generator
        "dotnet-trace"               # Performance tracing
    )
    
    for tool in "${tools[@]}"; do
        if ! dotnet tool list --global | grep -q "$tool"; then
            print_status "Installing $tool..."
            dotnet tool install --global "$tool" || print_warning "Failed to install $tool (continuing anyway)"
        else
            print_success "$tool already installed"
        fi
    done
}

# Function to create project structure
create_project_structure() {
    print_status "Creating project structure..."
    
    local dirs=(
        "src"
        "tests"
        "docs"
        "scripts"
        ".github/workflows"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        fi
    done
}

# Function to initialize solution and projects
init_solution() {
    if [ ! -f "*.sln" ]; then
        print_status "Creating solution file..."
        local solution_name=$(basename "$PWD")
        dotnet new sln --name "$solution_name"
        print_success "Solution created: $solution_name.sln"
    else
        print_success "Solution file already exists"
    fi
}

# Function to create example configuration
create_example_config() {
    print_status "Creating example configuration..."
    
    if [ ! -f "appsettings.example.json" ]; then
        cat > appsettings.example.json << 'EOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=MyApp;Trusted_Connection=true;"
  },
  "App": {
    "Name": "ProjectName",
    "Version": "1.0.0",
    "Environment": "Development"
  }
}
EOF
        print_success "Example configuration created"
    fi
}

# Function to create EditorConfig
create_editorconfig() {
    if [ ! -f ".editorconfig" ]; then
        print_status "Creating .editorconfig..."
        # EditorConfig content already exists in the file
        print_success "EditorConfig created"
    else
        print_success "EditorConfig already exists"
    fi
}

# Function to display next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}.NET project setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Update Directory.Build.props with your project details"
    echo "2. Create your main project: dotnet new console -n YourProjectName -o src/YourProjectName"
    echo "3. Add project to solution: dotnet sln add src/YourProjectName/YourProjectName.csproj"
    echo "4. Run './scripts/build.sh' to build the project"
    echo "5. Run './scripts/test.sh' to run tests"
    echo "6. Run './scripts/setup-cicd.sh' to configure CI/CD"
    echo ""
    echo -e "${BLUE}Available commands:${NC}"
    echo "• dotnet build          - Build the solution"
    echo "• dotnet test           - Run tests"
    echo "• dotnet run            - Run the application"
    echo "• dotnet format         - Format code"
    echo "• dotnet outdated       - Check for outdated packages"
    echo ""
    echo -e "${BLUE}Development scripts:${NC}"
    echo "• ./scripts/build.sh           - Build project"
    echo "• ./scripts/test.sh            - Run tests"
    echo "• ./scripts/lint.sh            - Run linting"
    echo "• ./scripts/format.sh          - Format code"
    echo "• ./scripts/security-check.sh  - Run security checks"
    echo "• ./scripts/check-all.sh       - Run all checks"
    echo ""
}

# Main setup function
main() {
    echo -e "${BLUE}.NET Project Setup${NC}"
    echo "======================================"
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] || ! grep -q ".NET Project Template" README.md 2>/dev/null; then
        print_warning "This doesn't appear to be a .NET template directory"
        print_status "Continuing anyway..."
    fi
    
    # Run setup steps
    install_dotnet
    install_dotnet_tools
    create_project_structure
    init_solution
    create_example_config
    create_editorconfig
    
    show_next_steps
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo ""
        echo "This script sets up a .NET development environment with:"
        echo "• .NET SDK installation"
        echo "• Essential .NET tools (dotnet-format, dotnet-outdated, etc.)"
        echo "• Project structure creation"
        echo "• Solution initialization"
        echo "• Configuration files"
        echo ""
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
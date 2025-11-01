#!/bin/bash

# Rust project setup script
# This script initializes a new Rust project with all necessary tools and configurations

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

# Function to install Rust if not present
install_rust() {
    if ! command_exists rustc; then
        print_status "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
        print_success "Rust installed successfully"
    else
        print_success "Rust is already installed ($(rustc --version))"
    fi
}

# Function to install Rust components
install_rust_components() {
    print_status "Installing Rust components..."
    
    # Install rustfmt for code formatting
    if ! rustup component list --installed | grep -q rustfmt; then
        rustup component add rustfmt
        print_success "rustfmt installed"
    else
        print_success "rustfmt already installed"
    fi
    
    # Install clippy for linting
    if ! rustup component list --installed | grep -q clippy; then
        rustup component add clippy
        print_success "clippy installed"
    else
        print_success "clippy already installed"
    fi
}

# Function to install additional Rust tools
install_rust_tools() {
    print_status "Installing additional Rust tools..."
    
    # List of tools to install
    local tools=(
        "cargo-audit"     # Security vulnerability scanner
        "cargo-outdated"  # Check for outdated dependencies
        "cargo-tarpaulin" # Code coverage tool
        "cargo-watch"     # Watch for changes and rebuild
        "cargo-expand"    # Show macro expansions
        "cargo-edit"      # Cargo subcommands for editing Cargo.toml
    )
    
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            print_status "Installing $tool..."
            cargo install "$tool" || print_warning "Failed to install $tool (continuing anyway)"
        else
            print_success "$tool already installed"
        fi
    done
}

# Function to initialize cargo project if needed
init_cargo_project() {
    if [ ! -f "Cargo.toml" ]; then
        print_status "Initializing Cargo project..."
        cargo init --name "$(basename "$PWD")" .
        print_success "Cargo project initialized"
    else
        print_success "Cargo.toml already exists"
    fi
}

# Function to create project directories
create_directories() {
    print_status "Creating project directories..."
    
    local dirs=(
        "src/bin"
        "tests/common"
        "benches"
        "examples"
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

# Function to set up git hooks
setup_git_hooks() {
    if [ -d ".git" ]; then
        print_status "Setting up git hooks..."
        
        # Create pre-commit hook
        cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for Rust projects

set -e

echo "Running pre-commit checks..."

# Run cargo fmt check
if ! cargo fmt -- --check; then
    echo "Code formatting issues found. Run 'cargo fmt' to fix them."
    exit 1
fi

# Run clippy
if ! cargo clippy -- -D warnings; then
    echo "Clippy found issues. Please fix them before committing."
    exit 1
fi

# Run tests
if ! cargo test; then
    echo "Tests failed. Please fix them before committing."
    exit 1
fi

echo "Pre-commit checks passed!"
EOF
        
        chmod +x .git/hooks/pre-commit
        print_success "Git pre-commit hook installed"
    else
        print_warning "Not a git repository, skipping git hooks setup"
    fi
}

# Function to create development scripts
create_dev_scripts() {
    print_status "Creating development scripts..."
    
    # Make scripts executable
    find scripts -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
    
    print_success "Development scripts are ready"
}

# Function to run initial build and tests
initial_build() {
    print_status "Running initial build and tests..."
    
    # Update dependencies
    cargo update
    
    # Build the project
    if cargo build; then
        print_success "Project built successfully"
    else
        print_error "Build failed"
        return 1
    fi
    
    # Run tests
    if cargo test; then
        print_success "Tests passed"
    else
        print_warning "Some tests failed"
    fi
    
    # Run clippy
    if cargo clippy -- -D warnings; then
        print_success "Clippy checks passed"
    else
        print_warning "Clippy found some issues"
    fi
    
    # Format code
    cargo fmt
    print_success "Code formatted"
}

# Function to create example configuration
create_example_config() {
    print_status "Creating example configuration..."
    
    if [ ! -f "config.example.json" ]; then
        cat > config.example.json << 'EOF'
{
  "server": {
    "host": "127.0.0.1",
    "port": 8080,
    "max_connections": 1000,
    "timeout": 30,
    "tls_enabled": false
  },
  "database": {
    "url": "postgresql://localhost/myapp",
    "max_connections": 10,
    "timeout": 30,
    "pool_enabled": true
  },
  "logging": {
    "level": "info",
    "format": "pretty",
    "console_enabled": true,
    "structured": false
  },
  "security": {
    "jwt_secret": "your-secret-key-change-this-in-production",
    "jwt_expiration": 24,
    "rate_limiting_enabled": true,
    "rate_limit_rpm": 100,
    "cors_enabled": true,
    "cors_origins": ["http://localhost:3000"]
  }
}
EOF
        print_success "Example configuration created"
    fi
}

# Function to display next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}🎉 Rust project setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Update Cargo.toml with your project details"
    echo "2. Configure your application in config.example.json"
    echo "3. Run './scripts/test.sh' to run tests"
    echo "4. Run './scripts/lint.sh' to check code quality"
    echo "5. Run 'cargo run --bin server' to start the server"
    echo "6. Run './scripts/setup-cicd.sh' to configure CI/CD"
    echo ""
    echo -e "${BLUE}Available commands:${NC}"
    echo "• cargo build          - Build the project"
    echo "• cargo test           - Run tests"
    echo "• cargo run            - Run the default binary"
    echo "• cargo fmt            - Format code"
    echo "• cargo clippy         - Run lints"
    echo "• cargo audit          - Check for security vulnerabilities"
    echo "• cargo watch -x test  - Watch for changes and run tests"
    echo ""
    echo -e "${BLUE}Development scripts:${NC}"
    echo "• ./scripts/test.sh           - Run all tests"
    echo "• ./scripts/lint.sh           - Run linting"
    echo "• ./scripts/format.sh         - Format code"
    echo "• ./scripts/security-check.sh - Run security checks"
    echo "• ./scripts/build.sh          - Build project"
    echo "• ./scripts/check-all.sh      - Run all checks"
    echo ""
}

# Main setup function
main() {
    echo -e "${BLUE}🦀 Rust Project Setup${NC}"
    echo "======================================"
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] || ! grep -q "Rust Project Template" README.md 2>/dev/null; then
        print_warning "This doesn't appear to be a Rust template directory"
        print_status "Continuing anyway..."
    fi
    
    # Run setup steps
    install_rust
    install_rust_components
    install_rust_tools
    init_cargo_project
    create_directories
    setup_git_hooks
    create_dev_scripts
    create_example_config
    initial_build
    
    show_next_steps
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo ""
        echo "This script sets up a Rust development environment with:"
        echo "• Rust toolchain installation"
        echo "• Essential Rust tools (clippy, rustfmt, cargo-audit, etc.)"
        echo "• Project structure creation"
        echo "• Git hooks for code quality"
        echo "• Development scripts"
        echo "• Initial build and test run"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
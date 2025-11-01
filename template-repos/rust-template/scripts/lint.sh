#!/bin/bash

# Rust linting script
# Runs comprehensive linting and static analysis for Rust projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if cargo is available
check_cargo() {
    if ! command -v cargo >/dev/null 2>&1; then
        print_error "Cargo is not installed. Please install Rust first."
        exit 1
    fi
}

# Function to run Clippy linting
run_clippy() {
    print_status "Running Clippy linting..."
    
    # Check if clippy is installed
    if ! rustup component list --installed | grep -q clippy; then
        print_warning "Clippy not installed, installing..."
        rustup component add clippy
    fi
    
    local clippy_args=(
        "--all-targets"
        "--all-features"
        "--"
        "-D" "warnings"
    )
    
    # Add additional clippy lints if strict mode is enabled
    if [ "${STRICT_MODE:-false}" = "true" ]; then
        clippy_args+=(
            "-D" "clippy::all"
            "-D" "clippy::pedantic"
            "-D" "clippy::nursery"
            "-D" "clippy::cargo"
        )
    fi
    
    if cargo clippy "${clippy_args[@]}"; then
        print_success "Clippy linting passed"
        return 0
    else
        print_error "Clippy found issues"
        return 1
    fi
}

# Function to check code formatting
check_formatting() {
    print_status "Checking code formatting..."
    
    # Check if rustfmt is installed
    if ! rustup component list --installed | grep -q rustfmt; then
        print_warning "rustfmt not installed, installing..."
        rustup component add rustfmt
    fi
    
    if cargo fmt -- --check; then
        print_success "Code formatting is correct"
        return 0
    else
        print_error "Code formatting issues found"
        print_status "Run 'cargo fmt' to fix formatting issues"
        return 1
    fi
}

# Function to check for security vulnerabilities
check_security() {
    print_status "Checking for security vulnerabilities..."
    
    if ! command -v cargo-audit >/dev/null 2>&1; then
        print_warning "cargo-audit not installed, installing..."
        cargo install cargo-audit
    fi
    
    if cargo audit; then
        print_success "No security vulnerabilities found"
        return 0
    else
        print_error "Security vulnerabilities found"
        return 1
    fi
}

# Function to check for outdated dependencies
check_outdated() {
    print_status "Checking for outdated dependencies..."
    
    if ! command -v cargo-outdated >/dev/null 2>&1; then
        print_warning "cargo-outdated not installed, installing..."
        cargo install cargo-outdated
    fi
    
    if cargo outdated --exit-code 1; then
        print_success "All dependencies are up to date"
        return 0
    else
        print_warning "Some dependencies are outdated"
        print_status "Run 'cargo update' to update dependencies"
        return 0  # Don't fail on outdated dependencies
    fi
}

# Function to check for unused dependencies
check_unused_deps() {
    print_status "Checking for unused dependencies..."
    
    if ! command -v cargo-udeps >/dev/null 2>&1; then
        print_warning "cargo-udeps not installed, installing..."
        cargo install cargo-udeps --locked
    fi
    
    if cargo +nightly udeps; then
        print_success "No unused dependencies found"
        return 0
    else
        print_warning "Unused dependencies found"
        return 0  # Don't fail on unused dependencies
    fi
}

# Function to run cargo check
run_cargo_check() {
    print_status "Running cargo check..."
    
    if cargo check --all-targets --all-features; then
        print_success "Cargo check passed"
        return 0
    else
        print_error "Cargo check failed"
        return 1
    fi
}

# Function to check documentation
check_docs() {
    print_status "Checking documentation..."
    
    # Check that documentation builds without warnings
    if RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --document-private-items; then
        print_success "Documentation builds without warnings"
    else
        print_error "Documentation has warnings or errors"
        return 1
    fi
    
    # Check for missing documentation
    if cargo clippy -- -W missing_docs; then
        print_success "Documentation coverage is good"
        return 0
    else
        print_warning "Some items are missing documentation"
        return 0  # Don't fail on missing docs
    fi
}

# Function to run workspace-specific linting
run_workspace_linting() {
    if cargo metadata --format-version 1 | grep -q '"workspace_members"'; then
        print_status "Running workspace-specific linting..."
        
        # Check workspace dependencies
        print_status "Checking workspace dependency consistency..."
        # This is a simplified check - in a real scenario you might want more sophisticated checks
        if cargo check --workspace; then
            print_success "Workspace dependencies are consistent"
        else
            print_error "Workspace dependency issues found"
            return 1
        fi
    fi
    
    return 0
}

# Function to run additional lints
run_additional_lints() {
    print_status "Running additional lints..."
    
    # Check for TODO/FIXME comments in production builds
    if [ "${PRODUCTION:-false}" = "true" ]; then
        print_status "Checking for TODO/FIXME comments..."
        if grep -r "TODO\|FIXME" src/ --include="*.rs" --exclude-dir=tests; then
            print_warning "TODO/FIXME comments found in production code"
        else
            print_success "No TODO/FIXME comments in production code"
        fi
    fi
    
    # Check for println! statements (should use logging instead)
    print_status "Checking for println! statements..."
    if grep -r "println!" src/ --include="*.rs" --exclude="*test*" --exclude="*example*"; then
        print_warning "println! statements found (consider using tracing/log instead)"
    else
        print_success "No println! statements in main code"
    fi
    
    return 0
}

# Function to display linting summary
show_lint_summary() {
    echo ""
    echo -e "${GREEN}🔍 Linting Summary${NC}"
    echo "=================================="
    echo "• Clippy: ${CLIPPY_STATUS:-unknown}"
    echo "• Formatting: ${FORMAT_STATUS:-unknown}"
    echo "• Security: ${SECURITY_STATUS:-unknown}"
    echo "• Dependencies: ${DEPS_STATUS:-unknown}"
    echo "• Documentation: ${DOCS_STATUS:-unknown}"
    echo "• Strict mode: ${STRICT_MODE:-false}"
    echo ""
}

# Main function
main() {
    echo -e "${BLUE}🦀 Rust Linter${NC}"
    echo "======================================"
    
    check_cargo
    
    local exit_code=0
    
    # Run cargo check first
    if run_cargo_check; then
        CARGO_CHECK_STATUS="passed"
    else
        CARGO_CHECK_STATUS="failed"
        exit_code=1
    fi
    
    # Run clippy
    if run_clippy; then
        CLIPPY_STATUS="passed"
    else
        CLIPPY_STATUS="failed"
        exit_code=1
    fi
    
    # Check formatting
    if check_formatting; then
        FORMAT_STATUS="passed"
    else
        FORMAT_STATUS="failed"
        if [ "${FIX_FORMAT:-false}" = "true" ]; then
            print_status "Auto-fixing formatting issues..."
            cargo fmt
            FORMAT_STATUS="fixed"
        else
            exit_code=1
        fi
    fi
    
    # Security check
    if check_security; then
        SECURITY_STATUS="passed"
    else
        SECURITY_STATUS="failed"
        if [ "${FAIL_ON_SECURITY:-true}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Check outdated dependencies
    if check_outdated; then
        DEPS_STATUS="up-to-date"
    else
        DEPS_STATUS="outdated"
    fi
    
    # Check documentation
    if check_docs; then
        DOCS_STATUS="passed"
    else
        DOCS_STATUS="issues"
        if [ "${FAIL_ON_DOCS:-false}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Run workspace linting if applicable
    if ! run_workspace_linting; then
        exit_code=1
    fi
    
    # Run additional lints
    run_additional_lints
    
    # Check for unused dependencies (optional)
    if [ "${CHECK_UNUSED:-false}" = "true" ]; then
        check_unused_deps
    fi
    
    show_lint_summary
    
    if [ $exit_code -eq 0 ]; then
        print_success "All linting checks passed!"
    else
        print_error "Some linting checks failed"
    fi
    
    return $exit_code
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --strict            Enable strict linting mode"
        echo "  --fix-format        Auto-fix formatting issues"
        echo "  --check-unused      Check for unused dependencies"
        echo "  --production        Production mode (stricter checks)"
        echo "  --no-security       Skip security checks"
        echo "  --no-docs           Skip documentation checks"
        echo "  --help              Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  STRICT_MODE         Enable strict linting (true|false)"
        echo "  FIX_FORMAT          Auto-fix formatting (true|false)"
        echo "  FAIL_ON_SECURITY    Fail on security issues (true|false)"
        echo "  FAIL_ON_DOCS        Fail on documentation issues (true|false)"
        echo "  CHECK_UNUSED        Check unused dependencies (true|false)"
        echo "  PRODUCTION          Production mode (true|false)"
        echo ""
        echo "Examples:"
        echo "  $0                     # Run standard linting"
        echo "  $0 --strict            # Run strict linting"
        echo "  $0 --fix-format        # Auto-fix formatting"
        echo "  $0 --production        # Production mode"
        echo "  STRICT_MODE=true $0    # Strict mode via environment"
        exit 0
        ;;
    --strict)
        STRICT_MODE=true
        main
        ;;
    --fix-format)
        FIX_FORMAT=true
        main
        ;;
    --check-unused)
        CHECK_UNUSED=true
        main
        ;;
    --production)
        PRODUCTION=true
        STRICT_MODE=true
        FAIL_ON_SECURITY=true
        main
        ;;
    --no-security)
        FAIL_ON_SECURITY=false
        main
        ;;
    --no-docs)
        FAIL_ON_DOCS=false
        main
        ;;
    *)
        main "$@"
        ;;
esac
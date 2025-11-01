#!/bin/bash

# Comprehensive check script for Rust projects
# Runs all quality assurance checks

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

# Check if script exists and is executable
check_script() {
    local script="$1"
    if [ -x "scripts/$script" ]; then
        return 0
    else
        print_warning "Script not found or not executable: scripts/$script"
        return 1
    fi
}

# Main function
main() {
    echo -e "${BLUE}🦀 Rust Comprehensive Checker${NC}"
    echo "======================================"
    
    local exit_code=0
    local checks_run=0
    local checks_passed=0
    
    # 1. Build check
    if check_script "build.sh"; then
        print_status "Running build check..."
        if ./scripts/build.sh; then
            print_success "✓ Build check passed"
            checks_passed=$((checks_passed + 1))
        else
            print_error "✗ Build check failed"
            exit_code=1
        fi
        checks_run=$((checks_run + 1))
    fi
    
    # 2. Test check
    if check_script "test.sh"; then
        print_status "Running test check..."
        if ./scripts/test.sh; then
            print_success "✓ Test check passed"
            checks_passed=$((checks_passed + 1))
        else
            print_error "✗ Test check failed"
            exit_code=1
        fi
        checks_run=$((checks_run + 1))
    fi
    
    # 3. Lint check
    if check_script "lint.sh"; then
        print_status "Running lint check..."
        if ./scripts/lint.sh; then
            print_success "✓ Lint check passed"
            checks_passed=$((checks_passed + 1))
        else
            print_error "✗ Lint check failed"
            exit_code=1
        fi
        checks_run=$((checks_run + 1))
    fi
    
    # 4. Format check
    if check_script "format.sh"; then
        print_status "Running format check..."
        if ./scripts/format.sh --check; then
            print_success "✓ Format check passed"
            checks_passed=$((checks_passed + 1))
        else
            print_error "✗ Format check failed"
            exit_code=1
        fi
        checks_run=$((checks_run + 1))
    fi
    
    # 5. Security check
    if check_script "security-check.sh"; then
        print_status "Running security check..."
        if ./scripts/security-check.sh; then
            print_success "✓ Security check passed"
            checks_passed=$((checks_passed + 1))
        else
            print_error "✗ Security check failed"
            exit_code=1
        fi
        checks_run=$((checks_run + 1))
    fi
    
    echo ""
    echo -e "${GREEN}📊 Summary${NC}"
    echo "=================================="
    echo "• Checks run: $checks_run"
    echo "• Checks passed: $checks_passed"
    echo "• Checks failed: $((checks_run - checks_passed))"
    echo ""
    
    if [ $exit_code -eq 0 ]; then
        print_success "🎉 All checks passed!"
    else
        print_error "❌ Some checks failed"
    fi
    
    return $exit_code
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo ""
        echo "This script runs all quality assurance checks:"
        echo "• Build check (compilation)"
        echo "• Test check (unit and integration tests)"
        echo "• Lint check (clippy and other lints)"
        echo "• Format check (rustfmt)"
        echo "• Security check (vulnerability scanning)"
        echo ""
        echo "All checks must pass for the script to succeed."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
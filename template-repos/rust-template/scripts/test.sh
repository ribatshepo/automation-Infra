#!/bin/bash

# Rust testing script
# Runs comprehensive tests for Rust projects

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

# Function to run unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    
    if cargo test --lib; then
        print_success "Unit tests passed"
        return 0
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    if cargo test --test '*'; then
        print_success "Integration tests passed"
        return 0
    else
        print_error "Integration tests failed"
        return 1
    fi
}

# Function to run doc tests
run_doc_tests() {
    print_status "Running documentation tests..."
    
    if cargo test --doc; then
        print_success "Documentation tests passed"
        return 0
    else
        print_error "Documentation tests failed"
        return 1
    fi
}

# Function to run benchmark tests
run_benchmarks() {
    print_status "Running benchmarks..."
    
    if cargo bench --no-run; then
        print_success "Benchmarks compiled successfully"
        
        if [ "${RUN_BENCHMARKS:-false}" = "true" ]; then
            print_status "Executing benchmarks..."
            cargo bench
            print_success "Benchmarks completed"
        else
            print_status "Skipping benchmark execution (set RUN_BENCHMARKS=true to run)"
        fi
        return 0
    else
        print_error "Benchmarks failed to compile"
        return 1
    fi
}

# Function to run tests with coverage
run_coverage() {
    print_status "Running tests with coverage..."
    
    if command -v cargo-tarpaulin >/dev/null 2>&1; then
        if cargo tarpaulin --out Html --out Xml; then
            print_success "Coverage report generated"
            
            # Show coverage summary
            if [ -f "tarpaulin-report.html" ]; then
                print_status "HTML coverage report: tarpaulin-report.html"
            fi
            
            if [ -f "cobertura.xml" ]; then
                print_status "XML coverage report: cobertura.xml"
            fi
            
            return 0
        else
            print_error "Coverage generation failed"
            return 1
        fi
    else
        print_warning "cargo-tarpaulin not installed, skipping coverage"
        print_status "Install with: cargo install cargo-tarpaulin"
        return 0
    fi
}

# Function to run specific test
run_specific_test() {
    local test_name="$1"
    print_status "Running specific test: $test_name"
    
    if cargo test "$test_name" -- --nocapture; then
        print_success "Test '$test_name' passed"
        return 0
    else
        print_error "Test '$test_name' failed"
        return 1
    fi
}

# Function to run tests with different profiles
run_tests_with_profiles() {
    print_status "Running tests with different profiles..."
    
    # Debug profile (default)
    print_status "Testing debug profile..."
    if cargo test; then
        print_success "Debug profile tests passed"
    else
        print_error "Debug profile tests failed"
        return 1
    fi
    
    # Release profile
    print_status "Testing release profile..."
    if cargo test --release; then
        print_success "Release profile tests passed"
    else
        print_error "Release profile tests failed"
        return 1
    fi
    
    return 0
}

# Function to run tests for specific packages in workspace
run_workspace_tests() {
    if cargo metadata --format-version 1 | grep -q '"workspace_members"'; then
        print_status "Running tests for all workspace members..."
        
        if cargo test --workspace; then
            print_success "Workspace tests passed"
            return 0
        else
            print_error "Workspace tests failed"
            return 1
        fi
    else
        print_status "Not a workspace, running single package tests"
        run_unit_tests
    fi
}

# Function to clean test artifacts
clean_test_artifacts() {
    print_status "Cleaning test artifacts..."
    
    # Remove coverage reports
    rm -f tarpaulin-report.html cobertura.xml lcov.info
    
    # Clean cargo test cache
    cargo clean --doc
    
    print_success "Test artifacts cleaned"
}

# Function to display test summary
show_test_summary() {
    echo ""
    echo -e "${GREEN}🧪 Test Summary${NC}"
    echo "=================================="
    
    # Get test count
    local test_count
    test_count=$(cargo test --dry-run 2>&1 | grep -c "test " || echo "unknown")
    
    echo "• Tests discovered: $test_count"
    echo "• Test mode: ${TEST_MODE:-comprehensive}"
    echo "• Coverage: ${COVERAGE:-false}"
    echo "• Benchmarks: ${RUN_BENCHMARKS:-false}"
    echo ""
    
    if [ -f "tarpaulin-report.html" ]; then
        echo "📊 Coverage report: tarpaulin-report.html"
    fi
    
    if [ -f "target/criterion" ]; then
        echo "📈 Benchmark results: target/criterion/"
    fi
}

# Main function
main() {
    echo -e "${BLUE}🦀 Rust Test Runner${NC}"
    echo "======================================"
    
    check_cargo
    
    local exit_code=0
    
    case "${TEST_MODE:-comprehensive}" in
        unit)
            run_unit_tests || exit_code=1
            ;;
        integration)
            run_integration_tests || exit_code=1
            ;;
        doc)
            run_doc_tests || exit_code=1
            ;;
        benchmark)
            run_benchmarks || exit_code=1
            ;;
        coverage)
            COVERAGE=true
            run_unit_tests || exit_code=1
            run_integration_tests || exit_code=1
            run_coverage || exit_code=1
            ;;
        profiles)
            run_tests_with_profiles || exit_code=1
            ;;
        workspace)
            run_workspace_tests || exit_code=1
            ;;
        comprehensive|*)
            # Run all tests
            run_unit_tests || exit_code=1
            run_integration_tests || exit_code=1
            run_doc_tests || exit_code=1
            run_benchmarks || exit_code=1
            
            if [ "${COVERAGE:-false}" = "true" ]; then
                run_coverage || exit_code=1
            fi
            ;;
    esac
    
    show_test_summary
    
    if [ $exit_code -eq 0 ]; then
        print_success "All tests completed successfully!"
    else
        print_error "Some tests failed"
    fi
    
    return $exit_code
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --unit              Run unit tests only"
        echo "  --integration       Run integration tests only"
        echo "  --doc               Run documentation tests only"
        echo "  --benchmark         Run benchmarks only"
        echo "  --coverage          Run tests with coverage"
        echo "  --profiles          Run tests with different profiles"
        echo "  --workspace         Run workspace tests"
        echo "  --clean             Clean test artifacts"
        echo "  --specific TEST     Run specific test"
        echo "  --help              Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  TEST_MODE           Set test mode (unit|integration|doc|benchmark|coverage|profiles|workspace|comprehensive)"
        echo "  COVERAGE            Enable coverage reporting (true|false)"
        echo "  RUN_BENCHMARKS      Execute benchmarks (true|false)"
        echo ""
        echo "Examples:"
        echo "  $0                          # Run comprehensive tests"
        echo "  $0 --unit                   # Run unit tests only"
        echo "  $0 --coverage               # Run tests with coverage"
        echo "  $0 --specific my_test       # Run specific test"
        echo "  TEST_MODE=unit $0           # Run unit tests via environment"
        echo "  COVERAGE=true $0            # Enable coverage via environment"
        exit 0
        ;;
    --unit)
        TEST_MODE=unit
        main
        ;;
    --integration)
        TEST_MODE=integration
        main
        ;;
    --doc)
        TEST_MODE=doc
        main
        ;;
    --benchmark)
        TEST_MODE=benchmark
        RUN_BENCHMARKS=true
        main
        ;;
    --coverage)
        TEST_MODE=coverage
        COVERAGE=true
        main
        ;;
    --profiles)
        TEST_MODE=profiles
        main
        ;;
    --workspace)
        TEST_MODE=workspace
        main
        ;;
    --clean)
        clean_test_artifacts
        ;;
    --specific)
        if [ -z "${2:-}" ]; then
            print_error "Please specify a test name"
            exit 1
        fi
        run_specific_test "$2"
        ;;
    *)
        main "$@"
        ;;
esac
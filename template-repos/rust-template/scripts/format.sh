#!/bin/bash

# Rust code formatting script
# Formats Rust code using rustfmt and other formatting tools

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

# Function to install rustfmt if not present
install_rustfmt() {
    if ! rustup component list --installed | grep -q rustfmt; then
        print_status "Installing rustfmt..."
        rustup component add rustfmt
        print_success "rustfmt installed"
    fi
}

# Function to format Rust code
format_rust_code() {
    print_status "Formatting Rust code with rustfmt..."
    
    local rustfmt_args=()
    
    # Add verbose output if requested
    if [ "${VERBOSE:-false}" = "true" ]; then
        rustfmt_args+=("--verbose")
    fi
    
    # Add check mode if requested
    if [ "${CHECK_ONLY:-false}" = "true" ]; then
        rustfmt_args+=("--check")
        print_status "Running in check mode (no changes will be made)"
    fi
    
    if cargo fmt "${rustfmt_args[@]}"; then
        if [ "${CHECK_ONLY:-false}" = "true" ]; then
            print_success "Code formatting is already correct"
        else
            print_success "Code formatted successfully"
        fi
        return 0
    else
        if [ "${CHECK_ONLY:-false}" = "true" ]; then
            print_error "Code formatting issues found"
            print_status "Run without --check to fix formatting"
        else
            print_error "Failed to format code"
        fi
        return 1
    fi
}

# Function to format Cargo.toml
format_cargo_toml() {
    print_status "Formatting Cargo.toml..."
    
    if command -v cargo-sort >/dev/null 2>&1; then
        if cargo sort; then
            print_success "Cargo.toml formatted"
        else
            print_warning "Failed to format Cargo.toml"
        fi
    else
        print_warning "cargo-sort not installed, skipping Cargo.toml formatting"
        print_status "Install with: cargo install cargo-sort"
    fi
}

# Function to format imports
format_imports() {
    if [ "${FORMAT_IMPORTS:-false}" = "true" ]; then
        print_status "Organizing imports..."
        
        # This would require additional tooling
        # For now, we'll rely on rustfmt's import organizing
        print_status "Import organization is handled by rustfmt"
    fi
}

# Function to check formatting configuration
check_formatting_config() {
    print_status "Checking formatting configuration..."
    
    if [ -f ".rustfmt.toml" ]; then
        print_success "Found .rustfmt.toml configuration"
        
        if [ "${VERBOSE:-false}" = "true" ]; then
            print_status "Current rustfmt configuration:"
            cat .rustfmt.toml | head -10
            if [ $(wc -l < .rustfmt.toml) -gt 10 ]; then
                echo "... (truncated)"
            fi
        fi
    else
        print_warning "No .rustfmt.toml found, using default configuration"
        
        if [ "${CREATE_CONFIG:-false}" = "true" ]; then
            print_status "Creating default .rustfmt.toml..."
            create_default_rustfmt_config
        fi
    fi
}

# Function to create default rustfmt configuration
create_default_rustfmt_config() {
    cat > .rustfmt.toml << 'EOF'
edition = "2021"
max_width = 100
hard_tabs = false
tab_spaces = 4
newline_style = "Unix"
use_small_heuristics = "Default"
reorder_imports = true
reorder_modules = true
remove_nested_parens = true
merge_derives = true
use_try_shorthand = false
use_field_init_shorthand = false
force_explicit_abi = true
empty_item_single_line = true
struct_lit_single_line = true
fn_single_line = false
where_single_line = false
imports_layout = "Mixed"
merge_imports = false
group_imports = "StdExternalCrate"
EOF
    print_success "Created default .rustfmt.toml"
}

# Function to format specific files
format_specific_files() {
    if [ ${#SPECIFIC_FILES[@]} -gt 0 ]; then
        print_status "Formatting specific files..."
        
        for file in "${SPECIFIC_FILES[@]}"; do
            if [ -f "$file" ]; then
                print_status "Formatting $file..."
                if rustfmt "$file"; then
                    print_success "Formatted $file"
                else
                    print_error "Failed to format $file"
                    return 1
                fi
            else
                print_warning "File not found: $file"
            fi
        done
    fi
}

# Function to format workspace
format_workspace() {
    if cargo metadata --format-version 1 | grep -q '"workspace_members"'; then
        print_status "Formatting workspace..."
        
        if cargo fmt --all; then
            print_success "Workspace formatted successfully"
        else
            print_error "Failed to format workspace"
            return 1
        fi
    else
        print_status "Not a workspace, formatting single package"
        format_rust_code
    fi
}

# Function to show formatting diff
show_formatting_diff() {
    if [ "${SHOW_DIFF:-false}" = "true" ]; then
        print_status "Showing formatting diff..."
        
        # Create a temporary copy of current files
        local temp_dir
        temp_dir=$(mktemp -d)
        
        # Copy current source files
        find src -name "*.rs" -exec cp {} "$temp_dir/" \; 2>/dev/null || true
        
        # Format the code
        cargo fmt
        
        # Show diff
        for file in src/**/*.rs; do
            if [ -f "$file" ]; then
                local basename_file
                basename_file=$(basename "$file")
                if [ -f "$temp_dir/$basename_file" ]; then
                    if ! diff -u "$temp_dir/$basename_file" "$file"; then
                        print_status "Changes made to $file"
                    fi
                fi
            fi
        done
        
        # Cleanup
        rm -rf "$temp_dir"
    fi
}

# Function to validate formatting result
validate_formatting() {
    print_status "Validating formatting result..."
    
    if cargo fmt --check; then
        print_success "All files are properly formatted"
        return 0
    else
        print_error "Some files are still not properly formatted"
        return 1
    fi
}

# Function to show formatting summary
show_formatting_summary() {
    echo ""
    echo -e "${GREEN}🎨 Formatting Summary${NC}"
    echo "=================================="
    echo "• Rustfmt: ${RUSTFMT_STATUS:-unknown}"
    echo "• Cargo.toml: ${CARGO_TOML_STATUS:-unknown}"
    echo "• Mode: ${MODE:-format}"
    echo "• Configuration: ${CONFIG_STATUS:-unknown}"
    echo ""
    
    if [ "${CHECK_ONLY:-false}" = "true" ]; then
        echo "ℹ️  Run without --check to apply formatting changes"
    fi
}

# Main function
main() {
    echo -e "${BLUE}🦀 Rust Code Formatter${NC}"
    echo "======================================"
    
    check_cargo
    install_rustfmt
    
    local exit_code=0
    
    # Check formatting configuration
    if check_formatting_config; then
        CONFIG_STATUS="found"
    else
        CONFIG_STATUS="default"
    fi
    
    # Show diff if requested
    if [ "${SHOW_DIFF:-false}" = "true" ] && [ "${CHECK_ONLY:-false}" = "false" ]; then
        show_formatting_diff
    fi
    
    # Format specific files if provided
    if [ ${#SPECIFIC_FILES[@]} -gt 0 ]; then
        if format_specific_files; then
            RUSTFMT_STATUS="formatted"
        else
            RUSTFMT_STATUS="failed"
            exit_code=1
        fi
    else
        # Format the entire project/workspace
        if [ "${WORKSPACE:-false}" = "true" ]; then
            if format_workspace; then
                RUSTFMT_STATUS="formatted"
            else
                RUSTFMT_STATUS="failed"
                exit_code=1
            fi
        else
            if format_rust_code; then
                if [ "${CHECK_ONLY:-false}" = "true" ]; then
                    RUSTFMT_STATUS="checked"
                else
                    RUSTFMT_STATUS="formatted"
                fi
            else
                RUSTFMT_STATUS="failed"
                exit_code=1
            fi
        fi
    fi
    
    # Format Cargo.toml if requested
    if [ "${FORMAT_CARGO:-false}" = "true" ]; then
        if format_cargo_toml; then
            CARGO_TOML_STATUS="formatted"
        else
            CARGO_TOML_STATUS="failed"
        fi
    else
        CARGO_TOML_STATUS="skipped"
    fi
    
    # Format imports if requested
    format_imports
    
    # Validate result if not in check mode
    if [ "${CHECK_ONLY:-false}" = "false" ] && [ $exit_code -eq 0 ]; then
        if ! validate_formatting; then
            exit_code=1
        fi
    fi
    
    show_formatting_summary
    
    if [ $exit_code -eq 0 ]; then
        if [ "${CHECK_ONLY:-false}" = "true" ]; then
            print_success "Formatting check completed successfully!"
        else
            print_success "Code formatting completed successfully!"
        fi
    else
        print_error "Formatting failed"
    fi
    
    return $exit_code
}

# Initialize arrays
SPECIFIC_FILES=()

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [options] [files...]"
            echo ""
            echo "Options:"
            echo "  --check             Check formatting without making changes"
            echo "  --workspace         Format entire workspace"
            echo "  --cargo             Format Cargo.toml"
            echo "  --imports           Organize imports"
            echo "  --diff              Show formatting diff"
            echo "  --verbose           Verbose output"
            echo "  --create-config     Create default .rustfmt.toml"
            echo "  --help              Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  CHECK_ONLY          Check mode (true|false)"
            echo "  WORKSPACE           Format workspace (true|false)"
            echo "  FORMAT_CARGO        Format Cargo.toml (true|false)"
            echo "  FORMAT_IMPORTS      Organize imports (true|false)"
            echo "  SHOW_DIFF           Show diff (true|false)"
            echo "  VERBOSE             Verbose output (true|false)"
            echo "  CREATE_CONFIG       Create config (true|false)"
            echo ""
            echo "Examples:"
            echo "  $0                      # Format all code"
            echo "  $0 --check             # Check formatting"
            echo "  $0 --workspace          # Format workspace"
            echo "  $0 src/main.rs          # Format specific file"
            echo "  $0 --cargo --imports    # Format Cargo.toml and imports"
            echo "  CHECK_ONLY=true $0      # Check via environment"
            exit 0
            ;;
        --check)
            CHECK_ONLY=true
            ;;
        --workspace)
            WORKSPACE=true
            ;;
        --cargo)
            FORMAT_CARGO=true
            ;;
        --imports)
            FORMAT_IMPORTS=true
            ;;
        --diff)
            SHOW_DIFF=true
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --create-config)
            CREATE_CONFIG=true
            ;;
        *.rs)
            SPECIFIC_FILES+=("$1")
            ;;
        *)
            print_warning "Unknown option: $1"
            ;;
    esac
    shift
done

# Set mode for summary
if [ "${CHECK_ONLY:-false}" = "true" ]; then
    MODE="check"
else
    MODE="format"
fi

main
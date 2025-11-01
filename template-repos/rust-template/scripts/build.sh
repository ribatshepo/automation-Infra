#!/bin/bash

# Rust build script
# Comprehensive build system for Rust projects

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

# Function to clean build artifacts
clean_build() {
    print_status "Cleaning build artifacts..."
    
    if cargo clean; then
        print_success "Build artifacts cleaned"
    else
        print_error "Failed to clean build artifacts"
        return 1
    fi
    
    # Clean additional artifacts
    rm -rf target/criterion/
    rm -f Cargo.lock.bak
    rm -f *.profraw
    
    print_success "All artifacts cleaned"
}

# Function to update dependencies
update_dependencies() {
    if [ "${UPDATE_DEPS:-false}" = "true" ]; then
        print_status "Updating dependencies..."
        
        if cargo update; then
            print_success "Dependencies updated"
        else
            print_warning "Failed to update some dependencies"
        fi
    fi
}

# Function to build debug version
build_debug() {
    print_status "Building debug version..."
    
    local build_args=()
    
    # Add additional build flags
    if [ "${VERBOSE:-false}" = "true" ]; then
        build_args+=(--verbose)
    fi
    
    if [ "${ALL_FEATURES:-false}" = "true" ]; then
        build_args+=(--all-features)
    fi
    
    if [ "${ALL_TARGETS:-false}" = "true" ]; then
        build_args+=(--all-targets)
    fi
    
    if cargo build "${build_args[@]}"; then
        print_success "Debug build completed"
        return 0
    else
        print_error "Debug build failed"
        return 1
    fi
}

# Function to build release version
build_release() {
    print_status "Building release version..."
    
    local build_args=(--release)
    
    # Add additional build flags
    if [ "${VERBOSE:-false}" = "true" ]; then
        build_args+=(--verbose)
    fi
    
    if [ "${ALL_FEATURES:-false}" = "true" ]; then
        build_args+=(--all-features)
    fi
    
    if [ "${ALL_TARGETS:-false}" = "true" ]; then
        build_args+=(--all-targets)
    fi
    
    if cargo build "${build_args[@]}"; then
        print_success "Release build completed"
        
        # Show binary information
        show_binary_info
        return 0
    else
        print_error "Release build failed"
        return 1
    fi
}

# Function to build for multiple targets
build_cross_platform() {
    if [ "${CROSS_COMPILE:-false}" = "true" ]; then
        print_status "Building for multiple targets..."
        
        local targets=(
            "x86_64-unknown-linux-gnu"
            "x86_64-pc-windows-gnu"
            "x86_64-apple-darwin"
        )
        
        # Install cross if not present
        if ! command -v cross >/dev/null 2>&1; then
            print_status "Installing cross for cross-compilation..."
            cargo install cross
        fi
        
        for target in "${targets[@]}"; do
            print_status "Building for $target..."
            
            if cross build --release --target "$target"; then
                print_success "Built for $target"
            else
                print_warning "Failed to build for $target"
            fi
        done
    fi
}

# Function to build workspace
build_workspace() {
    if cargo metadata --format-version 1 | grep -q '"workspace_members"'; then
        print_status "Building workspace..."
        
        local workspace_args=(--workspace)
        
        if [ "${BUILD_MODE}" = "release" ]; then
            workspace_args+=(--release)
        fi
        
        if [ "${VERBOSE:-false}" = "true" ]; then
            workspace_args+=(--verbose)
        fi
        
        if cargo build "${workspace_args[@]}"; then
            print_success "Workspace build completed"
            return 0
        else
            print_error "Workspace build failed"
            return 1
        fi
    else
        print_status "Not a workspace, building single package"
        if [ "${BUILD_MODE}" = "release" ]; then
            build_release
        else
            build_debug
        fi
    fi
}

# Function to build documentation
build_docs() {
    if [ "${BUILD_DOCS:-false}" = "true" ]; then
        print_status "Building documentation..."
        
        local doc_args=(--no-deps)
        
        if [ "${OPEN_DOCS:-false}" = "true" ]; then
            doc_args+=(--open)
        fi
        
        if [ "${DOCUMENT_PRIVATE:-false}" = "true" ]; then
            doc_args+=(--document-private-items)
        fi
        
        if cargo doc "${doc_args[@]}"; then
            print_success "Documentation built"
            
            # Show documentation location
            local doc_path="target/doc"
            if [ -d "$doc_path" ]; then
                print_status "Documentation available at: $doc_path/index.html"
            fi
        else
            print_error "Documentation build failed"
            return 1
        fi
    fi
}

# Function to build examples
build_examples() {
    if [ "${BUILD_EXAMPLES:-false}" = "true" ]; then
        print_status "Building examples..."
        
        if find examples -name "*.rs" -type f | head -1 | grep -q .; then
            if cargo build --examples; then
                print_success "Examples built"
            else
                print_error "Examples build failed"
                return 1
            fi
        else
            print_status "No examples found to build"
        fi
    fi
}

# Function to build benchmarks
build_benchmarks() {
    if [ "${BUILD_BENCHMARKS:-false}" = "true" ]; then
        print_status "Building benchmarks..."
        
        if find benches -name "*.rs" -type f | head -1 | grep -q .; then
            if cargo bench --no-run; then
                print_success "Benchmarks built"
            else
                print_error "Benchmarks build failed"
                return 1
            fi
        else
            print_status "No benchmarks found to build"
        fi
    fi
}

# Function to show binary information
show_binary_info() {
    print_status "Analyzing built binaries..."
    
    # Find binary files
    local target_dir="target"
    if [ "${BUILD_MODE}" = "release" ]; then
        target_dir="target/release"
    else
        target_dir="target/debug"
    fi
    
    if [ -d "$target_dir" ]; then
        # List executables
        find "$target_dir" -maxdepth 1 -type f -executable | while read -r binary; do
            if [ -f "$binary" ]; then
                local size
                size=$(du -h "$binary" | cut -f1)
                print_status "Binary: $(basename "$binary") (size: $size)"
                
                # Show file type if available
                if command -v file >/dev/null 2>&1; then
                    local file_info
                    file_info=$(file "$binary" | cut -d: -f2-)
                    print_status "  Type:$file_info"
                fi
            fi
        done
    fi
}

# Function to check build size
check_build_size() {
    if [ "${CHECK_SIZE:-false}" = "true" ]; then
        print_status "Checking build size..."
        
        local target_dir="target"
        if [ "${BUILD_MODE}" = "release" ]; then
            target_dir="target/release"
        else
            target_dir="target/debug"
        fi
        
        if [ -d "$target_dir" ]; then
            local total_size
            total_size=$(du -sh "$target_dir" | cut -f1)
            print_status "Total build size: $total_size"
            
            # Warn if size is too large
            local size_bytes
            size_bytes=$(du -sb "$target_dir" | cut -f1)
            local size_mb=$((size_bytes / 1024 / 1024))
            
            if [ $size_mb -gt 100 ]; then
                print_warning "Build size is quite large (${size_mb}MB)"
                print_status "Consider using 'strip = true' and 'lto = true' in Cargo.toml"
            fi
        fi
    fi
}

# Function to run post-build steps
run_post_build() {
    if [ "${POST_BUILD:-false}" = "true" ]; then
        print_status "Running post-build steps..."
        
        # Strip binaries if requested and in release mode
        if [ "${STRIP_BINARIES:-false}" = "true" ] && [ "${BUILD_MODE}" = "release" ]; then
            print_status "Stripping binaries..."
            find target/release -maxdepth 1 -type f -executable | while read -r binary; do
                if command -v strip >/dev/null 2>&1; then
                    strip "$binary" 2>/dev/null || true
                    print_status "Stripped $(basename "$binary")"
                fi
            done
        fi
        
        # Compress binaries if requested
        if [ "${COMPRESS_BINARIES:-false}" = "true" ] && [ "${BUILD_MODE}" = "release" ]; then
            print_status "Compressing binaries..."
            find target/release -maxdepth 1 -type f -executable | while read -r binary; do
                if command -v upx >/dev/null 2>&1; then
                    upx --best "$binary" 2>/dev/null || true
                    print_status "Compressed $(basename "$binary")"
                fi
            done
        fi
    fi
}

# Function to validate build
validate_build() {
    print_status "Validating build..."
    
    local target_dir="target"
    if [ "${BUILD_MODE}" = "release" ]; then
        target_dir="target/release"
    else
        target_dir="target/debug"
    fi
    
    # Check if main binary exists
    local project_name
    project_name=$(cargo metadata --format-version 1 | grep '"name"' | head -1 | cut -d'"' -f4)
    
    if [ -f "$target_dir/$project_name" ] || [ -f "$target_dir/${project_name}.exe" ]; then
        print_success "Main binary built successfully"
    else
        print_warning "Main binary not found in $target_dir"
    fi
    
    # Test if binary runs
    if [ "${TEST_BINARY:-false}" = "true" ]; then
        print_status "Testing binary execution..."
        if [ -f "$target_dir/$project_name" ]; then
            if timeout 5s "$target_dir/$project_name" --help >/dev/null 2>&1; then
                print_success "Binary executes successfully"
            else
                print_warning "Binary execution test failed or timed out"
            fi
        fi
    fi
}

# Function to show build summary
show_build_summary() {
    echo ""
    echo -e "${GREEN}🔨 Build Summary${NC}"
    echo "=================================="
    echo "• Build mode: ${BUILD_MODE:-debug}"
    echo "• Build type: ${BUILD_TYPE:-standard}"
    echo "• Target: ${TARGET:-native}"
    echo "• Features: ${FEATURES_STATUS:-default}"
    echo "• Documentation: ${DOCS_STATUS:-skipped}"
    echo "• Examples: ${EXAMPLES_STATUS:-skipped}"
    echo "• Benchmarks: ${BENCHMARKS_STATUS:-skipped}"
    echo ""
    
    # Show timing if available
    if [ -n "${BUILD_START_TIME:-}" ]; then
        local build_end_time
        build_end_time=$(date +%s)
        local build_duration=$((build_end_time - BUILD_START_TIME))
        echo "• Build duration: ${build_duration}s"
    fi
    
    # Show output location
    local target_dir="target"
    if [ "${BUILD_MODE}" = "release" ]; then
        target_dir="target/release"
    else
        target_dir="target/debug"
    fi
    echo "• Output directory: $target_dir"
}

# Main function
main() {
    echo -e "${BLUE}🦀 Rust Build System${NC}"
    echo "======================================"
    
    BUILD_START_TIME=$(date +%s)
    
    check_cargo
    
    local exit_code=0
    
    # Clean if requested
    if [ "${CLEAN:-false}" = "true" ]; then
        clean_build || exit_code=1
    fi
    
    # Update dependencies if requested
    update_dependencies
    
    # Set feature status
    if [ "${ALL_FEATURES:-false}" = "true" ]; then
        FEATURES_STATUS="all"
    else
        FEATURES_STATUS="default"
    fi
    
    # Build project
    case "${BUILD_TYPE:-standard}" in
        workspace)
            if build_workspace; then
                BUILD_STATUS="success"
            else
                BUILD_STATUS="failed"
                exit_code=1
            fi
            ;;
        cross)
            BUILD_TYPE="cross-platform"
            if [ "${BUILD_MODE}" = "release" ]; then
                build_release || exit_code=1
            else
                build_debug || exit_code=1
            fi
            build_cross_platform
            BUILD_STATUS="success"
            ;;
        *)
            if [ "${BUILD_MODE}" = "release" ]; then
                if build_release; then
                    BUILD_STATUS="success"
                else
                    BUILD_STATUS="failed"
                    exit_code=1
                fi
            else
                if build_debug; then
                    BUILD_STATUS="success"
                else
                    BUILD_STATUS="failed"
                    exit_code=1
                fi
            fi
            ;;
    esac
    
    # Build documentation
    if build_docs; then
        DOCS_STATUS="built"
    else
        DOCS_STATUS="failed"
        if [ "${BUILD_DOCS:-false}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Build examples
    if build_examples; then
        EXAMPLES_STATUS="built"
    else
        EXAMPLES_STATUS="failed"
        if [ "${BUILD_EXAMPLES:-false}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Build benchmarks
    if build_benchmarks; then
        BENCHMARKS_STATUS="built"
    else
        BENCHMARKS_STATUS="failed"
        if [ "${BUILD_BENCHMARKS:-false}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Post-build steps
    if [ $exit_code -eq 0 ]; then
        run_post_build
        check_build_size
        validate_build
    fi
    
    show_build_summary
    
    if [ $exit_code -eq 0 ]; then
        print_success "Build completed successfully!"
    else
        print_error "Build failed"
    fi
    
    return $exit_code
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --release           Build in release mode"
        echo "  --debug             Build in debug mode (default)"
        echo "  --clean             Clean before building"
        echo "  --workspace         Build entire workspace"
        echo "  --cross             Enable cross-compilation"
        echo "  --docs              Build documentation"
        echo "  --examples          Build examples"
        echo "  --benchmarks        Build benchmarks"
        echo "  --all-features      Build with all features"
        echo "  --all-targets       Build all targets"
        echo "  --update-deps       Update dependencies before building"
        echo "  --check-size        Check build size"
        echo "  --test-binary       Test binary execution"
        echo "  --strip             Strip release binaries"
        echo "  --compress          Compress binaries with UPX"
        echo "  --verbose           Verbose output"
        echo "  --help              Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  BUILD_MODE          Build mode (debug|release)"
        echo "  BUILD_TYPE          Build type (standard|workspace|cross)"
        echo "  CLEAN               Clean before build (true|false)"
        echo "  ALL_FEATURES        Build with all features (true|false)"
        echo "  ALL_TARGETS         Build all targets (true|false)"
        echo "  BUILD_DOCS          Build documentation (true|false)"
        echo "  BUILD_EXAMPLES      Build examples (true|false)"
        echo "  BUILD_BENCHMARKS    Build benchmarks (true|false)"
        echo "  CROSS_COMPILE       Enable cross-compilation (true|false)"
        echo "  UPDATE_DEPS         Update dependencies (true|false)"
        echo "  CHECK_SIZE          Check build size (true|false)"
        echo "  TEST_BINARY         Test binary execution (true|false)"
        echo "  STRIP_BINARIES      Strip binaries (true|false)"
        echo "  COMPRESS_BINARIES   Compress binaries (true|false)"
        echo "  POST_BUILD          Run post-build steps (true|false)"
        echo "  VERBOSE             Verbose output (true|false)"
        echo ""
        echo "Examples:"
        echo "  $0                    # Debug build"
        echo "  $0 --release          # Release build"
        echo "  $0 --clean --release  # Clean release build"
        echo "  $0 --workspace        # Build workspace"
        echo "  $0 --cross --release  # Cross-platform release build"
        echo "  $0 --docs --examples  # Build with docs and examples"
        echo "  BUILD_MODE=release $0 # Release build via environment"
        exit 0
        ;;
    --release)
        BUILD_MODE=release
        main
        ;;
    --debug)
        BUILD_MODE=debug
        main
        ;;
    --clean)
        CLEAN=true
        main
        ;;
    --workspace)
        BUILD_TYPE=workspace
        main
        ;;
    --cross)
        BUILD_TYPE=cross
        CROSS_COMPILE=true
        main
        ;;
    --docs)
        BUILD_DOCS=true
        main
        ;;
    --examples)
        BUILD_EXAMPLES=true
        main
        ;;
    --benchmarks)
        BUILD_BENCHMARKS=true
        main
        ;;
    --all-features)
        ALL_FEATURES=true
        main
        ;;
    --all-targets)
        ALL_TARGETS=true
        main
        ;;
    --update-deps)
        UPDATE_DEPS=true
        main
        ;;
    --check-size)
        CHECK_SIZE=true
        main
        ;;
    --test-binary)
        TEST_BINARY=true
        main
        ;;
    --strip)
        STRIP_BINARIES=true
        POST_BUILD=true
        main
        ;;
    --compress)
        COMPRESS_BINARIES=true
        POST_BUILD=true
        main
        ;;
    --verbose)
        VERBOSE=true
        main
        ;;
    *)
        main "$@"
        ;;
esac
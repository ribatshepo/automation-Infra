#!/bin/bash

# Rust security checking script
# Runs comprehensive security analysis for Rust projects

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

# Function to install security tools
install_security_tools() {
    print_status "Installing security tools..."
    
    # Install cargo-audit for vulnerability scanning
    if ! command -v cargo-audit >/dev/null 2>&1; then
        print_status "Installing cargo-audit..."
        cargo install cargo-audit
        print_success "cargo-audit installed"
    fi
    
    # Install cargo-deny for dependency analysis
    if ! command -v cargo-deny >/dev/null 2>&1; then
        print_status "Installing cargo-deny..."
        cargo install cargo-deny
        print_success "cargo-deny installed"
    fi
    
    # Install cargo-geiger for unsafe code detection
    if ! command -v cargo-geiger >/dev/null 2>&1; then
        print_status "Installing cargo-geiger..."
        cargo install cargo-geiger
        print_success "cargo-geiger installed"
    fi
}

# Function to run vulnerability audit
run_vulnerability_audit() {
    print_status "Running vulnerability audit..."
    
    local audit_args=()
    
    # Add format option if specified
    if [ -n "${AUDIT_FORMAT:-}" ]; then
        audit_args+=(--format "$AUDIT_FORMAT")
    fi
    
    # Run the audit
    if cargo audit "${audit_args[@]}"; then
        print_success "No known vulnerabilities found"
        return 0
    else
        print_error "Security vulnerabilities detected"
        
        # Show advisory details if requested
        if [ "${SHOW_DETAILS:-true}" = "true" ]; then
            print_status "Running detailed vulnerability report..."
            cargo audit --format json > vulnerability-report.json 2>/dev/null || true
            if [ -f "vulnerability-report.json" ]; then
                print_status "Detailed report saved to vulnerability-report.json"
            fi
        fi
        
        return 1
    fi
}

# Function to check dependency licenses and security policies
run_dependency_check() {
    print_status "Checking dependency licenses and security policies..."
    
    if ! command -v cargo-deny >/dev/null 2>&1; then
        print_warning "cargo-deny not available, skipping dependency policy check"
        return 0
    fi
    
    # Create default deny.toml if it doesn't exist
    if [ ! -f "deny.toml" ] && [ "${CREATE_DENY_CONFIG:-true}" = "true" ]; then
        print_status "Creating default deny.toml configuration..."
        create_default_deny_config
    fi
    
    if [ -f "deny.toml" ]; then
        if cargo deny check; then
            print_success "All dependency policies satisfied"
            return 0
        else
            print_error "Dependency policy violations found"
            return 1
        fi
    else
        print_warning "No deny.toml configuration found, skipping policy check"
        return 0
    fi
}

# Function to create default deny.toml configuration
create_default_deny_config() {
    cat > deny.toml << 'EOF'
[graph]
targets = [
    { triple = "x86_64-unknown-linux-gnu" },
    { triple = "x86_64-unknown-linux-musl" },
    { triple = "x86_64-pc-windows-msvc" },
    { triple = "x86_64-apple-darwin" },
]

[output]
feature-depth = 1

[advisories]
version = 2
db-path = "~/.cargo/advisory-db"
db-urls = ["https://github.com/rustsec/advisory-db"]
vulnerability = "deny"
unmaintained = "warn"
yanked = "warn"
notice = "warn"
ignore = [
    #"RUSTSEC-0000-0000",
]

[licenses]
version = 2
allow = [
    "MIT",
    "Apache-2.0",
    "Apache-2.0 WITH LLVM-exception",
    "BSD-2-Clause",
    "BSD-3-Clause",
    "ISC",
    "Unicode-DFS-2016",
    "CC0-1.0",
]
deny = [
    "GPL-2.0",
    "GPL-3.0",
    "AGPL-1.0",
    "AGPL-3.0",
]
copyleft = "warn"
allow-osi-fsf-free = "neither"
default = "deny"
confidence-threshold = 0.8

[bans]
multiple-versions = "warn"
wildcards = "allow"
highlight = "all"
workspace-default-features = "allow"
external-default-features = "allow"
allow = [
    #{ name = "ansi_term", version = "=0.11.0" },
]
deny = [
    #{ name = "openssl", version = "*" },
]
skip = [
    #{ name = "ansi_term", version = "=0.11.0" },
]
skip-tree = [
    #{ name = "ansi_term", version = "=0.11.0", depth = 20 },
]

[sources]
unknown-registry = "warn"
unknown-git = "warn"
allow-registry = ["https://github.com/rust-lang/crates.io-index"]
allow-git = []
EOF
    print_success "Created default deny.toml configuration"
}

# Function to detect unsafe code
detect_unsafe_code() {
    print_status "Detecting unsafe code usage..."
    
    if ! command -v cargo-geiger >/dev/null 2>&1; then
        print_warning "cargo-geiger not available, falling back to grep search"
        
        # Fallback: simple grep for unsafe blocks
        if grep -r "unsafe" src/ --include="*.rs" | grep -v "// " | grep -v "//" > unsafe-report.txt; then
            local unsafe_count
            unsafe_count=$(wc -l < unsafe-report.txt)
            print_warning "Found $unsafe_count unsafe code instances"
            
            if [ "${SHOW_UNSAFE_DETAILS:-true}" = "true" ]; then
                print_status "Unsafe code locations:"
                cat unsafe-report.txt | head -20
                if [ "$unsafe_count" -gt 20 ]; then
                    echo "... (showing first 20 instances)"
                fi
            fi
            
            rm -f unsafe-report.txt
            return 1
        else
            print_success "No unsafe code detected"
            rm -f unsafe-report.txt
            return 0
        fi
    else
        # Use cargo-geiger for detailed analysis
        if cargo geiger --format GitHubMarkdown > geiger-report.md 2>/dev/null; then
            print_status "Unsafe code analysis completed"
            
            # Check if any unsafe code was found
            if grep -q "🔒" geiger-report.md; then
                print_success "No unsafe code detected by cargo-geiger"
                return 0
            else
                print_warning "Unsafe code detected by cargo-geiger"
                
                if [ "${SHOW_UNSAFE_DETAILS:-true}" = "true" ]; then
                    print_status "Geiger report saved to geiger-report.md"
                fi
                return 1
            fi
        else
            print_error "Failed to run cargo-geiger analysis"
            return 1
        fi
    fi
}

# Function to check for common security anti-patterns
check_security_patterns() {
    print_status "Checking for common security anti-patterns..."
    
    local issues_found=0
    
    # Check for hardcoded secrets
    print_status "Checking for hardcoded secrets..."
    if grep -r -i "password\|secret\|key\|token" src/ --include="*.rs" | grep -E "(=|:)" | grep -v "TODO\|FIXME\|XXX" > secrets-check.tmp; then
        print_warning "Potential hardcoded secrets found:"
        cat secrets-check.tmp | head -10
        issues_found=$((issues_found + 1))
    fi
    rm -f secrets-check.tmp
    
    # Check for SQL injection patterns
    print_status "Checking for potential SQL injection patterns..."
    if grep -r "format!\|println!\|eprintln!" src/ --include="*.rs" | grep -i "select\|insert\|update\|delete" > sql-check.tmp; then
        print_warning "Potential SQL injection patterns found:"
        cat sql-check.tmp | head -5
        issues_found=$((issues_found + 1))
    fi
    rm -f sql-check.tmp
    
    # Check for command injection patterns
    print_status "Checking for command injection patterns..."
    if grep -r "Command::new\|process::Command" src/ --include="*.rs" | grep -v "// Safe:" > command-check.tmp; then
        print_warning "Command execution found (review for injection risks):"
        cat command-check.tmp | head -5
        issues_found=$((issues_found + 1))
    fi
    rm -f command-check.tmp
    
    # Check for deserialize without validation
    print_status "Checking for unsafe deserialization..."
    if grep -r "serde_json::from_str\|bincode::deserialize" src/ --include="*.rs" > deserial-check.tmp; then
        print_warning "Deserialization without validation found:"
        cat deserial-check.tmp | head -5
        issues_found=$((issues_found + 1))
    fi
    rm -f deserial-check.tmp
    
    if [ $issues_found -eq 0 ]; then
        print_success "No common security anti-patterns detected"
        return 0
    else
        print_warning "Found $issues_found potential security issues"
        return 1
    fi
}

# Function to check Rust security best practices
check_rust_security_practices() {
    print_status "Checking Rust security best practices..."
    
    local warnings=0
    
    # Check for panic handlers in production code
    if grep -r "panic!\|unwrap()\|expect(" src/ --include="*.rs" --exclude="*test*" > panic-check.tmp; then
        print_warning "Panic-inducing code found in production code:"
        cat panic-check.tmp | head -5
        warnings=$((warnings + 1))
    fi
    rm -f panic-check.tmp
    
    # Check for unsafe arithmetic operations
    if grep -r "as i\|as u\|wrapping_" src/ --include="*.rs" > arithmetic-check.tmp; then
        print_warning "Potential unsafe arithmetic operations found:"
        cat arithmetic-check.tmp | head -5
        warnings=$((warnings + 1))
    fi
    rm -f arithmetic-check.tmp
    
    # Check Cargo.toml security features
    if [ -f "Cargo.toml" ]; then
        print_status "Checking Cargo.toml security configuration..."
        
        if ! grep -q "\[profile\.release\]" Cargo.toml; then
            print_warning "No release profile configuration found"
            warnings=$((warnings + 1))
        fi
        
        if ! grep -q "panic = \"abort\"" Cargo.toml; then
            print_warning "Consider setting 'panic = \"abort\"' in release profile"
            warnings=$((warnings + 1))
        fi
        
        if ! grep -q "strip = true" Cargo.toml; then
            print_warning "Consider setting 'strip = true' in release profile"
            warnings=$((warnings + 1))
        fi
    fi
    
    if [ $warnings -eq 0 ]; then
        print_success "Rust security best practices are being followed"
        return 0
    else
        print_warning "Found $warnings security practice recommendations"
        return 0  # Don't fail on recommendations
    fi
}

# Function to generate security report
generate_security_report() {
    if [ "${GENERATE_REPORT:-false}" = "true" ]; then
        print_status "Generating security report..."
        
        local report_file="security-report.md"
        
        cat > "$report_file" << EOF
# Security Analysis Report

Generated on: $(date)
Project: $(basename "$PWD")

## Summary

- Vulnerability Audit: ${VULNERABILITY_STATUS:-unknown}
- Dependency Check: ${DEPENDENCY_STATUS:-unknown}
- Unsafe Code Detection: ${UNSAFE_CODE_STATUS:-unknown}
- Security Patterns: ${SECURITY_PATTERNS_STATUS:-unknown}
- Best Practices: ${BEST_PRACTICES_STATUS:-unknown}

## Details

### Vulnerability Audit
$(if [ -f "vulnerability-report.json" ]; then echo "See vulnerability-report.json for details"; else echo "No detailed report available"; fi)

### Unsafe Code Analysis
$(if [ -f "geiger-report.md" ]; then echo "See geiger-report.md for details"; else echo "No detailed report available"; fi)

### Recommendations

1. Regularly update dependencies: \`cargo update\`
2. Run security audits before releases: \`cargo audit\`
3. Review unsafe code usage carefully
4. Use \`#![forbid(unsafe_code)]\` if unsafe code is not needed
5. Enable security-related compiler flags in release builds
6. Use static analysis tools in CI/CD pipeline

### Next Steps

- Address any vulnerabilities found
- Review and document unsafe code usage
- Consider implementing additional security measures
- Set up automated security scanning in CI/CD

EOF
        
        print_success "Security report generated: $report_file"
    fi
}

# Function to show security summary
show_security_summary() {
    echo ""
    echo -e "${GREEN}🔐 Security Analysis Summary${NC}"
    echo "=================================="
    echo "• Vulnerability audit: ${VULNERABILITY_STATUS:-unknown}"
    echo "• Dependency check: ${DEPENDENCY_STATUS:-unknown}"
    echo "• Unsafe code detection: ${UNSAFE_CODE_STATUS:-unknown}"
    echo "• Security patterns: ${SECURITY_PATTERNS_STATUS:-unknown}"
    echo "• Best practices: ${BEST_PRACTICES_STATUS:-unknown}"
    echo ""
    
    if [ -f "security-report.md" ]; then
        echo "📋 Detailed report: security-report.md"
    fi
}

# Main function
main() {
    echo -e "${BLUE}🦀 Rust Security Checker${NC}"
    echo "======================================"
    
    check_cargo
    
    # Install security tools if needed
    if [ "${INSTALL_TOOLS:-true}" = "true" ]; then
        install_security_tools
    fi
    
    local exit_code=0
    
    # Run vulnerability audit
    if run_vulnerability_audit; then
        VULNERABILITY_STATUS="passed"
    else
        VULNERABILITY_STATUS="failed"
        if [ "${FAIL_ON_VULN:-true}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Run dependency check
    if run_dependency_check; then
        DEPENDENCY_STATUS="passed"
    else
        DEPENDENCY_STATUS="failed"
        if [ "${FAIL_ON_DEPS:-false}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Detect unsafe code
    if detect_unsafe_code; then
        UNSAFE_CODE_STATUS="clean"
    else
        UNSAFE_CODE_STATUS="detected"
        if [ "${FAIL_ON_UNSAFE:-false}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Check security patterns
    if check_security_patterns; then
        SECURITY_PATTERNS_STATUS="good"
    else
        SECURITY_PATTERNS_STATUS="issues"
        if [ "${FAIL_ON_PATTERNS:-false}" = "true" ]; then
            exit_code=1
        fi
    fi
    
    # Check best practices
    if check_rust_security_practices; then
        BEST_PRACTICES_STATUS="good"
    else
        BEST_PRACTICES_STATUS="warnings"
    fi
    
    # Generate report if requested
    generate_security_report
    
    show_security_summary
    
    if [ $exit_code -eq 0 ]; then
        print_success "Security analysis completed successfully!"
    else
        print_error "Security analysis found critical issues"
    fi
    
    return $exit_code
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --no-install          Skip tool installation"
        echo "  --report              Generate security report"
        echo "  --fail-on-vuln        Fail on vulnerabilities (default: true)"
        echo "  --fail-on-deps        Fail on dependency issues"
        echo "  --fail-on-unsafe      Fail on unsafe code"
        echo "  --fail-on-patterns    Fail on security patterns"
        echo "  --audit-format FORMAT Set audit output format"
        echo "  --no-details          Skip detailed reports"
        echo "  --help                Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  INSTALL_TOOLS         Install security tools (true|false)"
        echo "  GENERATE_REPORT       Generate security report (true|false)"
        echo "  FAIL_ON_VULN          Fail on vulnerabilities (true|false)"
        echo "  FAIL_ON_DEPS          Fail on dependency issues (true|false)"
        echo "  FAIL_ON_UNSAFE        Fail on unsafe code (true|false)"
        echo "  FAIL_ON_PATTERNS      Fail on security patterns (true|false)"
        echo "  AUDIT_FORMAT          Audit output format (json|human)"
        echo "  SHOW_DETAILS          Show detailed reports (true|false)"
        echo "  SHOW_UNSAFE_DETAILS   Show unsafe code details (true|false)"
        echo "  CREATE_DENY_CONFIG    Create deny.toml config (true|false)"
        echo ""
        echo "Examples:"
        echo "  $0                     # Run all security checks"
        echo "  $0 --report            # Generate security report"
        echo "  $0 --fail-on-unsafe    # Fail if unsafe code found"
        echo "  $0 --no-install        # Skip tool installation"
        echo "  GENERATE_REPORT=true $0 # Generate report via environment"
        exit 0
        ;;
    --no-install)
        INSTALL_TOOLS=false
        main
        ;;
    --report)
        GENERATE_REPORT=true
        main
        ;;
    --fail-on-vuln)
        FAIL_ON_VULN=true
        main
        ;;
    --fail-on-deps)
        FAIL_ON_DEPS=true
        main
        ;;
    --fail-on-unsafe)
        FAIL_ON_UNSAFE=true
        main
        ;;
    --fail-on-patterns)
        FAIL_ON_PATTERNS=true
        main
        ;;
    --audit-format)
        if [ -z "${2:-}" ]; then
            print_error "Please specify an audit format"
            exit 1
        fi
        AUDIT_FORMAT="$2"
        shift
        main
        ;;
    --no-details)
        SHOW_DETAILS=false
        SHOW_UNSAFE_DETAILS=false
        main
        ;;
    *)
        main "$@"
        ;;
esac
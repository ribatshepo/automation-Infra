#!/bin/bash

# Docker Security Check Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Configuration
IMAGE_NAME=${1:-$(basename "$(pwd)")}
IMAGE_TAG=${2:-"latest"}
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
REPORT_DIR="security-reports"

print_status "Running security checks for ${FULL_IMAGE}..."

# Create reports directory
mkdir -p "$REPORT_DIR"

# Check if image exists
if ! docker images "${FULL_IMAGE}" | grep -q "${IMAGE_NAME}"; then
    print_error "Image not found: ${FULL_IMAGE}"
    print_status "Build the image first with: ./scripts/build.sh"
    exit 1
fi

# Hadolint - Dockerfile linting
print_status "Running Hadolint (Dockerfile linting)..."
if command -v hadolint >/dev/null 2>&1; then
    if hadolint Dockerfile > "$REPORT_DIR/hadolint-report.txt" 2>&1; then
        print_success "Hadolint: No issues found"
    else
        print_warning "Hadolint: Issues found in Dockerfile"
        echo "Report saved to: $REPORT_DIR/hadolint-report.txt"
        cat "$REPORT_DIR/hadolint-report.txt"
    fi
else
    print_warning "Hadolint not found. Install with: scripts/setup.sh"
fi

# Trivy - Vulnerability scanning
print_status "Running Trivy (Vulnerability scanning)..."
if command -v trivy >/dev/null 2>&1; then
    # High/Critical vulnerabilities
    print_status "Scanning for HIGH and CRITICAL vulnerabilities..."
    if trivy image --severity HIGH,CRITICAL --format table "${FULL_IMAGE}" > "$REPORT_DIR/trivy-critical.txt" 2>&1; then
        print_success "Trivy: No high/critical vulnerabilities found"
    else
        print_warning "Trivy: High/critical vulnerabilities found"
        echo "Critical vulnerabilities report saved to: $REPORT_DIR/trivy-critical.txt"
        cat "$REPORT_DIR/trivy-critical.txt"
    fi
    
    # Full vulnerability report
    print_status "Generating full Trivy report..."
    trivy image --format json --output "$REPORT_DIR/trivy-full.json" "${FULL_IMAGE}"
    trivy image --format table --output "$REPORT_DIR/trivy-full.txt" "${FULL_IMAGE}"
    print_status "Full reports saved to: $REPORT_DIR/trivy-full.json and $REPORT_DIR/trivy-full.txt"
    
    # SARIF format for GitHub
    trivy image --format sarif --output "$REPORT_DIR/trivy-results.sarif" "${FULL_IMAGE}"
    print_status "SARIF report for GitHub saved to: $REPORT_DIR/trivy-results.sarif"
    
else
    print_warning "Trivy not found. Install with: scripts/setup.sh"
fi

# Grype - Alternative vulnerability scanner
print_status "Running Grype (Alternative vulnerability scanner)..."
if command -v grype >/dev/null 2>&1; then
    grype "${FULL_IMAGE}" -o table > "$REPORT_DIR/grype-report.txt" 2>&1
    grype "${FULL_IMAGE}" -o json > "$REPORT_DIR/grype-report.json" 2>&1
    print_status "Grype reports saved to: $REPORT_DIR/grype-report.txt and $REPORT_DIR/grype-report.json"
else
    print_warning "Grype not found. Install with: curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin"
fi

# Syft - SBOM generation
print_status "Generating Software Bill of Materials (SBOM)..."
if command -v syft >/dev/null 2>&1; then
    syft "${FULL_IMAGE}" -o spdx-json > "$REPORT_DIR/sbom.spdx.json"
    syft "${FULL_IMAGE}" -o table > "$REPORT_DIR/sbom.txt"
    print_status "SBOM saved to: $REPORT_DIR/sbom.spdx.json and $REPORT_DIR/sbom.txt"
else
    print_warning "Syft not found. Install with: curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin"
fi

# Docker Scout (if available)
print_status "Running Docker Scout..."
if docker scout version >/dev/null 2>&1; then
    docker scout cves "${FULL_IMAGE}" --format sarif --output "$REPORT_DIR/docker-scout.sarif" 2>/dev/null || true
    docker scout cves "${FULL_IMAGE}" > "$REPORT_DIR/docker-scout.txt" 2>&1 || true
    print_status "Docker Scout reports saved to: $REPORT_DIR/docker-scout.*"
else
    print_warning "Docker Scout not available. Enable with: docker scout"
fi

# Dive - Image layer analysis
print_status "Analyzing image layers..."
if command -v dive >/dev/null 2>&1; then
    print_status "Running dive analysis..."
    # Generate efficiency report
    dive "${FULL_IMAGE}" --ci --ci-config .dive-ci.yml > "$REPORT_DIR/dive-analysis.txt" 2>&1 || {
        # Create basic dive config if it doesn't exist
        cat > .dive-ci.yml << 'EOF'
rules:
  - name: 'wasted-bytes-0.1'
    selector: 'wasted-bytes > 0.1GB'
    action: 'warn'
  - name: 'efficiency-0.9'
    selector: 'efficiency < 0.9'
    action: 'warn'
EOF
        dive "${FULL_IMAGE}" --ci --ci-config .dive-ci.yml > "$REPORT_DIR/dive-analysis.txt" 2>&1
    }
    print_status "Dive analysis saved to: $REPORT_DIR/dive-analysis.txt"
else
    print_warning "dive not found. Install with: scripts/setup.sh"
fi

# Container structure test
print_status "Running container structure tests..."
if command -v container-structure-test >/dev/null 2>&1; then
    if [[ -f "container-structure-test.yaml" ]]; then
        container-structure-test test --image "${FULL_IMAGE}" --config container-structure-test.yaml > "$REPORT_DIR/structure-test.txt" 2>&1
        print_status "Structure test results saved to: $REPORT_DIR/structure-test.txt"
    else
        print_warning "No container-structure-test.yaml found. Creating basic template..."
        cat > container-structure-test.yaml << 'EOF'
schemaVersion: 2.0.0
fileExistenceTests:
  - name: 'app directory'
    path: '/app'
    shouldExist: true
    isDirectory: true
  - name: 'package.json'
    path: '/app/package.json'
    shouldExist: true
commandTests:
  - name: 'node version'
    command: 'node'
    args: ['--version']
    expectedOutput: ['v18.*']
metadataTest:
  exposedPorts: ["3000"]
  user: "appuser"
EOF
        container-structure-test test --image "${FULL_IMAGE}" --config container-structure-test.yaml > "$REPORT_DIR/structure-test.txt" 2>&1
        print_status "Structure test results saved to: $REPORT_DIR/structure-test.txt"
    fi
else
    print_warning "container-structure-test not found. Install from: https://github.com/GoogleContainerTools/container-structure-test"
fi

# CIS Docker Benchmark
print_status "Checking CIS Docker Benchmark..."
if docker images | grep -q "docker/docker-bench-security"; then
    print_status "Running CIS Docker Benchmark..."
    docker run --rm --net host --pid host --userns host --cap-add audit_control \
        -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
        -v /etc:/etc:ro \
        -v /usr/bin/containerd:/usr/bin/containerd:ro \
        -v /usr/bin/runc:/usr/bin/runc:ro \
        -v /usr/lib/systemd:/usr/lib/systemd:ro \
        -v /var/lib:/var/lib:ro \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        --label docker_bench_security \
        docker/docker-bench-security > "$REPORT_DIR/docker-bench-security.txt" 2>&1
    print_status "CIS Benchmark results saved to: $REPORT_DIR/docker-bench-security.txt"
else
    print_status "Docker Bench Security not available. Pull with:"
    print_status "docker pull docker/docker-bench-security"
fi

# Generate summary report
print_status "Generating security summary..."
cat > "$REPORT_DIR/security-summary.md" << EOF
# Security Scan Summary

**Image:** ${FULL_IMAGE}  
**Scan Date:** $(date)  
**Scan Host:** $(hostname)

## Scan Results

### Dockerfile Linting (Hadolint)
$(if [[ -f "$REPORT_DIR/hadolint-report.txt" ]]; then
    if [[ -s "$REPORT_DIR/hadolint-report.txt" ]]; then
        echo "FAIL - Issues found - see hadolint-report.txt"
    else
        echo "PASS - No issues found"
    fi
else
    echo "SKIP - Not available"
fi)

### Vulnerability Scanning (Trivy)
$(if [[ -f "$REPORT_DIR/trivy-critical.txt" ]]; then
    CRITICAL_COUNT=$(grep -c "CRITICAL" "$REPORT_DIR/trivy-critical.txt" 2>/dev/null || echo "0")
    HIGH_COUNT=$(grep -c "HIGH" "$REPORT_DIR/trivy-critical.txt" 2>/dev/null || echo "0")
    if [[ "$CRITICAL_COUNT" -eq 0 && "$HIGH_COUNT" -eq 0 ]]; then
        echo "PASS - No critical/high vulnerabilities"
    else
        echo "FAIL - Found $CRITICAL_COUNT critical and $HIGH_COUNT high vulnerabilities"
    fi
else
    echo "SKIP - Not available"
fi)

### Image Analysis (Dive)
$(if [[ -f "$REPORT_DIR/dive-analysis.txt" ]]; then
    if grep -q "PASS" "$REPORT_DIR/dive-analysis.txt" 2>/dev/null; then
        echo "PASS - Image efficiency acceptable"
    else
        echo "WARN - Image efficiency could be improved"
    fi
else
    echo "SKIP - Not available"
fi)

### Container Structure Test
$(if [[ -f "$REPORT_DIR/structure-test.txt" ]]; then
    if grep -q "PASS" "$REPORT_DIR/structure-test.txt" 2>/dev/null; then
        echo "PASS - All structure tests passed"
    else
        echo "FAIL - Some structure tests failed"
    fi
else
    echo "SKIP - Not available"
fi)

## Files Generated
$(ls -la "$REPORT_DIR" | grep -v "^total" | awk '{print "- " $9 " (" $5 " bytes)"}')

## Recommendations

1. Review all security scan reports
2. Address critical and high vulnerabilities
3. Optimize image layers for better efficiency
4. Ensure proper security configurations
5. Regular security scanning in CI/CD pipeline

EOF

print_success "Security checks completed"
print_status "Summary report: $REPORT_DIR/security-summary.md"
print_status "All reports saved in: $REPORT_DIR/"

# Display critical issues
if [[ -f "$REPORT_DIR/trivy-critical.txt" ]] && [[ -s "$REPORT_DIR/trivy-critical.txt" ]]; then
    print_warning "Critical security issues found!"
    echo "Run: cat $REPORT_DIR/trivy-critical.txt"
fi
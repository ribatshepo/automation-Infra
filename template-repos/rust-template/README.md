# Rust Project Template

A minimal, extensible Rust project template with modern tooling and CI/CD integration.

## Features

- **Modern Rust**: Latest stable Rust with Cargo workspace support
- **Code Quality**: Clippy, rustfmt, and comprehensive linting
- **Testing**: Unit tests, integration tests, and benchmarks
- **Security**: Cargo audit for vulnerability scanning
- **Documentation**: Automated documentation generation with rustdoc
- **CI/CD Integration**: GitHub Actions workflows from cicd-templates
- **Performance**: Criterion for benchmarking and profiling
- **Extensible**: Easy to customize for web services, CLI tools, or libraries

## Quick Start

### 1. Use This Template
```bash
# Create new repository from template
gh repo create my-rust-project --template automation-infra/rust-template
cd my-rust-project
```

### 2. Initialize Project
```bash
# Run setup script
./scripts/setup.sh

# Build and test
cargo build
cargo test
```

### 3. Configure CI/CD
```bash
# Set up GitHub Actions (optional)
./scripts/setup-cicd.sh
```

## Project Structure

```
rust-template/
├── README.md                    # This file
├── Cargo.toml                   # Workspace configuration
├── Cargo.lock                   # Locked dependencies
├── .gitignore                   # Git ignore patterns
├── .rustfmt.toml               # Rustfmt configuration
├── clippy.toml                 # Clippy configuration
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
├── src/                        # Main library source code
│   ├── lib.rs                  # Library root
│   ├── config.rs               # Configuration module
│   ├── error.rs                # Error handling
│   └── utils.rs                # Utility functions
├── src/bin/                    # Binary applications
│   └── server.rs               # Example server application
├── tests/                      # Integration tests
│   ├── common/                 # Test utilities
│   │   └── mod.rs
│   └── integration_test.rs     # Integration tests
├── benches/                    # Benchmark tests
│   └── benchmark.rs            # Performance benchmarks
├── examples/                   # Usage examples
│   └── basic_usage.rs          # Basic usage example
└── docs/                       # Documentation
    ├── api.md
    └── deployment.md
```

## Configuration

### Workspace Configuration (Cargo.toml)
```toml
[workspace]
members = [
    ".",
]

[package]
name = "project-name"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <your.email@example.com>"]
description = "A minimal Rust project template"
license = "MIT"
repository = "https://github.com/your-org/project-name"
documentation = "https://docs.rs/project-name"
homepage = "https://github.com/your-org/project-name"
readme = "README.md"
keywords = ["rust", "template", "boilerplate"]
categories = ["development-tools"]

[dependencies]
tokio = { version = "1.0", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
clap = { version = "4.0", features = ["derive"] }
tracing = "0.1"
tracing-subscriber = "0.3"
thiserror = "1.0"
anyhow = "1.0"

[dev-dependencies]
criterion = "0.5"
tempfile = "3.0"
mockall = "0.11"

[[bin]]
name = "server"
path = "src/bin/server.rs"

[[bench]]
name = "benchmark"
harness = false

[profile.release]
lto = true
codegen-units = 1
panic = "abort"
strip = true

[profile.dev]
debug = true
split-debuginfo = "unpacked"

[profile.test]
debug = true
```

### Rustfmt Configuration (.rustfmt.toml)
```toml
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
```

### Clippy Configuration (clippy.toml)
```toml
# Clippy configuration
avoid-breaking-exported-api = false
msrv = "1.70.0"

# Allowed lints (these won't trigger warnings)
allow = [
    "clippy::module_name_repetitions",
    "clippy::similar_names",
]

# Denied lints (these will cause compilation to fail)
deny = [
    "clippy::all",
    "clippy::pedantic",
    "clippy::cargo",
    "clippy::nursery",
]

# Warned lints (these will show warnings)
warn = [
    "clippy::use_debug",
    "clippy::dbg_macro",
    "clippy::todo",
    "clippy::unimplemented",
]
```

## Development Workflow

### Setup Development Environment
```bash
# Install Rust (rustup)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Initialize project
./scripts/setup.sh

# Install additional tools
rustup component add rustfmt clippy
cargo install cargo-audit cargo-tarpaulin
```

### Daily Development
```bash
# Run development server
cargo run --bin server

# Run tests
cargo test

# Run linting
cargo clippy

# Format code
cargo fmt

# Build project
cargo build --release

# Run all checks
./scripts/check-all.sh
```

### Dependency Management
```bash
# Add dependency
cargo add package-name

# Add development dependency
cargo add --dev package-name

# Update dependencies
cargo update

# Check for outdated dependencies
cargo outdated
```

## Testing

### Test Structure
```rust
// src/lib.rs
//! # Project Name
//! 
//! A minimal Rust project template with modern tooling.

pub mod config;
pub mod error;
pub mod utils;

pub use config::Config;
pub use error::{Error, Result};

/// Main library function for demonstration.
pub fn process_data(input: &str) -> Result<String> {
    if input.is_empty() {
        return Err(Error::InvalidInput("Input cannot be empty".to_string()));
    }
    
    Ok(format!("Processed: {}", input.to_uppercase()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_process_data() {
        let result = process_data("hello").unwrap();
        assert_eq!(result, "Processed: HELLO");
    }

    #[test]
    fn test_process_data_empty() {
        let result = process_data("");
        assert!(result.is_err());
    }
}
```

### Test Commands
```bash
# Run all tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run specific test
cargo test test_process_data

# Run integration tests only
cargo test --test integration_test

# Run benchmarks
cargo bench

# Generate coverage report
cargo tarpaulin --out html
```

## CI/CD Integration

This template integrates with the automation-infra CI/CD templates:

### GitHub Actions Workflow
- Uses `cicd-templates/examples/main-rust-deploy.yml`
- Automated testing and linting
- Security scanning with cargo audit
- Container building and deployment
- Performance benchmarking with criterion

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
    uses: automation-infra/cicd-templates/.github/workflows/main-rust-deploy.yml@main
    with:
      rust_version: "stable"
      project_name: "my-rust-project"
      run_tests: true
      run_benchmarks: true
      run_security_scan: true
      deploy_to_registry: false
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}
```

## Customization

### Framework-Specific Extensions

#### Web Service with Actix-web
```bash
# Add Actix dependencies
cargo add actix-web actix-rt

# Update src/bin/server.rs for Actix
# Add route handlers and middleware
# Update tests for HTTP endpoints
```

#### CLI Application with Clap
```bash
# Add CLI dependencies
cargo add clap --features derive

# Create CLI structure
# Add command definitions
# Update CI/CD for binary distribution
```

#### Async Runtime with Tokio
```bash
# Add async dependencies
cargo add tokio --features full
cargo add tokio-util

# Add async utilities
# Update error handling for async
# Add async tests
```

### Database Integration
```bash
# Add database dependencies (example: PostgreSQL)
cargo add sqlx --features "runtime-tokio-rustls,postgres,chrono,uuid"
cargo add sea-orm

# Add migration tools
# Configure connection pooling
# Add database tests
```

## Security

### Dependency Scanning
- Automated vulnerability scanning with `cargo audit`
- License compliance checking
- Security advisories monitoring

### Code Security
- Static analysis with Clippy
- Memory safety guaranteed by Rust
- SAST integration in CI/CD

### Security Configuration
```bash
# Install security tools
cargo install cargo-audit

# Run security audit
cargo audit

# Check for supply chain attacks
cargo audit --db ./advisory-db
```

## Performance

### Benchmarking
```rust
// benches/benchmark.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use project_name::process_data;

fn benchmark_process_data(c: &mut Criterion) {
    c.bench_function("process_data", |b| {
        b.iter(|| process_data(black_box("benchmark input")))
    });
}

criterion_group!(benches, benchmark_process_data);
criterion_main!(benches);
```

### Profiling
```bash
# Install profiling tools
cargo install flamegraph

# Generate flame graph
cargo flamegraph --bin server

# Profile with perf
perf record --call-graph=dwarf ./target/release/server
perf report
```

## Deployment Options

### Container Deployment
```dockerfile
# Multi-stage build for Rust application
FROM rust:1.75 as builder

WORKDIR /app

# Copy manifest files
COPY Cargo.toml Cargo.lock ./

# Create dummy main to cache dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm src/main.rs

# Copy source code
COPY src/ ./src/

# Build application
RUN cargo build --release

# Production stage
FROM debian:bookworm-slim as production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -r -s /bin/false appuser

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/target/release/server ./server

# Change ownership to non-root user
RUN chown appuser:appuser ./server

# Switch to non-root user
USER appuser

EXPOSE 8080

CMD ["./server"]
```

### Binary Distribution
- Cross-compilation for multiple platforms
- GitHub Releases automation
- Package managers (Cargo, Homebrew, etc.)

## Best Practices

### Code Organization
- Use modules for logical separation
- Keep functions small and focused
- Use type system for safety
- Document public APIs thoroughly

### Error Handling
- Use `Result` types for fallible operations
- Create custom error types with thiserror
- Use `anyhow` for application errors
- Handle errors explicitly

### Performance
- Use appropriate data structures
- Profile before optimizing
- Leverage Rust's zero-cost abstractions
- Consider memory allocation patterns

### Testing
- Write unit tests for all public functions
- Use integration tests for workflows
- Add benchmarks for performance-critical code
- Test error conditions

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
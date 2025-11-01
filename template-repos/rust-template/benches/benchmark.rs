use criterion::{black_box, criterion_group, criterion_main, Criterion};
use project_name::{process_data, utils};

fn benchmark_process_data(c: &mut Criterion) {
    c.bench_function("process_data", |b| {
        b.iter(|| {
            let input = "benchmark test input";
            process_data(black_box(input)).unwrap()
        })
    });
}

fn benchmark_timestamp_generation(c: &mut Criterion) {
    c.bench_function("current_timestamp", |b| {
        b.iter(|| {
            utils::current_timestamp()
        })
    });
}

fn benchmark_string_sanitization(c: &mut Criterion) {
    c.bench_function("sanitize_string", |b| {
        b.iter(|| {
            let input = "Hello, World! <script>alert('xss')</script> with unicode: 你好";
            utils::sanitize_string(black_box(input))
        })
    });
}

fn benchmark_email_validation(c: &mut Criterion) {
    let emails = vec![
        "test@example.com",
        "user.name@domain.co.uk",
        "invalid.email",
        "another@test.org",
        "@invalid.com",
        "user@",
        "valid.email@subdomain.example.org",
    ];
    
    c.bench_function("validate_email", |b| {
        b.iter(|| {
            for email in &emails {
                utils::validate_email(black_box(email));
            }
        })
    });
}

fn benchmark_random_string_generation(c: &mut Criterion) {
    c.bench_function("generate_random_string", |b| {
        b.iter(|| {
            utils::generate_random_string(black_box(32))
        })
    });
}

fn benchmark_rate_limiter(c: &mut Criterion) {
    let rate_limiter = utils::RateLimiter::new(100, std::time::Duration::from_secs(60));
    
    c.bench_function("rate_limiter_check", |b| {
        b.iter(|| {
            rate_limiter.is_allowed()
        })
    });
}

fn benchmark_metrics_collector(c: &mut Criterion) {
    let metrics = utils::MetricsCollector::new();
    
    c.bench_function("metrics_increment_counter", |b| {
        b.iter(|| {
            metrics.increment_counter(black_box("test_counter"), black_box(1))
        })
    });
    
    c.bench_function("metrics_set_gauge", |b| {
        b.iter(|| {
            metrics.set_gauge(black_box("test_gauge"), black_box(42.5))
        })
    });
    
    c.bench_function("metrics_get_json", |b| {
        b.iter(|| {
            metrics.get_metrics_json().unwrap()
        })
    });
}

fn benchmark_config_validation(c: &mut Criterion) {
    let config = project_name::Config::default();
    
    c.bench_function("config_validation", |b| {
        b.iter(|| {
            config.validate().unwrap()
        })
    });
}

fn benchmark_error_creation(c: &mut Criterion) {
    c.bench_function("error_creation", |b| {
        b.iter(|| {
            let _error = project_name::Error::InvalidInput(black_box("test error".to_string()));
        })
    });
}

fn benchmark_health_checker(c: &mut Criterion) {
    let mut checker = utils::HealthChecker::new();
    checker.add_check(|| Ok(()));
    checker.add_check(|| Ok(()));
    checker.add_check(|| Ok(()));
    
    c.bench_function("health_check", |b| {
        b.iter(|| {
            checker.check_health().unwrap()
        })
    });
}

// Group all benchmarks
criterion_group!(
    benches,
    benchmark_process_data,
    benchmark_timestamp_generation,
    benchmark_string_sanitization,
    benchmark_email_validation,
    benchmark_random_string_generation,
    benchmark_rate_limiter,
    benchmark_metrics_collector,
    benchmark_config_validation,
    benchmark_error_creation,
    benchmark_health_checker
);

criterion_main!(benches);
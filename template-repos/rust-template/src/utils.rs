use std::time::{Duration, SystemTime, UNIX_EPOCH};
use tracing::{info, warn, error};

use crate::error::{Error, Result};

/// Utility functions for the application.

/// Get current timestamp in seconds since Unix epoch.
pub fn current_timestamp() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_else(|_| Duration::from_secs(0))
        .as_secs()
}

/// Format timestamp as ISO 8601 string.
pub fn format_timestamp(timestamp: u64) -> String {
    let datetime = UNIX_EPOCH + Duration::from_secs(timestamp);
    
    match datetime.elapsed() {
        Ok(_) => {
            // For this example, we'll use a simple format
            // In a real application, you might want to use chrono
            format!("timestamp-{}", timestamp)
        }
        Err(_) => "invalid-timestamp".to_string(),
    }
}

/// Validate email format (basic validation).
pub fn validate_email(email: &str) -> bool {
    email.contains('@') && email.contains('.') && email.len() > 5
}

/// Sanitize string input for logging and display.
pub fn sanitize_string(input: &str) -> String {
    input
        .chars()
        .filter(|c| c.is_alphanumeric() || c.is_whitespace() || ".-_@".contains(*c))
        .collect()
}

/// Generate a random string of specified length.
pub fn generate_random_string(length: usize) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    
    let mut hasher = DefaultHasher::new();
    current_timestamp().hash(&mut hasher);
    let hash = hasher.finish();
    
    let chars: Vec<char> = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        .chars()
        .collect();
    
    (0..length)
        .map(|i| {
            let index = ((hash.wrapping_add(i as u64)) % chars.len() as u64) as usize;
            chars[index]
        })
        .collect()
}

/// Retry operation with exponential backoff.
pub async fn retry_with_backoff<F, T, E>(
    mut operation: F,
    max_retries: usize,
    initial_delay: Duration,
) -> std::result::Result<T, E>
where
    F: FnMut() -> std::result::Result<T, E>,
    E: std::fmt::Debug,
{
    let mut delay = initial_delay;
    
    for attempt in 0..=max_retries {
        match operation() {
            Ok(result) => {
                if attempt > 0 {
                    info!("Operation succeeded after {} retries", attempt);
                }
                return Ok(result);
            }
            Err(error) => {
                if attempt == max_retries {
                    error!("Operation failed after {} retries: {:?}", max_retries, error);
                    return Err(error);
                }
                
                warn!("Operation failed (attempt {}), retrying in {:?}: {:?}", 
                      attempt + 1, delay, error);
                
                tokio::time::sleep(delay).await;
                delay *= 2; // Exponential backoff
            }
        }
    }
    
    unreachable!("Loop should always return")
}

/// Rate limiter implementation.
pub struct RateLimiter {
    requests: std::sync::Arc<std::sync::Mutex<Vec<u64>>>,
    limit: usize,
    window: Duration,
}

impl RateLimiter {
    /// Create a new rate limiter.
    pub fn new(limit: usize, window: Duration) -> Self {
        Self {
            requests: std::sync::Arc::new(std::sync::Mutex::new(Vec::new())),
            limit,
            window,
        }
    }
    
    /// Check if request is allowed.
    pub fn is_allowed(&self) -> bool {
        let now = current_timestamp();
        let window_start = now.saturating_sub(self.window.as_secs());
        
        let mut requests = self.requests.lock().unwrap();
        
        // Remove old requests
        requests.retain(|&timestamp| timestamp >= window_start);
        
        // Check if we're under the limit
        if requests.len() < self.limit {
            requests.push(now);
            true
        } else {
            false
        }
    }
    
    /// Get current request count in window.
    pub fn current_count(&self) -> usize {
        let now = current_timestamp();
        let window_start = now.saturating_sub(self.window.as_secs());
        
        let requests = self.requests.lock().unwrap();
        requests.iter().filter(|&&timestamp| timestamp >= window_start).count()
    }
}

/// Health check utilities.
pub struct HealthChecker {
    checks: Vec<Box<dyn Fn() -> Result<()> + Send + Sync>>,
}

impl HealthChecker {
    /// Create a new health checker.
    pub fn new() -> Self {
        Self {
            checks: Vec::new(),
        }
    }
    
    /// Add a health check function.
    pub fn add_check<F>(&mut self, check: F)
    where
        F: Fn() -> Result<()> + Send + Sync + 'static,
    {
        self.checks.push(Box::new(check));
    }
    
    /// Run all health checks.
    pub fn check_health(&self) -> Result<()> {
        for (i, check) in self.checks.iter().enumerate() {
            if let Err(error) = check() {
                error!("Health check {} failed: {:?}", i, error);
                return Err(error);
            }
        }
        
        info!("All health checks passed");
        Ok(())
    }
}

impl Default for HealthChecker {
    fn default() -> Self {
        Self::new()
    }
}

/// Metrics collector.
pub struct MetricsCollector {
    counters: std::sync::Arc<std::sync::Mutex<std::collections::HashMap<String, u64>>>,
    gauges: std::sync::Arc<std::sync::Mutex<std::collections::HashMap<String, f64>>>,
}

impl MetricsCollector {
    /// Create a new metrics collector.
    pub fn new() -> Self {
        Self {
            counters: std::sync::Arc::new(std::sync::Mutex::new(std::collections::HashMap::new())),
            gauges: std::sync::Arc::new(std::sync::Mutex::new(std::collections::HashMap::new())),
        }
    }
    
    /// Increment a counter.
    pub fn increment_counter(&self, name: &str, value: u64) {
        let mut counters = self.counters.lock().unwrap();
        *counters.entry(name.to_string()).or_insert(0) += value;
    }
    
    /// Set a gauge value.
    pub fn set_gauge(&self, name: &str, value: f64) {
        let mut gauges = self.gauges.lock().unwrap();
        gauges.insert(name.to_string(), value);
    }
    
    /// Get counter value.
    pub fn get_counter(&self, name: &str) -> u64 {
        let counters = self.counters.lock().unwrap();
        counters.get(name).copied().unwrap_or(0)
    }
    
    /// Get gauge value.
    pub fn get_gauge(&self, name: &str) -> Option<f64> {
        let gauges = self.gauges.lock().unwrap();
        gauges.get(name).copied()
    }
    
    /// Get all metrics as JSON.
    pub fn get_metrics_json(&self) -> Result<String> {
        let counters = self.counters.lock().unwrap();
        let gauges = self.gauges.lock().unwrap();
        
        let metrics = serde_json::json!({
            "counters": *counters,
            "gauges": *gauges,
            "timestamp": current_timestamp()
        });
        
        serde_json::to_string(&metrics).map_err(Error::from)
    }
}

impl Default for MetricsCollector {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_current_timestamp() {
        let timestamp = current_timestamp();
        assert!(timestamp > 0);
    }

    #[test]
    fn test_validate_email() {
        assert!(validate_email("test@example.com"));
        assert!(validate_email("user.name@domain.co.uk"));
        assert!(!validate_email("invalid"));
        assert!(!validate_email("@domain.com"));
        assert!(!validate_email("user@"));
    }

    #[test]
    fn test_sanitize_string() {
        let input = "Hello, World! <script>alert('xss')</script>";
        let sanitized = sanitize_string(input);
        assert!(!sanitized.contains('<'));
        assert!(!sanitized.contains('>'));
        assert!(sanitized.contains("Hello"));
    }

    #[test]
    fn test_generate_random_string() {
        let random1 = generate_random_string(10);
        let random2 = generate_random_string(10);
        
        assert_eq!(random1.len(), 10);
        assert_eq!(random2.len(), 10);
        // Note: These might be the same due to deterministic nature
        // In a real implementation, you'd use a proper random generator
    }

    #[test]
    fn test_rate_limiter() {
        let limiter = RateLimiter::new(2, Duration::from_secs(60));
        
        assert!(limiter.is_allowed());
        assert_eq!(limiter.current_count(), 1);
        
        assert!(limiter.is_allowed());
        assert_eq!(limiter.current_count(), 2);
        
        assert!(!limiter.is_allowed());
        assert_eq!(limiter.current_count(), 2);
    }

    #[test]
    fn test_health_checker() {
        let mut checker = HealthChecker::new();
        
        // Add a passing check
        checker.add_check(|| Ok(()));
        
        // Add a failing check
        checker.add_check(|| Err(Error::Internal("Test failure".to_string())));
        
        // Should fail due to the failing check
        assert!(checker.check_health().is_err());
    }

    #[test]
    fn test_metrics_collector() -> Result<()> {
        let collector = MetricsCollector::new();
        
        collector.increment_counter("requests", 1);
        collector.increment_counter("requests", 5);
        collector.set_gauge("cpu_usage", 75.5);
        
        assert_eq!(collector.get_counter("requests"), 6);
        assert_eq!(collector.get_gauge("cpu_usage"), Some(75.5));
        assert_eq!(collector.get_gauge("nonexistent"), None);
        
        let json = collector.get_metrics_json()?;
        assert!(json.contains("requests"));
        assert!(json.contains("cpu_usage"));
        
        Ok(())
    }

    #[tokio::test]
    async fn test_retry_with_backoff() {
        let mut attempts = 0;
        
        let result = retry_with_backoff(
            || {
                attempts += 1;
                if attempts < 3 {
                    Err("Temporary failure")
                } else {
                    Ok("Success")
                }
            },
            5,
            Duration::from_millis(10),
        ).await;
        
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "Success");
        assert_eq!(attempts, 3);
    }
}
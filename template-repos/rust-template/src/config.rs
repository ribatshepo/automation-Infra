use serde::{Deserialize, Serialize};
use std::env;
use std::path::PathBuf;

use crate::error::{Error, Result};

/// Application configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    /// Server configuration
    pub server: ServerConfig,
    
    /// Database configuration
    pub database: DatabaseConfig,
    
    /// Logging configuration
    pub logging: LoggingConfig,
    
    /// Security configuration
    pub security: SecurityConfig,
}

/// Server configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    /// Server host address
    pub host: String,
    
    /// Server port
    pub port: u16,
    
    /// Maximum number of connections
    pub max_connections: usize,
    
    /// Request timeout in seconds
    pub timeout: u64,
    
    /// Enable TLS
    pub tls_enabled: bool,
    
    /// TLS certificate file path
    pub tls_cert_path: Option<PathBuf>,
    
    /// TLS private key file path
    pub tls_key_path: Option<PathBuf>,
}

/// Database configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseConfig {
    /// Database URL
    pub url: String,
    
    /// Maximum number of database connections
    pub max_connections: u32,
    
    /// Connection timeout in seconds
    pub timeout: u64,
    
    /// Enable connection pooling
    pub pool_enabled: bool,
}

/// Logging configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoggingConfig {
    /// Log level (trace, debug, info, warn, error)
    pub level: String,
    
    /// Log output format (json, pretty, compact)
    pub format: String,
    
    /// Log file path (optional)
    pub file_path: Option<PathBuf>,
    
    /// Enable console output
    pub console_enabled: bool,
    
    /// Enable structured logging
    pub structured: bool,
}

/// Security configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    /// JWT secret key
    pub jwt_secret: String,
    
    /// JWT expiration time in hours
    pub jwt_expiration: u64,
    
    /// Enable rate limiting
    pub rate_limiting_enabled: bool,
    
    /// Rate limit requests per minute
    pub rate_limit_rpm: u32,
    
    /// Enable CORS
    pub cors_enabled: bool,
    
    /// Allowed CORS origins
    pub cors_origins: Vec<String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            server: ServerConfig {
                host: "127.0.0.1".to_string(),
                port: 8080,
                max_connections: 1000,
                timeout: 30,
                tls_enabled: false,
                tls_cert_path: None,
                tls_key_path: None,
            },
            database: DatabaseConfig {
                url: "postgresql://localhost/myapp".to_string(),
                max_connections: 10,
                timeout: 30,
                pool_enabled: true,
            },
            logging: LoggingConfig {
                level: "info".to_string(),
                format: "pretty".to_string(),
                file_path: None,
                console_enabled: true,
                structured: false,
            },
            security: SecurityConfig {
                jwt_secret: "your-secret-key".to_string(),
                jwt_expiration: 24,
                rate_limiting_enabled: true,
                rate_limit_rpm: 100,
                cors_enabled: true,
                cors_origins: vec!["http://localhost:3000".to_string()],
            },
        }
    }
}

impl Config {
    /// Load configuration from environment variables and config file.
    pub fn load() -> Result<Self> {
        let mut config = Self::default();
        
        // Override with environment variables
        config.load_from_env()?;
        
        // Try to load from config file
        if let Ok(config_path) = env::var("CONFIG_FILE") {
            config.load_from_file(&config_path)?;
        }
        
        // Validate configuration
        config.validate()?;
        
        Ok(config)
    }
    
    /// Load configuration from environment variables.
    pub fn load_from_env(&mut self) -> Result<()> {
        if let Ok(host) = env::var("SERVER_HOST") {
            self.server.host = host;
        }
        
        if let Ok(port) = env::var("SERVER_PORT") {
            self.server.port = port.parse()
                .map_err(|_| Error::Config("Invalid SERVER_PORT".to_string()))?;
        }
        
        if let Ok(db_url) = env::var("DATABASE_URL") {
            self.database.url = db_url;
        }
        
        if let Ok(log_level) = env::var("LOG_LEVEL") {
            self.logging.level = log_level;
        }
        
        if let Ok(jwt_secret) = env::var("JWT_SECRET") {
            self.security.jwt_secret = jwt_secret;
        }
        
        Ok(())
    }
    
    /// Load configuration from a file.
    pub fn load_from_file<P: AsRef<std::path::Path>>(&mut self, path: P) -> Result<()> {
        let content = std::fs::read_to_string(path)?;
        let file_config: Config = serde_json::from_str(&content)?;
        
        // Merge with current config (file takes precedence)
        *self = file_config;
        
        Ok(())
    }
    
    /// Validate configuration values.
    pub fn validate(&self) -> Result<()> {
        if self.server.port == 0 {
            return Err(Error::Config("Server port cannot be 0".to_string()));
        }
        
        if self.database.url.is_empty() {
            return Err(Error::Config("Database URL cannot be empty".to_string()));
        }
        
        if self.security.jwt_secret.len() < 32 {
            return Err(Error::Config("JWT secret must be at least 32 characters".to_string()));
        }
        
        let valid_log_levels = ["trace", "debug", "info", "warn", "error"];
        if !valid_log_levels.contains(&self.logging.level.as_str()) {
            return Err(Error::Config(format!(
                "Invalid log level: {}. Valid levels: {:?}",
                self.logging.level, valid_log_levels
            )));
        }
        
        Ok(())
    }
    
    /// Get server bind address.
    pub fn server_address(&self) -> String {
        format!("{}:{}", self.server.host, self.server.port)
    }
    
    /// Check if running in development mode.
    pub fn is_development(&self) -> bool {
        env::var("RUST_ENV").unwrap_or_else(|_| "development".to_string()) == "development"
    }
    
    /// Check if running in production mode.
    pub fn is_production(&self) -> bool {
        env::var("RUST_ENV").unwrap_or_else(|_| "development".to_string()) == "production"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;
    use std::io::Write;

    #[test]
    fn test_default_config() {
        let config = Config::default();
        assert_eq!(config.server.host, "127.0.0.1");
        assert_eq!(config.server.port, 8080);
        assert_eq!(config.logging.level, "info");
    }

    #[test]
    fn test_config_validation() {
        let mut config = Config::default();
        
        // Valid config should pass
        assert!(config.validate().is_ok());
        
        // Invalid port should fail
        config.server.port = 0;
        assert!(config.validate().is_err());
        
        // Reset port
        config.server.port = 8080;
        
        // Empty database URL should fail
        config.database.url = String::new();
        assert!(config.validate().is_err());
        
        // Reset database URL
        config.database.url = "postgresql://localhost/test".to_string();
        
        // Short JWT secret should fail
        config.security.jwt_secret = "short".to_string();
        assert!(config.validate().is_err());
    }

    #[test]
    fn test_load_from_file() -> Result<()> {
        let mut config = Config::default();
        
        // Create temporary config file
        let mut temp_file = NamedTempFile::new()?;
        let test_config = r#"
        {
            "server": {
                "host": "0.0.0.0",
                "port": 9000,
                "max_connections": 2000,
                "timeout": 60,
                "tls_enabled": false,
                "tls_cert_path": null,
                "tls_key_path": null
            },
            "database": {
                "url": "postgresql://test:test@localhost/testdb",
                "max_connections": 20,
                "timeout": 60,
                "pool_enabled": true
            },
            "logging": {
                "level": "debug",
                "format": "json",
                "file_path": null,
                "console_enabled": true,
                "structured": true
            },
            "security": {
                "jwt_secret": "this-is-a-very-long-secret-key-for-testing",
                "jwt_expiration": 48,
                "rate_limiting_enabled": true,
                "rate_limit_rpm": 200,
                "cors_enabled": true,
                "cors_origins": ["http://localhost:3000"]
            }
        }
        "#;
        
        temp_file.write_all(test_config.as_bytes())?;
        
        // Load config from file
        config.load_from_file(temp_file.path())?;
        
        // Verify loaded values
        assert_eq!(config.server.host, "0.0.0.0");
        assert_eq!(config.server.port, 9000);
        assert_eq!(config.logging.level, "debug");
        assert_eq!(config.security.jwt_expiration, 48);
        
        Ok(())
    }

    #[test]
    fn test_server_address() {
        let config = Config::default();
        assert_eq!(config.server_address(), "127.0.0.1:8080");
    }
}
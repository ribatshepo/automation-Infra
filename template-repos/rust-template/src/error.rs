use thiserror::Error;

/// Application error types.
#[derive(Error, Debug)]
pub enum Error {
    #[error("Invalid input: {0}")]
    InvalidInput(String),
    
    #[error("Configuration error: {0}")]
    Config(String),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
    
    #[error("Network error: {0}")]
    Network(String),
    
    #[error("Database error: {0}")]
    Database(String),
    
    #[error("Authentication error: {0}")]
    Auth(String),
    
    #[error("Permission denied: {0}")]
    Permission(String),
    
    #[error("Resource not found: {0}")]
    NotFound(String),
    
    #[error("Internal server error: {0}")]
    Internal(String),
}

/// Application result type.
pub type Result<T> = std::result::Result<T, Error>;

impl Error {
    /// Check if the error is recoverable.
    pub fn is_recoverable(&self) -> bool {
        matches!(
            self,
            Error::Network(_) | Error::Database(_) | Error::Io(_)
        )
    }
    
    /// Get error severity level.
    pub fn severity(&self) -> ErrorSeverity {
        match self {
            Error::InvalidInput(_) | Error::Config(_) => ErrorSeverity::Warning,
            Error::Auth(_) | Error::Permission(_) => ErrorSeverity::Error,
            Error::NotFound(_) => ErrorSeverity::Info,
            Error::Network(_) | Error::Database(_) | Error::Io(_) => ErrorSeverity::Error,
            Error::Serialization(_) | Error::Internal(_) => ErrorSeverity::Critical,
        }
    }
}

/// Error severity levels.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorSeverity {
    Info,
    Warning,
    Error,
    Critical,
}

impl std::fmt::Display for ErrorSeverity {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ErrorSeverity::Info => write!(f, "INFO"),
            ErrorSeverity::Warning => write!(f, "WARN"),
            ErrorSeverity::Error => write!(f, "ERROR"),
            ErrorSeverity::Critical => write!(f, "CRITICAL"),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_severity() {
        let error = Error::InvalidInput("test".to_string());
        assert_eq!(error.severity(), ErrorSeverity::Warning);
        
        let error = Error::Internal("test".to_string());
        assert_eq!(error.severity(), ErrorSeverity::Critical);
    }

    #[test]
    fn test_error_is_recoverable() {
        let error = Error::Network("test".to_string());
        assert!(error.is_recoverable());
        
        let error = Error::Auth("test".to_string());
        assert!(!error.is_recoverable());
    }
}
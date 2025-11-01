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
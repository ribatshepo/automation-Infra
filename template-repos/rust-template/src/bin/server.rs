use clap::{Parser, Subcommand};
use tokio::net::TcpListener;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tracing::{info, error, warn};
use tracing_subscriber;

use project_name::{Config, Result, process_data};

#[derive(Parser)]
#[command(name = "server")]
#[command(about = "A simple HTTP server example")]
#[command(version = "0.1.0")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
    
    /// Configuration file path
    #[arg(short, long)]
    config: Option<String>,
    
    /// Log level
    #[arg(short, long, default_value = "info")]
    log_level: String,
    
    /// Server host
    #[arg(long, default_value = "127.0.0.1")]
    host: String,
    
    /// Server port
    #[arg(short, long, default_value = "8080")]
    port: u16,
}

#[derive(Subcommand)]
enum Commands {
    /// Start the HTTP server
    Serve {
        /// Enable TLS
        #[arg(long)]
        tls: bool,
    },
    /// Run health check
    Health,
    /// Process data from stdin
    Process {
        /// Input data
        #[arg(short, long)]
        input: Option<String>,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(&cli.log_level)
        .init();
    
    info!("Starting server application");
    
    // Load configuration
    let mut config = if let Some(config_path) = cli.config {
        std::env::set_var("CONFIG_FILE", config_path);
        Config::load()?
    } else {
        Config::default()
    };
    
    // Override config with CLI arguments
    config.server.host = cli.host;
    config.server.port = cli.port;
    
    // Validate configuration
    config.validate()?;
    
    match cli.command {
        Some(Commands::Serve { tls }) => {
            config.server.tls_enabled = tls;
            start_server(config).await
        }
        Some(Commands::Health) => {
            run_health_check().await
        }
        Some(Commands::Process { input }) => {
            run_process_command(input).await
        }
        None => {
            // Default to serving
            start_server(config).await
        }
    }
}

async fn start_server(config: Config) -> Result<()> {
    let address = config.server_address();
    info!("Starting HTTP server on {}", address);
    
    let listener = TcpListener::bind(&address).await
        .map_err(|e| project_name::Error::Network(format!("Failed to bind to {}: {}", address, e)))?;
    
    info!("Server listening on {}", address);
    
    loop {
        match listener.accept().await {
            Ok((mut socket, addr)) => {
                info!("New connection from {}", addr);
                
                tokio::spawn(async move {
                    if let Err(e) = handle_connection(&mut socket).await {
                        error!("Error handling connection from {}: {:?}", addr, e);
                    }
                });
            }
            Err(e) => {
                error!("Failed to accept connection: {}", e);
            }
        }
    }
}

async fn handle_connection(socket: &mut tokio::net::TcpStream) -> Result<()> {
    let mut buffer = [0; 1024];
    let bytes_read = socket.read(&mut buffer).await
        .map_err(|e| project_name::Error::Network(format!("Failed to read from socket: {}", e)))?;
    
    let request = String::from_utf8_lossy(&buffer[..bytes_read]);
    info!("Received request: {}", request.lines().next().unwrap_or(""));
    
    // Parse HTTP request (basic parsing)
    let (method, path) = parse_request_line(&request)?;
    
    let response = match (method.as_str(), path.as_str()) {
        ("GET", "/") => {
            create_response(200, "OK", "text/html", 
                           "<h1>Hello from Rust Server!</h1><p>Server is running.</p>")
        }
        ("GET", "/health") => {
            create_response(200, "OK", "application/json", 
                           r#"{"status":"healthy","timestamp":"#.to_string() + &project_name::utils::current_timestamp().to_string() + "}")
        }
        ("POST", "/process") => {
            // Extract body from request (simplified)
            let body = extract_body(&request);
            match process_data(&body) {
                Ok(result) => {
                    let json_response = format!(r#"{{"result":"{}","status":"success"}}"#, result);
                    create_response(200, "OK", "application/json", &json_response)
                }
                Err(e) => {
                    let json_response = format!(r#"{{"error":"{}","status":"error"}}"#, e);
                    create_response(400, "Bad Request", "application/json", &json_response)
                }
            }
        }
        ("GET", "/metrics") => {
            // Simple metrics endpoint
            let metrics = format!(r#"{{
                "uptime_seconds": {},
                "requests_total": 1,
                "status": "healthy"
            }}"#, project_name::utils::current_timestamp());
            create_response(200, "OK", "application/json", &metrics)
        }
        _ => {
            create_response(404, "Not Found", "text/html", 
                           "<h1>404 Not Found</h1><p>The requested resource was not found.</p>")
        }
    };
    
    socket.write_all(response.as_bytes()).await
        .map_err(|e| project_name::Error::Network(format!("Failed to write response: {}", e)))?;
    
    Ok(())
}

fn parse_request_line(request: &str) -> Result<(String, String)> {
    let first_line = request.lines().next()
        .ok_or_else(|| project_name::Error::InvalidInput("Empty request".to_string()))?;
    
    let parts: Vec<&str> = first_line.split_whitespace().collect();
    if parts.len() < 2 {
        return Err(project_name::Error::InvalidInput("Invalid request line".to_string()));
    }
    
    Ok((parts[0].to_string(), parts[1].to_string()))
}

fn extract_body(request: &str) -> String {
    // Find the empty line that separates headers from body
    if let Some(body_start) = request.find("\r\n\r\n") {
        request[body_start + 4..].to_string()
    } else if let Some(body_start) = request.find("\n\n") {
        request[body_start + 2..].to_string()
    } else {
        String::new()
    }
}

fn create_response(status_code: u16, status_text: &str, content_type: &str, body: &str) -> String {
    format!(
        "HTTP/1.1 {} {}\r\nContent-Type: {}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        status_code,
        status_text,
        content_type,
        body.len(),
        body
    )
}

async fn run_health_check() -> Result<()> {
    info!("Running health check");
    
    // Perform basic health checks
    let mut checker = project_name::utils::HealthChecker::new();
    
    // Check system resources
    checker.add_check(|| {
        info!("Checking system health");
        Ok(())
    });
    
    // Check configuration
    checker.add_check(|| {
        info!("Checking configuration");
        let config = Config::load()?;
        config.validate()?;
        Ok(())
    });
    
    match checker.check_health() {
        Ok(()) => {
            info!("Health check passed");
            Ok(())
        }
        Err(e) => {
            error!("Health check failed: {:?}", e);
            Err(e)
        }
    }
}

async fn run_process_command(input: Option<String>) -> Result<()> {
    let data = if let Some(input) = input {
        input
    } else {
        info!("Reading from stdin...");
        let mut buffer = String::new();
        std::io::stdin().read_line(&mut buffer)
            .map_err(|e| project_name::Error::Io(e))?;
        buffer.trim().to_string()
    };
    
    info!("Processing input: {}", data);
    
    match process_data(&data) {
        Ok(result) => {
            info!("Result: {}", result);
            println!("{}", result);
            Ok(())
        }
        Err(e) => {
            error!("Processing failed: {:?}", e);
            Err(e)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_request_line() {
        let request = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n";
        let (method, path) = parse_request_line(request).unwrap();
        assert_eq!(method, "GET");
        assert_eq!(path, "/");
    }

    #[test]
    fn test_extract_body() {
        let request = "POST /process HTTP/1.1\r\nContent-Length: 5\r\n\r\nhello";
        let body = extract_body(request);
        assert_eq!(body, "hello");
    }

    #[test]
    fn test_create_response() {
        let response = create_response(200, "OK", "text/plain", "Hello");
        assert!(response.contains("HTTP/1.1 200 OK"));
        assert!(response.contains("Content-Type: text/plain"));
        assert!(response.contains("Content-Length: 5"));
        assert!(response.contains("Hello"));
    }
}
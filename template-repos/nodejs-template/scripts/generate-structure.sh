#!/bin/bash
set -e

echo "Generating basic project structure..."

# Create main entry point
cat > src/index.ts << 'EOF'
/**
 * Main entry point for the application.
 */

import { app } from './app';

const PORT = process.env.PORT || 3000;

/**
 * Start the server
 */
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

/**
 * Graceful shutdown
 */
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
  });
});

export { server };
EOF

# Create app configuration
cat > src/app.ts << 'EOF'
/**
 * Application setup and configuration.
 */

import express, { Express, Request, Response, NextFunction } from 'express';
import { router } from './routes';
import { errorHandler, requestLogger } from './middleware';

/**
 * Create Express application
 */
const app: Express = express();

/**
 * Middleware setup
 */
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

/**
 * Health check endpoint
 */
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
  });
});

/**
 * Ready check endpoint
 */
app.get('/ready', (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'ready',
    timestamp: new Date().toISOString(),
  });
});

/**
 * API routes
 */
app.use('/api', router);

/**
 * Root endpoint
 */
app.get('/', (_req: Request, res: Response) => {
  res.json({
    message: 'Welcome to Node.js API template',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      ready: '/ready',
      api: '/api',
    },
  });
});

/**
 * 404 handler
 */
app.use('*', (_req: Request, res: Response) => {
  res.status(404).json({
    error: 'Route not found',
    message: 'The requested route does not exist',
  });
});

/**
 * Error handling middleware
 */
app.use(errorHandler);

export { app };
EOF

# Create routes
cat > src/routes/index.ts << 'EOF'
/**
 * API routes definition.
 */

import { Router, Request, Response } from 'express';

const router = Router();

/**
 * GET /api/
 * API information endpoint
 */
router.get('/', (_req: Request, res: Response) => {
  res.json({
    message: 'API is running',
    version: '1.0.0',
    endpoints: [
      'GET /api/',
      'GET /api/status',
    ],
  });
});

/**
 * GET /api/status
 * Status endpoint
 */
router.get('/status', (_req: Request, res: Response) => {
  res.json({
    status: 'active',
    timestamp: new Date().toISOString(),
    nodeVersion: process.version,
    platform: process.platform,
    memory: process.memoryUsage(),
  });
});

export { router };
EOF

# Create middleware
cat > src/middleware/index.ts << 'EOF'
/**
 * Express middleware functions.
 */

import { Request, Response, NextFunction } from 'express';

/**
 * Request logging middleware
 */
export const requestLogger = (
  req: Request,
  _res: Response,
  next: NextFunction
): void => {
  const timestamp = new Date().toISOString();
  console.log(`${timestamp} - ${req.method} ${req.path}`);
  next();
};

/**
 * Error handling middleware
 */
export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  console.error('Error:', err);

  // Default error response
  const statusCode = 500;
  const message = process.env.NODE_ENV === 'production' 
    ? 'Internal Server Error' 
    : err.message;

  res.status(statusCode).json({
    error: message,
    timestamp: new Date().toISOString(),
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
};

/**
 * Async error wrapper
 */
export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>
) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
EOF

# Create services
cat > src/services/index.ts << 'EOF'
/**
 * Business logic services.
 */

/**
 * Example service class
 */
export class ExampleService {
  /**
   * Get example data
   */
  public async getData(): Promise<{ message: string; data: unknown[] }> {
    // Simulate async operation
    await new Promise(resolve => setTimeout(resolve, 100));
    
    return {
      message: 'Data retrieved successfully',
      data: [
        { id: 1, name: 'Example 1' },
        { id: 2, name: 'Example 2' },
      ],
    };
  }

  /**
   * Process data
   */
  public async processData(input: unknown): Promise<{ processed: boolean; input: unknown }> {
    // Simulate processing
    await new Promise(resolve => setTimeout(resolve, 50));
    
    return {
      processed: true,
      input,
    };
  }
}

/**
 * Service instances
 */
export const exampleService = new ExampleService();
EOF

# Create utilities
cat > src/utils/index.ts << 'EOF'
/**
 * Utility functions and helpers.
 */

/**
 * Validate email format
 */
export const isValidEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Generate random string
 */
export const generateRandomString = (length: number): string => {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  
  for (let i = 0; i < length; i++) {
    result += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  
  return result;
};

/**
 * Delay execution
 */
export const delay = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

/**
 * Format date to ISO string
 */
export const formatDate = (date: Date): string => {
  return date.toISOString();
};

/**
 * Parse JSON safely
 */
export const safeJsonParse = <T>(json: string, defaultValue: T): T => {
  try {
    return JSON.parse(json) as T;
  } catch {
    return defaultValue;
  }
};

/**
 * Environment configuration
 */
export const config = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  isDevelopment: process.env.NODE_ENV === 'development',
  isProduction: process.env.NODE_ENV === 'production',
  isTest: process.env.NODE_ENV === 'test',
};
EOF

# Create test setup
cat > tests/setup.ts << 'EOF'
/**
 * Test setup and configuration.
 */

// Mock console methods in test environment
if (process.env.NODE_ENV === 'test') {
  global.console = {
    ...console,
    log: jest.fn(),
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  };
}

// Set test timeout
jest.setTimeout(10000);
EOF

# Create unit tests
cat > tests/unit/index.test.ts << 'EOF'
/**
 * Unit tests for main modules.
 */

import { generateRandomString, isValidEmail, safeJsonParse } from '../../src/utils';
import { ExampleService } from '../../src/services';

describe('Utils', () => {
  describe('generateRandomString', () => {
    it('should generate string of correct length', () => {
      const length = 10;
      const result = generateRandomString(length);
      expect(result).toHaveLength(length);
    });

    it('should generate different strings', () => {
      const result1 = generateRandomString(10);
      const result2 = generateRandomString(10);
      expect(result1).not.toBe(result2);
    });
  });

  describe('isValidEmail', () => {
    it('should validate correct email', () => {
      expect(isValidEmail('test@example.com')).toBe(true);
    });

    it('should reject invalid email', () => {
      expect(isValidEmail('invalid-email')).toBe(false);
    });
  });

  describe('safeJsonParse', () => {
    it('should parse valid JSON', () => {
      const result = safeJsonParse('{"key": "value"}', {});
      expect(result).toEqual({ key: 'value' });
    });

    it('should return default value for invalid JSON', () => {
      const defaultValue = { default: true };
      const result = safeJsonParse('invalid json', defaultValue);
      expect(result).toBe(defaultValue);
    });
  });
});

describe('ExampleService', () => {
  let service: ExampleService;

  beforeEach(() => {
    service = new ExampleService();
  });

  describe('getData', () => {
    it('should return data with message', async () => {
      const result = await service.getData();
      expect(result).toHaveProperty('message');
      expect(result).toHaveProperty('data');
      expect(Array.isArray(result.data)).toBe(true);
    });
  });

  describe('processData', () => {
    it('should process input data', async () => {
      const input = { test: 'data' };
      const result = await service.processData(input);
      expect(result.processed).toBe(true);
      expect(result.input).toBe(input);
    });
  });
});
EOF

# Create integration tests
cat > tests/integration/app.test.ts << 'EOF'
/**
 * Integration tests for the application.
 */

import request from 'supertest';
import { app } from '../../src/app';

describe('Application Integration Tests', () => {
  describe('GET /', () => {
    it('should return welcome message', async () => {
      const response = await request(app).get('/');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('endpoints');
    });
  });

  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ok');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
    });
  });

  describe('GET /ready', () => {
    it('should return ready status', async () => {
      const response = await request(app).get('/ready');
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ready');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /api', () => {
    it('should return API information', async () => {
      const response = await request(app).get('/api');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('endpoints');
    });
  });

  describe('GET /api/status', () => {
    it('should return status information', async () => {
      const response = await request(app).get('/api/status');
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('active');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('nodeVersion');
      expect(response.body).toHaveProperty('platform');
      expect(response.body).toHaveProperty('memory');
    });
  });

  describe('GET /nonexistent', () => {
    it('should return 404 for unknown routes', async () => {
      const response = await request(app).get('/nonexistent');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Route not found');
    });
  });
});
EOF

# Create documentation
cat > docs/api.md << 'EOF'
# API Documentation

## Overview

This API provides a RESTful interface for the Node.js application template.

## Endpoints

### Health Checks

#### GET /health
Returns the health status of the application.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-11-02T12:00:00.000Z",
  "uptime": 123.456,
  "environment": "development"
}
```

#### GET /ready
Returns the readiness status of the application.

**Response:**
```json
{
  "status": "ready",
  "timestamp": "2024-11-02T12:00:00.000Z"
}
```

### API Endpoints

#### GET /api
Returns information about the API.

**Response:**
```json
{
  "message": "API is running",
  "version": "1.0.0",
  "endpoints": [
    "GET /api/",
    "GET /api/status"
  ]
}
```

#### GET /api/status
Returns detailed status information.

**Response:**
```json
{
  "status": "active",
  "timestamp": "2024-11-02T12:00:00.000Z",
  "nodeVersion": "v18.0.0",
  "platform": "linux",
  "memory": {
    "rss": 123456,
    "heapTotal": 123456,
    "heapUsed": 123456,
    "external": 123456,
    "arrayBuffers": 123456
  }
}
```

## Error Handling

All endpoints return appropriate HTTP status codes and error messages:

- `200` - Success
- `404` - Not Found
- `500` - Internal Server Error

Error response format:
```json
{
  "error": "Error message",
  "timestamp": "2024-11-02T12:00:00.000Z"
}
```
EOF

cat > docs/deployment.md << 'EOF'
# Deployment Guide

## Docker Deployment

### Build Image
```bash
docker build -t my-nodejs-app .
```

### Run Container
```bash
docker run -p 3000:3000 -e NODE_ENV=production my-nodejs-app
```

## Kubernetes Deployment

### Using kubectl
```bash
kubectl apply -f k8s/
```

### Using Helm
```bash
helm install my-app ./helm/project-name
```

## Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production/test)

## Health Checks

The application provides health check endpoints for container orchestration:

- `/health` - Application health status
- `/ready` - Application readiness status
EOF

# Create example usage
cat > examples/basic-usage.js << 'EOF'
/**
 * Basic usage example for the Node.js API.
 */

const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000';

/**
 * Example API calls
 */
async function examples() {
  try {
    // Check application health
    console.log('Checking health...');
    const healthResponse = await axios.get(`${API_BASE_URL}/health`);
    console.log('Health:', healthResponse.data);

    // Get API information
    console.log('\nGetting API info...');
    const apiResponse = await axios.get(`${API_BASE_URL}/api`);
    console.log('API Info:', apiResponse.data);

    // Get status information
    console.log('\nGetting status...');
    const statusResponse = await axios.get(`${API_BASE_URL}/api/status`);
    console.log('Status:', statusResponse.data);

  } catch (error) {
    console.error('Error:', error.message);
  }
}

// Run examples if this file is executed directly
if (require.main === module) {
  examples();
}

module.exports = { examples };
EOF

echo "Basic project structure generated successfully!"
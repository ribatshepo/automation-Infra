# Node.js Project Template

A minimal, extensible Node.js project template with modern tooling and CI/CD integration.

## Features

- **Package Management**: Support for npm, yarn, and pnpm
- **Code Quality**: ESLint, Prettier, and TypeScript support
- **Testing**: Jest with coverage reporting
- **Security**: Dependency scanning and vulnerability checks
- **Documentation**: Automated documentation generation
- **CI/CD Integration**: GitHub Actions workflows from cicd-templates
- **Performance**: Load testing and benchmarking tools
- **Extensible**: Easy to customize for frameworks like Express, NestJS, or Next.js

## Quick Start

### 1. Use This Template
```bash
# Create new repository from template
gh repo create my-nodejs-project --template automation-infra/nodejs-template
cd my-nodejs-project
```

### 2. Initialize Project
```bash
# Run setup script
./scripts/setup.sh

# Install dependencies (choose your package manager)
npm install
# or
yarn install
# or
pnpm install
```

### 3. Configure CI/CD
```bash
# Set up GitHub Actions (optional)
./scripts/setup-cicd.sh
```

## Project Structure

```
nodejs-template/
├── README.md                    # This file
├── package.json                # Project configuration and dependencies
├── package-lock.json           # Locked dependencies (npm)
├── yarn.lock                   # Locked dependencies (yarn)
├── pnpm-lock.yaml              # Locked dependencies (pnpm)
├── .gitignore                  # Git ignore patterns
├── .nvmrc                      # Node.js version specification
├── .eslintrc.js                # ESLint configuration
├── .prettierrc                 # Prettier configuration
├── jest.config.js              # Jest configuration
├── tsconfig.json               # TypeScript configuration
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
├── src/                        # Source code
│   ├── index.ts                # Entry point
│   ├── app.ts                  # Application setup
│   ├── routes/                 # API routes
│   │   └── index.ts
│   ├── middleware/             # Middleware functions
│   │   └── index.ts
│   ├── services/               # Business logic
│   │   └── index.ts
│   └── utils/                  # Utility functions
│       └── index.ts
├── tests/                      # Test files
│   ├── unit/                   # Unit tests
│   │   └── index.test.ts
│   ├── integration/            # Integration tests
│   │   └── app.test.ts
│   └── setup.ts                # Test setup
├── docs/                       # Documentation
│   ├── api.md
│   └── deployment.md
└── examples/                   # Usage examples
    └── basic-usage.js
```

## Configuration

### Package.json
```json
{
  "name": "project-name",
  "version": "1.0.0",
  "description": "Project description",
  "main": "dist/index.js",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
    "build": "tsc",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/**/*.ts",
    "lint:fix": "eslint src/**/*.ts --fix",
    "format": "prettier --write src/**/*.ts",
    "format:check": "prettier --check src/**/*.ts",
    "type-check": "tsc --noEmit",
    "security:audit": "npm audit",
    "security:fix": "npm audit fix"
  },
  "keywords": [],
  "author": "Your Name <your.email@example.com>",
  "license": "MIT",
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  }
}
```

### TypeScript Configuration
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "removeComments": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### ESLint Configuration
```javascript
module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/explicit-function-return-type': 'warn',
    '@typescript-eslint/no-explicit-any': 'warn',
    'prefer-const': 'error',
    'no-var': 'error',
  },
};
```

## Development Workflow

### Setup Development Environment
```bash
# Install Node.js (use version specified in .nvmrc)
nvm use

# Initialize project
./scripts/setup.sh

# Install dependencies
npm install
```

### Daily Development
```bash
# Start development server
npm run dev

# Run tests
npm test

# Run linting
npm run lint

# Format code
npm run format

# Build project
npm run build

# Run all checks
./scripts/check-all.sh
```

### Package Management
```bash
# Add runtime dependency
npm install package-name
yarn add package-name
pnpm add package-name

# Add development dependency
npm install --save-dev package-name
yarn add --dev package-name
pnpm add --save-dev package-name
```

## Testing

### Jest Configuration
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.test.ts',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};
```

### Test Examples
```typescript
// tests/unit/index.test.ts
import { app } from '../../src/app';
import request from 'supertest';

describe('API Endpoints', () => {
  test('GET / should return 200', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
  });

  test('Health check endpoint', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'ok');
  });
});
```

## CI/CD Integration

This template integrates with the automation-infra CI/CD templates:

### GitHub Actions Workflow
- Uses `cicd-templates/examples/main-nodejs-deploy.yml`
- Automated testing and linting
- Security scanning
- Container building and deployment
- Performance testing

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
    uses: automation-infra/cicd-templates/.github/workflows/main-nodejs-deploy.yml@main
    with:
      node_version: "18"
      package_manager: "npm"
      project_name: "my-nodejs-project"
      run_tests: true
      run_e2e_tests: true
      run_security_scan: true
      deploy_to_registry: false
    secrets:
      HARBOR_USERNAME: ${{ secrets.HARBOR_USERNAME }}
      HARBOR_PASSWORD: ${{ secrets.HARBOR_PASSWORD }}
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Customization

### Framework-Specific Extensions

#### Express.js Extension
```bash
# Add Express dependencies
npm install express @types/express

# Update src/app.ts for Express
# Add middleware and routes
# Update tests for Express endpoints
```

#### NestJS Extension
```bash
# Install NestJS CLI
npm install -g @nestjs/cli

# Transform to NestJS project
nest new . --package-manager npm --skip-git
```

#### Next.js Extension
```bash
# Add Next.js dependencies
npm install next react react-dom

# Add Next.js scripts to package.json
# Update directory structure for Next.js
```

### Database Integration
```bash
# Add database dependencies (example: PostgreSQL)
npm install pg @types/pg
npm install --save-dev @types/pg

# Add TypeORM for ORM
npm install typeorm reflect-metadata
```

## Security

### Dependency Scanning
- Automated vulnerability scanning with `npm audit`
- License compliance checking
- Security advisories monitoring

### Code Security
- Static analysis with ESLint security plugins
- Secret detection
- SAST integration in CI/CD

### Security Configuration
```json
{
  "scripts": {
    "security:audit": "npm audit",
    "security:fix": "npm audit fix",
    "security:check": "npx audit-ci --config audit-ci.json"
  }
}
```

## Performance

### Load Testing
```javascript
// k6 load test example
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 },
    { duration: '5m', target: 10 },
    { duration: '2m', target: 0 },
  ],
};

export default function() {
  let response = http.get('http://localhost:3000/health');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
}
```

### Monitoring
- Application performance monitoring (APM)
- Health checks and metrics endpoints
- Logging configuration

## Deployment Options

### Container Deployment
```dockerfile
# Multi-stage build for Node.js application
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

WORKDIR /app

# Copy built application
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json

USER nextjs

EXPOSE 3000

CMD ["npm", "start"]
```

### Serverless Deployment
- AWS Lambda with Serverless Framework
- Vercel deployment for Next.js
- Google Cloud Functions support

## Best Practices

### Code Quality
- Follow TypeScript best practices
- Use meaningful variable and function names
- Write comprehensive tests
- Maintain high test coverage

### Project Organization
- Use barrel exports for clean imports
- Separate concerns with proper layering
- Follow consistent naming conventions
- Document complex business logic

### Performance
- Implement proper error handling
- Use connection pooling for databases
- Implement caching strategies
- Monitor application metrics

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
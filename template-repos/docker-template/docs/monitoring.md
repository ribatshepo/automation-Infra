# Docker Template Monitoring Guide

This guide covers monitoring, observability, and alerting for applications deployed using the Docker template.

## Overview

The Docker template includes a comprehensive monitoring stack:

- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboards
- **Application Metrics** - Custom application metrics
- **Log Aggregation** - Centralized logging
- **Health Checks** - Application and infrastructure health

## Prometheus Configuration

### Metrics Collection

Prometheus is configured to collect metrics from:

- Application endpoints (`/metrics`)
- Node exporter (system metrics)
- PostgreSQL exporter (database metrics)
- Redis exporter (cache metrics)
- Docker daemon metrics

### Configuration

Edit `config/prometheus/prometheus.yml` to add new targets:

```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

### Custom Metrics

Add custom metrics to your application:

```javascript
const prometheus = require('prom-client');

// Counter example
const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'status_code']
});

// Histogram example
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route']
});

// Usage in middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    httpRequestsTotal.labels(req.method, res.statusCode).inc();
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path)
      .observe((Date.now() - start) / 1000);
  });
  
  next();
});
```

## Grafana Dashboards

### Access

- URL: http://localhost:3001
- Username: admin
- Password: admin (change in production)

### Pre-configured Dashboards

1. **Application Overview**
   - Request rate and response times
   - Error rates and status codes
   - Resource utilization

2. **Infrastructure Metrics**
   - CPU and memory usage
   - Disk I/O and network traffic
   - Container statistics

3. **Database Metrics**
   - Connection pool status
   - Query performance
   - Database size and growth

### Creating Custom Dashboards

1. Navigate to Grafana UI
2. Click "+" → "Dashboard"
3. Add panels with Prometheus queries
4. Configure visualization options
5. Save dashboard

Example queries:

```promql
# Request rate
rate(http_requests_total[5m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m])

# Memory usage
container_memory_usage_bytes{name="app"}

# CPU usage
rate(container_cpu_usage_seconds_total{name="app"}[5m]) * 100
```

## Health Checks

### Application Health

The template provides multiple health check endpoints:

```javascript
// Basic health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    environment: process.env.NODE_ENV
  });
});

// Detailed health check
app.get('/health/detailed', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
    external_api: await checkExternalAPI()
  };
  
  const allHealthy = Object.values(checks).every(check => check.healthy);
  
  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? 'healthy' : 'unhealthy',
    checks: checks,
    timestamp: new Date().toISOString()
  });
});
```

### Infrastructure Health

Docker health checks:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh
```

Kubernetes health checks:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Logging

### Log Configuration

Structured logging with correlation IDs:

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/app.log' })
  ]
});

// Add correlation ID middleware
app.use((req, res, next) => {
  req.correlationId = req.headers['x-correlation-id'] || generateId();
  res.setHeader('x-correlation-id', req.correlationId);
  next();
});

// Logging with correlation ID
app.use((req, res, next) => {
  logger.info('Request received', {
    correlationId: req.correlationId,
    method: req.method,
    url: req.url,
    userAgent: req.get('User-Agent')
  });
  next();
});
```

### Log Aggregation

For production, consider using:

- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Fluentd** with Elasticsearch
- **Loki** with Grafana
- **Splunk** for enterprise environments

Example Fluentd configuration:

```yaml
# fluentd.conf
<source>
  @type forward
  port 24224
</source>

<match docker.**>
  @type elasticsearch
  host elasticsearch
  port 9200
  index_name docker_logs
  type_name docker
</match>
```

## Alerting

### Prometheus Alerting Rules

Create alerting rules in `config/prometheus/alerts.yml`:

```yaml
groups:
  - name: application_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s"

      - alert: DatabaseDown
        expr: up{job="postgres"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Database is down"
          description: "PostgreSQL database is not responding"

      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes{name="app"} / container_memory_max_usage_bytes{name="app"} > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Container memory usage is {{ $value | humanizePercentage }}"
```

### Notification Channels

Configure Grafana notification channels:

1. **Slack Integration**
```json
{
  "channel": "#alerts",
  "webhook_url": "https://hooks.slack.com/services/...",
  "title": "Grafana Alert",
  "text": "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}"
}
```

2. **Email Notifications**
```yaml
smtp:
  host: smtp.gmail.com:587
  user: alerts@company.com
  password: app_password
  from_address: alerts@company.com
```

3. **PagerDuty Integration**
```json
{
  "integration_key": "your_integration_key",
  "severity": "error",
  "client": "Grafana",
  "client_url": "{{ .ExternalURL }}"
}
```

## Performance Monitoring

### Application Performance Monitoring (APM)

Integrate with APM tools:

```javascript
// New Relic
require('newrelic');

// DataDog
const tracer = require('dd-trace').init();

// Elastic APM
const apm = require('elastic-apm-node').start({
  serviceName: 'my-docker-app',
  serverUrl: 'http://apm-server:8200'
});
```

### Database Monitoring

Monitor database performance:

```yaml
# PostgreSQL exporter
postgres_exporter:
  image: prometheuscommunity/postgres-exporter
  environment:
    DATA_SOURCE_NAME: "postgresql://user:password@postgres:5432/database?sslmode=disable"
  ports:
    - "9187:9187"
```

### Custom Monitoring Scripts

Create monitoring scripts:

```bash
#!/bin/bash
# monitor.sh - Custom monitoring script

# Check application health
if ! curl -f http://localhost:3000/health >/dev/null 2>&1; then
  echo "Application health check failed"
  # Send alert
fi

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
  echo "Disk usage is ${DISK_USAGE}%"
  # Send alert
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ "$MEMORY_USAGE" -gt 80 ]; then
  echo "Memory usage is ${MEMORY_USAGE}%"
  # Send alert
fi
```

## Security Monitoring

### Security Events

Monitor security-related events:

```javascript
// Failed login attempts
app.post('/login', (req, res) => {
  // Authentication logic
  if (!authenticated) {
    logger.warn('Failed login attempt', {
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      username: req.body.username,
      timestamp: new Date().toISOString()
    });
  }
});

// Suspicious activity
app.use((req, res, next) => {
  if (isSuspiciousRequest(req)) {
    logger.warn('Suspicious request detected', {
      ip: req.ip,
      path: req.path,
      method: req.method,
      headers: req.headers
    });
  }
  next();
});
```

### Vulnerability Monitoring

Regular security scans:

```bash
# Trivy scan
trivy image my-app:latest

# OWASP dependency check
npm audit

# Docker bench security
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  docker/docker-bench-security
```

## Troubleshooting Monitoring

### Common Issues

1. **Metrics not appearing**: Check Prometheus targets and service discovery
2. **Grafana dashboard empty**: Verify data source configuration
3. **Alerts not firing**: Check alerting rules and notification channels
4. **High cardinality metrics**: Limit label values and use recording rules

### Debug Commands

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Query Prometheus metrics
curl http://localhost:9090/api/v1/query?query=up

# Check Grafana health
curl http://localhost:3001/api/health

# View application metrics
curl http://localhost:3000/metrics
```
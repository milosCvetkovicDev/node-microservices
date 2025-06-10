# Troubleshooting Guide

This comprehensive guide helps you diagnose and resolve common issues in the Node.js Microservices application.

## 🔍 Quick Diagnostics

### System Health Check

Run this command to get a quick system overview:

```bash
# Check all services status
kubectl get pods -n default

# Check service logs
kubectl logs -n default -l app=microservices --tail=50

# Check resource usage
kubectl top pods -n default

# Check database connectivity
kubectl exec -it deployment/user-service -- npm run db:ping
```

## 🚨 Common Issues and Solutions

### 1. Service Won't Start

#### Symptoms
- Service pods in `CrashLoopBackOff` or `Error` state
- Container exits immediately after starting
- No logs available

#### Diagnosis
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check container logs
kubectl logs <pod-name> -c <container-name> --previous

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

#### Solutions

**A. Environment Variables Missing**
```bash
# Check if all required env vars are set
kubectl exec <pod-name> -- env | grep -E "DATABASE_URL|REDIS_URL|JWT_SECRET"

# Fix: Update ConfigMap or Secrets
kubectl edit configmap app-config
kubectl edit secret app-secrets
```

**B. Database Connection Failed**
```bash
# Test database connectivity
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql postgresql://user:pass@postgres:5432/dbname

# Common fixes:
# 1. Check database credentials
# 2. Verify network policies
# 3. Ensure database is running
```

**C. Port Already in Use**
```yaml
# Check for port conflicts in service definitions
# Fix: Update deployment.yaml
spec:
  containers:
  - name: service
    ports:
    - containerPort: 3001  # Ensure unique ports
```

### 2. Database Issues

#### Symptoms
- "Connection refused" errors
- "Database does not exist" errors
- Slow queries or timeouts

#### Diagnosis
```bash
# Check PostgreSQL status
kubectl exec -it postgres-0 -- pg_isready

# Check active connections
kubectl exec -it postgres-0 -- psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Check slow queries
kubectl exec -it postgres-0 -- psql -U postgres -c "SELECT query, state, waiting, query_start FROM pg_stat_activity WHERE state != 'idle' ORDER BY query_start;"
```

#### Solutions

**A. Connection Pool Exhausted**
```typescript
// Increase pool size in database config
const pool = new Pool({
  max: 20, // Increase from default 10
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

**B. Migration Issues**
```bash
# Reset migrations
kubectl exec -it deployment/user-service -- npm run prisma:reset

# Apply migrations manually
kubectl exec -it deployment/user-service -- npm run prisma:migrate:deploy
```

**C. Performance Issues**
```sql
-- Check missing indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, tablename;

-- Add missing indexes
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

### 3. Authentication Failures

#### Symptoms
- 401 Unauthorized errors
- "Invalid token" responses
- Users can't log in

#### Diagnosis
```bash
# Check Auth Service logs
kubectl logs -l app=auth-service --tail=100 | grep ERROR

# Verify JWT secret is set
kubectl get secret app-secrets -o jsonpath="{.data.JWT_SECRET}" | base64 -d

# Check Redis connection
kubectl exec -it deployment/auth-service -- redis-cli ping
```

#### Solutions

**A. JWT Secret Mismatch**
```bash
# Ensure all services use the same JWT secret
# Update secret in all namespaces
kubectl create secret generic app-secrets \
  --from-literal=JWT_SECRET="your-secret" \
  --dry-run=client -o yaml | kubectl apply -f -
```

**B. Token Expiration Issues**
```typescript
// Adjust token expiration in auth service
const token = jwt.sign(payload, secret, {
  expiresIn: '24h', // Increase from default
});
```

**C. Redis Session Issues**
```bash
# Clear Redis cache
kubectl exec -it redis-master-0 -- redis-cli FLUSHDB

# Check Redis memory
kubectl exec -it redis-master-0 -- redis-cli INFO memory
```

### 4. API Gateway Issues

#### Symptoms
- 502 Bad Gateway errors
- Timeouts on API calls
- Incorrect routing

#### Diagnosis
```bash
# Check Gateway logs
kubectl logs -l app=api-gateway --tail=100

# Test service discovery
kubectl exec -it deployment/api-gateway -- nslookup user-service

# Check route configuration
kubectl exec -it deployment/api-gateway -- cat /app/config/routes.json
```

#### Solutions

**A. Service Discovery Failed**
```yaml
# Ensure services have correct labels
metadata:
  labels:
    app: user-service
    version: v1
spec:
  selector:
    app: user-service
```

**B. Timeout Configuration**
```typescript
// Increase timeout in gateway config
app.use('/api/users', createProxyMiddleware({
  target: 'http://user-service:3001',
  timeout: 30000, // 30 seconds
  proxyTimeout: 30000,
}));
```

### 5. Kubernetes Deployment Issues

#### Symptoms
- Pods stuck in Pending state
- Image pull errors
- Resource quota exceeded

#### Diagnosis
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name>

# Check resource quotas
kubectl get resourcequota
```

#### Solutions

**A. Insufficient Resources**
```yaml
# Adjust resource requests/limits
resources:
  requests:
    memory: "256Mi"  # Reduce if needed
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

**B. Image Pull Errors**
```bash
# Check image pull secrets
kubectl get secret regcred -o yaml

# Create new pull secret
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass
```

### 6. Performance Issues

#### Symptoms
- Slow response times
- High CPU/memory usage
- Request timeouts

#### Diagnosis
```bash
# Check resource usage
kubectl top pods
kubectl top nodes

# Check application metrics
curl http://service:3001/metrics

# Profile Node.js application
kubectl exec -it <pod-name> -- node --inspect=0.0.0.0:9229 app.js
```

#### Solutions

**A. Memory Leaks**
```typescript
// Add memory monitoring
if (global.gc) {
  setInterval(() => {
    global.gc();
    console.log('Memory usage:', process.memoryUsage());
  }, 60000);
}
```

**B. CPU Optimization**
```yaml
# Enable Node.js clustering
replicas: 4  # Match CPU cores
env:
- name: NODE_OPTIONS
  value: "--max-old-space-size=512"
```

### 7. Networking Issues

#### Symptoms
- Service-to-service communication fails
- External API calls timeout
- DNS resolution errors

#### Diagnosis
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check network policies
kubectl get networkpolicies

# Test connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- curl http://user-service:3001/health
```

#### Solutions

**A. DNS Issues**
```yaml
# Add DNS config to deployment
dnsPolicy: ClusterFirst
dnsConfig:
  options:
  - name: ndots
    value: "2"
  - name: edns0
```

**B. Network Policy Blocking**
```yaml
# Allow service communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-services
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
```

## 🛠 Debugging Tools

### 1. Debug Container

```bash
# Run debug container
kubectl run -it --rm debug --image=node:20-alpine --restart=Never -- sh

# Install debugging tools
apk add --no-cache curl postgresql-client redis

# Test connections
curl http://user-service:3001/health
psql postgresql://user:pass@postgres:5432/dbname
redis-cli -h redis ping
```

### 2. Port Forwarding

```bash
# Forward service port to local
kubectl port-forward service/user-service 3001:3001

# Test locally
curl http://localhost:3001/health
```

### 3. Exec into Container

```bash
# Get shell access
kubectl exec -it deployment/user-service -- sh

# Run diagnostic commands
npm run test:connection
cat /proc/1/status | grep -i memory
netstat -tulpn
```

## 📊 Monitoring Commands

### Logs Analysis

```bash
# Get logs with timestamps
kubectl logs -l app=user-service --timestamps=true

# Follow logs in real-time
kubectl logs -f deployment/api-gateway

# Get logs from all containers
kubectl logs -l app=microservices --all-containers=true

# Export logs for analysis
kubectl logs -l app=microservices --since=1h > logs.txt
```

### Metrics Collection

```bash
# Get Prometheus metrics
curl http://localhost:3001/metrics | grep -E "http_request_duration|memory_usage"

# Check Grafana dashboards
kubectl port-forward -n monitoring service/grafana 3000:80
```

## 🔧 Recovery Procedures

### 1. Service Recovery

```bash
# Restart deployment
kubectl rollout restart deployment/user-service

# Scale to zero and back
kubectl scale deployment/user-service --replicas=0
kubectl scale deployment/user-service --replicas=3
```

### 2. Database Recovery

```bash
# Backup database
kubectl exec -it postgres-0 -- pg_dump -U postgres dbname > backup.sql

# Restore database
kubectl exec -i postgres-0 -- psql -U postgres dbname < backup.sql
```

### 3. Clear Cache

```bash
# Clear Redis cache
kubectl exec -it redis-master-0 -- redis-cli FLUSHALL

# Clear application cache
kubectl exec -it deployment/api-gateway -- rm -rf /tmp/cache/*
```

## 📝 Troubleshooting Checklist

Before escalating issues, check:

- [ ] All environment variables are set correctly
- [ ] Database is accessible and migrations are applied
- [ ] Redis is running and accessible
- [ ] All required secrets are created
- [ ] Network policies allow communication
- [ ] Resource limits are not exceeded
- [ ] No recent deployments that could cause issues
- [ ] Health check endpoints return 200 OK
- [ ] Logs don't show critical errors
- [ ] Monitoring dashboards show normal metrics

## 🆘 Escalation Path

If issues persist after following this guide:

1. **Level 1**: Check #microservices-help Slack channel
2. **Level 2**: Contact DevOps team (oncall@example.com)
3. **Level 3**: Page infrastructure team lead
4. **Critical**: Initiate incident response procedure

## 📚 Additional Resources

- [Kubernetes Debugging Guide](https://kubernetes.io/docs/tasks/debug/)
- [Node.js Debugging](https://nodejs.org/en/docs/guides/debugging-getting-started/)
- [PostgreSQL Troubleshooting](https://wiki.postgresql.org/wiki/Troubleshooting)
- [Redis Troubleshooting](https://redis.io/docs/manual/troubleshooting/)

---

**Last Updated**: January 2024
**Version**: 1.0.0
**Maintainer**: DevOps Team

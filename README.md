# Multi-Application Helm Chart

A comprehensive Helm chart designed for deploying and managing multiple microservices applications across different Kubernetes environments with consistent configuration and operational best practices.

## Overview

This Helm chart provides a flexible, scalable solution for deploying complex microservices architectures. It supports multiple application types including web services, user interfaces, and background workers, all managed through a unified configuration system.

## Architecture

### Chart Structure

```
.
├── Chart.yaml                 # Chart metadata and version
├── values/                    # Environment-specific configurations
│   ├── integration-values.yaml
│   ├── qa-values.yaml
│   └── prod-values.yaml
├── templates/                 # Kubernetes resource templates
│   ├── _helpers.tpl          # Template helper functions
│   ├── app-deployments.yaml  # Application deployments
│   ├── app-services.yaml     # Service definitions
│   ├── hpa.yaml              # Horizontal Pod Autoscalers
│   ├── ingress.yaml          # Ingress routing
│   ├── rbac/                 # RBAC resources
│   └── tests/                # Helm tests
└── charts/                   # Dependency charts (if any)
```

### Application Types

The chart supports three main application patterns:

1. **Web Services**: Backend API services with HTTP/gRPC endpoints
2. **User Interfaces**: Frontend applications serving web content
3. **Background Workers**: Asynchronous task processors and schedulers

## Features

### 🚀 Multi-Environment Support
- Environment-specific configurations
- Namespace isolation
- Different resource allocations per environment
- Environment-specific ingress routing

### 📈 Auto-Scaling & Resource Management
- Horizontal Pod Autoscaling (HPA) with CPU and memory metrics
- Configurable resource requests and limits
- Startup probes for application health checks
- Rolling update strategies with zero downtime

### 🔒 Security & RBAC
- Role-Based Access Control (RBAC) setup
- Service account management
- Secret management for environment variables
- Container image pull secrets

### 🌐 Networking & Ingress
- Centralized ingress configuration
- TLS termination support
- Multiple service types (ClusterIP, NodePort, LoadBalancer)
- gRPC and HTTP service support

### 🔧 Operational Excellence
- Configurable startup and readiness probes
- Resource monitoring and limits
- Logging and debugging capabilities
- Helm test integration

## Configuration

### Global Configuration

```yaml
global:
  namespace: your-namespace
  image:
    registry: your-registry.com
    repository: your-org
    pullPolicy: Always
  imagePullSecrets:
    - name: registry-secret
```

### Application Configuration

Each application in the `apps` array supports the following configuration:

```yaml
apps:
  - name: service-name
    namespace: optional-override-namespace
    app: kubernetes-app-label
    replicas: 2
    
    # Container Configuration
    imageName: container-image-name
    tag: image-tag
    command: ["custom", "command"]  # Optional
    
    # Networking
    ports:
      port: 8080
      targetPort: 8080
      grpcPort: 50051        # Optional gRPC port
      grpcNodePort: 30051    # Optional NodePort for gRPC
    
    # Health Checks
    startupProbe:
      enabled: true
      initialDelaySeconds: 60
      periodSeconds: 10
    
    # Resources
    resources:
      enabled: true
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"
    
    # Environment Variables
    envFrom: secret-name     # Kubernetes secret name
    env: []                  # Additional environment variables
    
    # Service Configuration
    service:
      type: ClusterIP        # ClusterIP, NodePort, LoadBalancer
    
    # Auto-scaling
    hpa:
      enabled: false
      minReplicas: 2
      maxReplicas: 10
      targetCPUUtilizationPercentage: 80
      targetMemoryUtilizationPercentage: 80
```

### Ingress Configuration

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
  
  rules:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
          backend:
            service: api-service
            port: 8080
  
  tls:
    - hosts:
        - api.example.com
      secretName: tls-secret
```

### RBAC Configuration

```yaml
rbac:
  enabled: true
  serviceAccountName: app-service-account
  roleName: app-role
  roleBindingName: app-role-binding
  tokenSecretName: app-token
  group: app-users
```

## Deployment

### Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.x
- kubectl configured with cluster access
- Container registry access (if using private images)

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd helm-chart
   ```

2. **Customize values for your environment:**
   ```bash
   cp integration-values.yaml my-values.yaml
   # Edit my-values.yaml with your configuration
   ```

3. **Deploy to Kubernetes:**
   ```bash
   # Install new deployment
   helm install my-release . -f my-values.yaml
   
   # Upgrade existing deployment
   helm upgrade my-release . -f my-values.yaml
   ```

### Environment-Specific Deployments

```bash
# Integration Environment
helm upgrade --install app-int . -f integration-values.yaml

# QA Environment
helm upgrade --install app-qa . -f qa-values.yaml

# Production Environment
helm upgrade --install app-prod . -f prod-values.yaml
```

## Validation & Testing

### Helm Tests

Run built-in connectivity tests:
```bash
helm test my-release
```

### Validation Commands

```bash
# Validate template rendering
helm template . -f my-values.yaml

# Dry run deployment
helm upgrade --install --dry-run my-release . -f my-values.yaml

# Check deployment status
kubectl get pods,services,ingress -n your-namespace
```

## Monitoring & Troubleshooting

### Health Checks

- Startup probes ensure containers are ready before receiving traffic
- HPA monitors CPU and memory usage for automatic scaling
- Resource limits prevent resource exhaustion

### Common Commands

```bash
# View pod logs
kubectl logs -f deployment/service-name -n namespace

# Check HPA status
kubectl get hpa -n namespace

# View ingress status
kubectl describe ingress -n namespace

# Check RBAC permissions
kubectl auth can-i --list --as=system:serviceaccount:namespace:service-account
```

### Debugging

1. **Pod Issues:**
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace>
   ```

2. **Service Connectivity:**
   ```bash
   kubectl port-forward service/<service-name> 8080:8080 -n <namespace>
   ```

3. **Ingress Issues:**
   ```bash
   kubectl describe ingress <ingress-name> -n <namespace>
   ```

## Best Practices

### Security
- Use specific image tags instead of `latest`
- Configure resource limits to prevent resource exhaustion
- Enable RBAC with minimal required permissions
- Store sensitive data in Kubernetes secrets

### Performance
- Set appropriate resource requests and limits
- Configure HPA based on actual usage patterns
- Use rolling updates for zero-downtime deployments
- Monitor startup times and adjust probe timings

### Maintenance
- Regularly update container images
- Monitor resource usage and adjust limits
- Keep Helm chart dependencies updated
- Use semantic versioning for releases

## Advanced Configuration

### Custom Resource Management

For applications requiring special handling:

```yaml
# Disable resource management for specific apps
resources:
  enabled: false

# Custom startup probe configuration
startupProbe:
  enabled: true
  initialDelaySeconds: 120
  periodSeconds: 30
```

### Background Workers

For worker applications that don't need services:

```yaml
apps:
  - name: worker-app
    # ... other config
    service: null          # No service creation
    ports: []             # No ports needed
    command: ["worker", "start"]
```

### Multi-Port Services

For applications exposing multiple ports:

```yaml
ports:
  port: 8080              # Primary HTTP port
  targetPort: 8080
  grpcPort: 50051         # Additional gRPC port
  grpcNodePort: 30051     # NodePort for external gRPC access
```

## Contributing

1. Follow Kubernetes and Helm best practices
2. Test changes across all environment configurations
3. Update documentation for any new features
4. Validate templates with `helm lint`

## Support

For issues and questions:
- Check the troubleshooting section
- Review Kubernetes and Helm documentation
- Validate configuration with dry-run deployments

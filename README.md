# Multi-Application Helm Chart

A comprehensive Helm chart designed for deploying and managing multiple microservices applications across different Kubernetes environments with consistent configuration and operational best practices.

## Overview

This Helm chart provides a flexible, scalable solution for deploying complex microservices architectures. It supports multiple application types including web services, user interfaces, and background workers, all managed through a unified configuration system using modern Kubernetes standards like the Gateway API.

## Architecture

### Chart Structure

```
├── appsphere
│   ├── Chart.yaml
│   ├── templates
│   │   ├── app-deployments.yaml
│   │   ├── app-services.yaml
│   │   ├── gateway-client-setting.yaml
│   │   ├── gateway.yaml
│   │   ├── _helpers.tpl
│   │   ├── hpa.yaml
│   │   ├── http-redirect.yaml
│   │   ├── http-route.yaml
│   │   ├── NOTES.txt
│   │   ├── pdb.yaml
│   │   ├── rbac-sa-token.yaml
│   │   ├── rolebinding.yaml
│   │   ├── role.yaml
│   │   ├── serviceaccount.yaml
│   │   └── tests
│   │       └── test-connection.yaml
│   ├── values
│   │   ├── integration-values.yaml
│   │   ├── prod-values.yaml
│   │   └── qa-values.yaml
│   └── values.yaml
├── GATEWAY.md
├── BLUE_GREEN.md
└── README.md
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

### 🌐 Networking & Gateway API
- Modern **Gateway API** implementation (replacing legacy Ingress)
- Centralized `Gateway` configuration
- `HTTPRoute` for flexible routing rules
- Multi-listener support (HTTP/HTTPS)
- **Automatic HTTP to HTTPS Redirection**
- **Blue-Green & Canary Deployments** via weighted traffic shifting
- **Advanced Proxy Settings** (e.g., Request Body Size)
- TLS termination

### 📈 Auto-Scaling & Resource Management
- **Horizontal Pod Autoscaling (HPA)** with CPU and memory metrics
- **Pod Disruption Budgets (PDB)** for high availability
- Configurable resource requests and limits
- Startup, Liveness, and Readiness probes

### 🔒 Security & RBAC
- Role-Based Access Control (RBAC) setup
- Service account management
- Auto-generated tokens
- Security Context configuration (Pod and Container levels)
- Container image pull secrets

### 🔧 Operational Excellence
- Configurable probes
- Resource monitoring and limiting
- Helm test integration
- Standardized labels and metadata

## Configuration

### Global Configuration

Define shared settings across all applications:

```yaml
global:
  namespace: demo
  image:
    registry: docker.io
    repository: your-org
    pullPolicy: Always
  imagePullSecrets: []
```

### Application Configuration

Configure individual applications in the `apps` list:

```yaml
apps:
  - name: my-service
    namespace: demo
    app: my-app-label
    replicas: 1
    
    # Image Details
    imageName: my-service-image
    tag: v1.0.0
    
    # Networking
    ports:
      port: 80
      targetPort: 8080
      nodePort: 30080      # Optional
      grpcPort: 50051      # Optional
      grpcTargetPort: 50051
    
    # Probes
    livenessProbe:
      httpGet:
        path: /health
        port: 80
      initialDelaySeconds: 15
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
    
    # Resources
    resources:
      enabled: true
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
    
    # Security
    podSecurityContext:
      runAsUser: 1000
    securityContext:
      readOnlyRootFilesystem: true
    
    # Autoscaling (HPA)
    hpa:
      enabled: true
      minReplicas: 2
      maxReplicas: 5
      targetCPUUtilizationPercentage: 80
      targetMemoryUtilizationPercentage: 80

    # Availability (PDB)
    pdb:
      enabled: true
      minAvailable: 1
```

### Gateway Configuration

Configure ingress traffic using the Gateway API:

```yaml
gateway:
  enabled: true
  name: gateway
  namespace: demo
  
  # Advanced Proxy Settings (optional)
  clientSettings:
    enabled: true
    name: gateway-client-settings
    maxSize: "50"  # Maximum allowed request body size
  
  listeners:
    - host: api.example.com
      port: 443
      protocol: HTTPS
      tls: tls-secret-name
      sslRedirect: true  # Automatically redirect HTTP to HTTPS
      routes:
        - path: /v1
          pathType: PathPrefix
          backend:
            service: my-service
            port: 80
        - path: /grpc
          pathType: PathPrefix
          backend:
            service: grpc-service
            port: 50051
```

### RBAC Configuration

Manage permissions and service accounts:

```yaml
rbac:
  enabled: true
  serviceAccountName: rbac-sa
  roleName: rbac-role
  roleBindingName: rbac-binding
  tokenSecretName: rbac-token
  group: devusers
```

## Deployment

### Prerequisites
- Kubernetes cluster (v1.24+) with Gateway API CRDs installed
- Helm 3.x
- `kubectl` configured

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd helm-template
   ```

2. **Customize values:**
   Use the provided environment files as templates:
   - `appsphere/integration-values.yaml`
   - `appsphere/qa-values.yaml`
   - `appsphere/prod-values.yaml`

3. **Deploy to Kubernetes:**

   ```bash
   # Deploy using default values
   helm install my-release ./appsphere
   
   # Deploy/Upgrade using specific environment values
   helm upgrade --install my-app ./appsphere -f appsphere/qa-values.yaml
   ```

## Validation & Testing

### Helm Tests
Run connection tests defined in the chart:
```bash
helm test my-app
```

### Verify Resources
```bash
# Check Gateway Status
kubectl get gateway -n demo

# Check HTTP Routes
kubectl get httproute -n demo

# Check HPA
kubectl get hpa -n demo
```

## Troubleshooting

- **Gateway Not Ready**: Ensure Gateway API CRDs are installed on your cluster.
- **Routes Not Matching**: Verify the `host` in `listeners` matches exactly (or check for wildcard support). Ensure the `backend.service` matches the `name` defined in your `apps` list.
- **Pod Scheduling Failed**: Check resource quotas and `resources` requests in `values.yaml`.

## Best Practices

- **Tagging**: Avoid using `latest` tags in production.
- **Resource Limits**: Always set `resources` for critical apps to ensure QoS.
- **Probes**: Configure `readinessProbe` to prevent traffic to unready pods.
- **Security**: Run containers as non-root users using `securityContext`.

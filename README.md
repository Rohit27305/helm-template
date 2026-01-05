# 🚀 AppSphere: Enterprise Multi-Application Helm Chart

[![Helm Version](https://img.shields.io/badge/helm-v3.x-blue.svg)](https://helm.sh/)
[![Kubernetes Version](https://img.shields.io/badge/kubernetes-v1.24+-green.svg)](https://kubernetes.io/)
[![Gateway API](https://img.shields.io/badge/Networking-Gateway%20API-orange.svg)](https://gateway-api.sigs.k8s.io/)

A professional-grade Helm chart designed for deploying and managing complex microservices architectures across diverse environments with consistency, security, and high availability.

---

## 📖 Internal Documentation

Click on the links below to access detailed guides for specific features:

| Guide | Description |
| :--- | :--- |
| 🌐 [**Gateway Guide**](GATEWAY.md) | Architecture and setup for modern Gateway API networking. |
| 🔄 [**Blue-Green/Canary**](BLUE_GREEN.md) | Zero-downtime deployment strategies and traffic shifting. |
| 🔒 [**RBAC Strategy**](RBAC.md) | Granular permission management with dual-ServiceAccounts. |
| 📈 [**Autoscaling (HPA)**](HPA.md) | Dynamic scaling requirements and Metrics Server setup. |
| 📜 [**Chart Rules**](CHART_RULES.md) | Mandatory technical requirements and Golden Rules. |

---

## 🏗️ Chart Structure

```text
├── Chart.yaml
├── templates
│   ├── app-deployments.yaml
│   ├── app-services.yaml
│   ├── gateway-client-setting.yaml
│   ├── gateway.yaml
│   ├── _helpers.tpl
│   ├── hpa.yaml
│   ├── http-redirect.yaml
│   ├── http-route.yaml
│   ├── NOTES.txt
│   ├── pdb.yaml
│   ├── rbac-cluster.yaml
│   ├── rbac-namespace.yaml
│   ├── serviceaccount.yaml
│   └── tests
│       └── test-connection.yaml
├── values
│   ├── int-values.yaml
│   ├── prd-values.yaml
│   └── qa-values.yaml
└── values.yaml
```

---

## ✨ Core Features

### 🌍 Networking & Traffic Management
*   **Gateway API First**: Built-in support for the standard Gateway API (NGINX/Istio ready).
*   **Intelligent Routing**: Path-based matching, header manipulation, and weighted traffic.
*   **HTTPS Always**: Automatic SSL/TLS termination and HTTP-to-HTTPS redirection.

### 🛡️ Enterprise Security
*   **Dual-SA RBAC**: Separate identities for Namespace and Cluster-level permissions.
*   **Hardened Pods**: Configurable Pod/Container SecurityContexts for least privilege.
*   **Secret Management**: Native support for image pull secrets and token generation.

### � Scalability & Robustness
*   **HPA Integration**: Automated scaling based on CPU utilization (Metrics Server required).
*   **Blue-Green Native**: Native support for zero-downtime rollouts via `blue` and `green` slots.
*   **High Availability**: Pod Disruption Budgets (PDB) ensure availability during maintenance.

---

## ⚙️ Configuration Overview

### 1. Global Settings
Define shared attributes across all services:
```yaml
global:
  namespace: demo
  image:
    registry: docker.io
    repository: your-org
```

### 2. Application Definition
Configure independent microservices using a dictionary-based structure for safe `helm upgrade --set` operations.

```yaml
apps:
  myService:
    name: my-app-name      # Required: Strict resource naming
    replicas: 2
    imageName: my-api
    tag: v1.2.3            # Required: No global fallbacks
    
    # Resources & Auto-scaling
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
    hpa:
      enabled: true
      minReplicas: 2
      maxReplicas: 10
      targetCPUUtilizationPercentage: 70

    # Networking
    ports:
      port: 80
      targetPort: 8080

    # Probes
    startupProbe:
      httpGet:
        path: /health
        port: 80
    livenessProbe:
      httpGet:
        path: /health
        port: 80
    readinessProbe:
      httpGet:
        path: /ready
        port: 80

    # Security
    podSecurityContext:
      runAsUser: 1000
    securityContext:
      readOnlyRootFilesystem: true
      runAsNonRoot: true
```

---

## 🛠️ Operational Toolset

The chart includes automation scripts in the root `scripts/` folder to simplify management:

| Script | Function |
| :--- | :--- |
| `generate-kubeconfig.sh` | Generates a standalone Kubeconfig for any ServiceAccount. |
| `setup-user.sh` | Automates Linux user creation and Kubeconfig provisioning. |

---

## 🚀 Getting Started

### Prerequisites
*   **Helm 3.x** and **Kubectl** installed.
*   Kubernetes cluster with **Gateway API CRDs** managed by a controller (e.g., NGINX).

### Deployment Workflow
```bash
# 1. Install using a specific environment overlay
helm upgrade --install my-release ./appsphere -f appsphere/values/qa-values.yaml

# 2. Verify deployments
kubectl get pods -n qa

# 3. Run integrated connectivity tests
helm test my-release -n qa
```

---

## 💡 Best Practices & Recommendations

> [!IMPORTANT]
> **Strict Naming**: Always define `app.name` and `app.tag` for every service. The chart relies on these for consistent labeling and image resolution.

*   **Resources**: Always define `requests` for CPU to enable the HPA functionality.
*   **BG Weights**: In Blue-Green mode, manage weights directly in the `gateway` section. Note that the **Blue** slot shares the base `app.name` to ensure NodePort stability and prevent allocation conflicts.
*   **Map-Based Logic**: Use map keys (e.g., `--set gateway.listeners.primary.routes.http...`) instead of index-based arrays to prevent configuration wipes and enable deep merging.

---

## 🆘 Troubleshooting

*   **Gateway Issues**: Run `kubectl describe gateway` to check for `Programmed: True`.
*   **HPA Not Scaling**: Ensure the **Metrics Server** is reporting pods via `kubectl top pods`.
*   **Image Pull Errors**: Verify `global.imagePullSecrets` if using a private registry.

---
© 2026 AppSphere Ops Team. Powered by Kubernetes Gateway API.

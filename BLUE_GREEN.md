# 🔄 AppSphere: Blue-Green & Canary Deployment Strategy

This guide explains the implementation and operational workflows for **zero-downtime** deployments in the AppSphere chart, utilizing weighted traffic shifting via the Kubernetes Gateway API.

---

## ✨ Strategy Overview

The chart maintains two parallel environments, **Blue** (Stable) and **Green** (New/Canary). Instead of a destructive "all-or-nothing" switch, we use weights in the Gateway API to control traffic distribution on the **same endpoint**.

*   🔵 **Blue**: The verified, stable version currently serving production traffic.
*   🟢 **Green**: The candidate version being tested or gradually rolled out.

---

## ⚙️ Configuration

Blue-Green settings are managed per-application in `values.yaml`.

```yaml
apps:
  demo:
    name: demo
    imageName: test-app
    tag: v1.0.0            # Default tag

    blueGreen:
      enabled: true
      blue:
        tag: v1.0.0        # Current Live
      green:
        tag: v2.0.0        # New Candidate
```

> [!NOTE]
> **NodePort Handling**: To prevent conflicts, the **blue** slot uses the static `nodePort` from your configuration, while the **green** slot is **auto-assigned** a random host port by Kubernetes.

---

1.  **Dual Deployments**: Two distinct deployments are created:
    *   🔵 **Blue**: Shares the base application name (`demo`) to ensure smooth transition and persistent NodePorts.
    *   🟢 **Green**: Named with a suffix (`demo-green`) for side-by-side testing.
2.  **Dedicated Services**: Both slots receive unique internal services for direct testing.
3.  **Gateway API Integration**: The `HTTPRoute` leverages `backendRefs` with weights to split incoming traffic.
4.  **Conditional Rendering**: The chart automatically skips "green" backends in the `HTTPRoute` if Blue-Green is disabled for that specific app.

---

## 🚀 Production Workflow (Manual)

### 1. Deploy to Inactive Slot
Deploy the new version to Green while Blue serves 100% of traffic.
```bash
helm upgrade my-release ./appsphere \
  --set apps.demo.blueGreen.enabled=true \
  --set apps.demo.blueGreen.green.tag=v2.0.0
```

### 2. Gradual Canary Rollout
Shift 10% of users to the new version to monitor stability.
```bash
# Set weights: Blue=90, Green=10
helm upgrade my-release ./appsphere \
  --set apps.demo.blueGreen.enabled=true \
  --set gateway.listeners.demo.routes.http.backendRefs.primary.weight=90 \
  --set gateway.listeners.demo.routes.http.backendRefs.green.weight=10 \
  --set gateway.listeners.demo.routes.grpc.backendRefs.primary.weight=90 \
  --set gateway.listeners.demo.routes.grpc.backendRefs.green.weight=10
```

### 3. Full Cutover
Switch 100% of traffic to Green.
```bash
helm upgrade my-release ./appsphere \
  --set apps.demo.blueGreen.enabled=true \
  --set gateway.listeners.demo.routes.http.backendRefs.primary.weight=0 \
  --set gateway.listeners.demo.routes.http.backendRefs.green.weight=100 \
  --set gateway.listeners.demo.routes.grpc.backendRefs.primary.weight=0 \
  --set gateway.listeners.demo.routes.grpc.backendRefs.green.weight=100
```

---

## 💡 Key Benefits
*   **Zero Downtime**: Shifts happen at the networking layer; no pod restarts are required for the "switch".
*   **Safety**: If issues are detected, a single Helm command reverts traffic to the stable slot.
*   **Validation**: Test the new version on the production URL with a small subset of traffic.

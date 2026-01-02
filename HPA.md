# Horizontal Pod Autoscaling (HPA)

This Helm chart supports automatic scaling of your application pods based on CPU utilization using the Kubernetes [Horizontal Pod Autoscaler (HPA)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).

## 📋 Prerequisites

To use HPA, your cluster must meet the following requirements:

1.  **Metrics Server**: The [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) must be installed and running in your cluster.

### 🔍 Verify Metrics Server
Before installing, check if the Metrics Server is already running in your cluster:

```bash
# Method 1: Check nodes metrics (Standard)
kubectl top nodes

# Method 2: Check for the metrics-server pod
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

If `kubectl top nodes` returns resource usage, the server is healthy. If you see an error like `Metrics API not available`, proceed to installation.

### 📥 Installing Metrics Server

If you don't have the Metrics Server installed, you can deploy it using one of the following methods:

#### Method 1: Kubectl (Standard)
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

#### Method 2: Helm
```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm install metrics-server metrics-server/metrics-server
```

> [!TIP]
> **Minikube/Kind**: If you are using Minikube, you can simply run `minikube addons enable metrics-server`. For Kind or some cloud providers, you might need to add `--kubelet-insecure-tls` to the metrics-server deployment arguments if it fails to scrape metrics.

2.  **Resource Requests**: Your application pods **must** have CPU resource requests defined. Without requests, the HPA cannot calculate utilization percentages.

## ⚙️ Configuration

HPA is configured per-application in `values.yaml` under the `hpa` key.

### Example Configuration

```yaml
apps:
  my-app:
    name: my-app
    
    # Resource requests are REQUIRED for HPA
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"

    # HPA Settings
    hpa:
      enabled: true
      minReplicas: 2
      maxReplicas: 10
      targetCPUUtilizationPercentage: 70
```

## 🏗️ How it Works

1.  **Metric Collection**: The HPA controller periodically queries the Metrics Server for the CPU utilization of the pods targeted by the Deployment.
2.  **Calculation**: It compares the current utilization against the `targetCPUUtilizationPercentage`.
3.  **Scaling**: 
    *   If utilization is higher than the target, it increases the replica count (up to `maxReplicas`).
    *   If utilization is lower, it gradually decreases the replica count (down to `minReplicas`).

### Blue-Green Support
When Blue-Green deployments are enabled, the chart automatically creates separate HPAs for both the `blue` and `green` slots, ensuring that both versions scale independently based on their own load.

## ✅ Verification

You can verify the status of your HPA using the following commands:

```bash
# List all HPAs in the namespace
kubectl get hpa -n <namespace>

# View detailed status and scaling events
kubectl describe hpa <app-name>-hpa -n <namespace>

# Monitor scaling in real-time
kubectl get hpa -n <namespace> --watch
```

## 💡 Best Practices
- **Set Realistic Requests**: Ensure your CPU `requests` reflect the actual baseline usage of your app.
- **Graceful Scaling**: Use a reasonable `targetCPUUtilizationPercentage` (typically 50-80%) to allow enough headroom for spikes during the scaling process.
- **Cooldown Periods**: Be aware that Kubernetes has default horizontal scale-down stabilization windows (default 5 minutes) to prevent "flapping".

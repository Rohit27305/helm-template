# Blue-Green & Canary Deployment Strategy with Helm (Weighted)

This document explains how the Blue-Green deployment strategy is implemented in this Helm chart using **weighted traffic shifting** via the Kubernetes Gateway API.

## Strategy Overview

We maintain two identical environments, **Blue** and **Green**, for each application. Instead of a hard switch, we use weights to control how much traffic goes to each version on the **same URL**.

- **Blue**: One version of the application (e.g., Stable).
- **Green**: Another version (e.g., New/Canary).

## Configuration

The configuration is managed in `values.yaml` under each app's `blueGreen` section.

```yaml
blueGreen:
  enabled: true
  blue:
    tag: v1.0.0
    weight: 100  # Percentage of traffic
  green:
    tag: v2.0.0
    weight: 0    # Percentage of traffic
```

### How it works

1. **Dual Deployments**: Two deployments are created: `app-name-blue` and `app-name-green`.
2. **Dedicated Services**:
   - `app-name-blue`: Direct access to Blue pods.
   - `app-name-green`: Direct access to Green pods.
   - `app-name`: Standard fallback service (points to the slot with higher weight).
3. **Gateway API Integration**: The `HTTPRoute` splits traffic between `-blue` and `-green` services based on the **explicitly defined** weights in the `gateway.listeners[].routes[].backendRefs` section of `values.yaml`.

## How to Switch (Production Workflow)

The best practice is to use `helm upgrade` with `--set` for CI/CD automation.

### 1. Deploy New Version to Inactive Slot
If Blue is currently at 100% weight, deploy the new version to Green:
```bash
helm upgrade <release-name> . --set apps[0].blueGreen.green.tag=v2.0.0
```

### 2. Verify on Same URL (Canary/Gradual Rollout)
Shift a small percentage of traffic to the new version to test it "live" on the production URL:
```bash
helm upgrade <release-name> . \
  --set apps[0].blueGreen.blue.weight=90 \
  --set apps[0].blueGreen.green.weight=10
```

### 3. Full Cutover
Once satisfied, move 100% of the traffic to the new version:
```bash
helm upgrade <release-name> . \
  --set apps[0].blueGreen.blue.weight=0 \
  --set apps[0].blueGreen.green.weight=100
```

### 4. Instant Rollback
In case of errors, immediately shift all traffic back to the stable version by updating the weights in the `gateway.listeners` section.

### 5. Managing Weights in Gateway Configuration
The traffic shift is now explicitly controlled in the `gateway` section of your `values.yaml` for each route:

```yaml
gateway:
  listeners:
    - host: test.makunaiglobal.ai
      routes:
        - path: /
          backendRefs:
            - name: test-blue
              port: 80
              weight: "100"
            - name: test-green
              port: 80
              weight: "0"
```

## Benefits
- **Same URL Testing**: Validate new versions on the actual production domain.
- **Canary Rollouts**: Gradually increase traffic to reduce risk.
- **Zero Downtime**: Shifts happen at the networking layer without pod restarts.
- **Simplified CI/CD**: No manual template changes; strictly value-driven.

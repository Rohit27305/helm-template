# Blue-Green & Canary Deployment Strategy with Helm (Weighted)

This document explains how the Blue-Green deployment strategy is implemented in this Helm chart using **weighted traffic shifting** via the Kubernetes Gateway API.

## Strategy Overview

We maintain two environments, **Blue** (Default/Stable) and **Green** (New/Canary), for each application. Instead of a hard switch, we use weights in the Gateway API to control how much traffic goes to each version on the **same URL**.

- **Blue**: The standard version of the application.
- **Green**: The new/canary version of the application.

## Configuration

The configuration is managed in `values.yaml` under each app's `blueGreen` section.

```yaml
blueGreen:
  enabled: true
  blue:
    tag: v1.0.0
  green:
    tag: v2.0.0
```

> [!NOTE]
> Weights are managed at the **Gateway** level for precise traffic control across the shared hostname.

### How it works

1. **Dual Deployments**: Two deployments are created: `app-name-blue` and `app-name-green`.
2. **Dedicated Services**: 
   - `app-name-blue`: Direct access to Blue pods.
   - `app-name-green`: Direct access to Green pods.
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
# gateway.listeners[0].routes[0].backendRefs[0] -> Blue
# gateway.listeners[0].routes[0].backendRefs[1] -> Green
helm upgrade <release-name> . \
  --set gateway.listeners[0].routes[0].backendRefs[0].weight=90 \
  --set gateway.listeners[0].routes[0].backendRefs[1].weight=10
```

### 3. Full Cutover
Once satisfied, move 100% of the traffic to the new version:
```bash
helm upgrade <release-name> . \
  --set gateway.listeners[0].routes[0].backendRefs[0].weight=0 \
  --set gateway.listeners[0].routes[0].backendRefs[1].weight=100
```

## Benefits
- **Minimal Complexity**: Uses only two dedicated services for clear separation.
- **Same URL Testing**: Validate new versions on the actual production domain.
- **Zero Downtime**: Shifts happen at the networking layer without pod restarts.
- **Simplified CI/CD**: Strictly value-driven rollout and rollback.

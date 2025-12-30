# Blue-Green & Canary Deployment Strategy with Helm (Weighted)

This document explains how the Blue-Green deployment strategy is implemented in this Helm chart using **weighted traffic shifting** via the Kubernetes Gateway API.

## Strategy Overview

We maintain two environments, **Blue** (Stable) and **Green** (New/Canary). Instead of a hard switch, we use weights in the Gateway API to control how much traffic goes to each version on the **same URL**.

- **Blue**: The currently stable version of the application.
- **Green**: The new or canary version being rolled out.

## Configuration

The configuration is managed in `values.yaml` under each app's `blueGreen` section. Note that `apps` is a **dictionary (map)**, not a list.

```yaml
apps:
  demo:  # 'demo' is the map key
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

1. **Dual Deployments**: Two deployments are created: `demo-blue` and `demo-green`.
2. **Dedicated Services**: 
   - `demo-blue`: Direct access to Blue pods.
   - `demo-green`: Direct access to Green pods.
3. **Gateway API Integration**: The `HTTPRoute` splits traffic between `-blue` and `-green` services based on the **explicitly defined** weights in the `gateway.listeners[].routes[].backendRefs` section of `values.yaml`.

## How to Rollout (Production Workflow)

The best practice is to use `helm upgrade` with `--set` for CI/CD automation. 

> [!IMPORTANT]
> Because `apps` is a dictionary, you must refer to the app name directly (e.g., `apps.demo`) instead of using an index like `apps[0]`. This ensures Helm **merges** your changes instead of wiping out the entire app configuration.

### 1. Deploy New Version to Inactive Slot
If Blue is currently at 100% weight, deploy the new version to Green:
```bash
helm upgrade test . -n demo --set apps.demo.blueGreen.green.tag=v2.0.0
```

### 2. Verify on Same URL (Canary/Gradual Rollout)
Shift a small percentage of traffic to the new version to test it "live":
```bash
# gateway.listeners[0].routes[0].backendRefs[0] -> Blue
# gateway.listeners[0].routes[0].backendRefs[1] -> Green
helm upgrade test . -n demo \
  --set gateway.listeners[0].routes[0].backendRefs[0].weight=90 \
  --set gateway.listeners[0].routes[0].backendRefs[1].weight=10
```

### 3. Full Cutover
Once satisfied, move 100% of the traffic to the new version:
```bash
helm upgrade test . -n demo \
  --set gateway.listeners[0].routes[0].backendRefs[0].weight=0 \
  --set gateway.listeners[0].routes[0].backendRefs[1].weight=100
```

## Benefits of the Map Structure
- **Safe Overrides**: Using a map for `apps` prevents the "wipe issue" where `--set` on a list index replaces the entire object.
- **Minimal Complexity**: Uses only two dedicated services for clear separation.
- **Same URL Testing**: Validate new versions on the actual production domain.
- **Zero Downtime**: Shifts happen at the networking layer without pod restarts.

# 📜 AppSphere: Mandatory Chart Rules & Guidelines

This document outlines the strict technical requirements and operational "Golden Rules" that must be followed when managing the AppSphere Helm chart. Failure to follow these may result in failed templates or incomplete deployments.

---

## 🔄 1. Blue-Green & Canary Deployments

To correctly utilize the Blue-Green or Canary deployment strategy:

*   **Activation**: `apps.<app-name>.blueGreen.enabled` **must** be set to `true`. If disabled, only the "blue" (stable) version will be rendered.
    
    > [!IMPORTANT]
    > **Mandatory Flag**: You **must** ensure the `enabled: true` flag is set (either in `values.yaml` or via `--set apps.<app-name>.blueGreen.enabled=true`) whenever using Blue-Green or Canary deployments. Without this flag, the "green" slot and traffic weighting will be ignored.
*   **Tag Management**: 
    *   Always define specific tags under `blueGreen.blue.tag` and `blueGreen.green.tag`.
    *   The top-level `apps.<app-name>.tag` is only used as a fallback when Blue-Green is disabled.
*   **Green Installation**: To deploy a new version to the Canary slot, ensure you are setting `apps.<app-name>.blueGreen.green.tag` via your values file or `--set` flag.
*   **Route Syncing**: When shifting traffic, you **must** update weights for **all** route types (HTTP, gRPC, etc.) associated with the application to ensure a consistent user experience.

---

## 🏷️ 2. Naming & Identification

*   **Global Namespace**: `global.namespace` is **mandatory**. All resources (Deployments, Services, Gateways) are bound to this namespace.
*   **App Naming**: `apps.<app-name>.name` is required. It serves as the base for resource names (`demo`, `demo-green`, `demo-svc`).
*   **Strict Image Formatting**: Every app must define an `imageName`. The final image is constructed as: `{{ .Values.global.image.registry }}/{{ .Values.global.image.repository }}/{{ $app.imageName }}:{{ $tag }}`.

---

## 🕸️ 3. Networking & Gateway API

*   **Deep Merge Requirement**: Always use map-based keys for listeners, routes, and backends (e.g., `demo`, `primary`, `green`). 
    > [!WARNING]
    > **Never** use array indices (like `routes[0]`) in `--set` commands. This will overwrite the entire list and break other routes.
*   **NodePort Stability**: 
    *   The **Blue** slot uses the static `nodePort` defined in `values.yaml`. 
    *   The **Green** slot is assigned a **random** port by Kubernetes to prevent port conflicts on the host.

---

## 📈 4. Scaling & Performance

*   **HPA Prerequisite**: Horizontal Pod Autoscaling (HPA) **requires** `resources.requests.cpu` to be defined for the application. Without requests, the Metrics Server cannot calculate utilization.
*   **PDB Safety**: Pod Disruption Budgets are active by default. Ensure your `minAvailable` or `maxUnavailable` settings allow for rolling updates.

---

## 🛠️ 5. Operational Best Practices

*   **Private Registries**: If using private images, always populate `global.imagePullSecrets`.
*   **Dry Runs**: Always perform a `helm template` or `helm upgrade --dry-run` when modifying traffic weights to verify the `HTTPRoute` backend refs.

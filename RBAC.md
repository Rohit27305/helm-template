# 🔒 AppSphere: RBAC (Role-Based Access Control) Strategy

This guide details the flexible, multi-level RBAC implementation provided by the AppSphere Helm chart. It allows for independent management of **Namespace** and **Cluster** permissions using a secure, dual-identity strategy.

---

## 🏗️ High-Level Architecture

The RBAC implementation is consolidated into three core templates for clarity and maintainability:
1.  `serviceaccount.yaml`: Dynamically provisions ServiceAccounts and token Secrets.
2.  `rbac-namespace.yaml`: Governs namespace-scoped `Roles` and `RoleBindings`.
3.  `rbac-cluster.yaml`: Governs cluster-scoped `ClusterRoles` and `ClusterRoleBindings`.

## ⚙️ Configuration

RBAC is configured in the `rbac` section of `values.yaml`.

### 1. Global Enablement
```yaml
rbac:
  enabled: true
```

### 2. Namespace-Level RBAC
Namespace-level permissions are scoped to the namespace where the chart is deployed. They are used for managing resources like Pods, Services, and Deployments.

```yaml
rbac:
  namespace:
    enabled: true
    serviceAccountName: rbac-sa
    tokenSecretName: rbac-token
    roleName: rbac-role
    roleBindingName: rbac-binding
    rules:
      - apiGroups: [""]
        resources: ["pods", "services"]
        verbs: ["get", "list"]
```

### 3. Cluster-Level RBAC
Cluster-level permissions are scoped to the entire cluster. They are used for managing cluster-wide resources like Nodes, Namespaces, or PersistentVolumes.

```yaml
rbac:
  cluster:
    enabled: true
    serviceAccountName: rbac-cluster-sa
    tokenSecretName: rbac-cluster-token
    roleName: rbac-cluster-role
    roleBindingName: rbac-cluster-binding
    rules:
      - apiGroups: [""]
        resources: ["nodes"]
        verbs: ["get", "list"]
```

---

## 🧠 Advanced Logic

### Dual Identity (Separate ServiceAccounts)
The chart creates two distinct ServiceAccounts if both levels are enabled:
- **`rbac-sa`**: Restricted to namespace permissions.
- **`rbac-cluster-sa`**: Authorized for cluster-wide operations.

This allows you to assign specific pods to use one or the other depending on the permissions they require, adhering to the **Principle of Least Privilege**.

### Automatic Token Secrets
For older Kubernetes versions or specific automation needs, the chart automatically generates `ServiceAccount` token secrets when `tokenSecretName` is provided.

---

## 🛠 Operational Scripts

We provide scripts to automate common RBAC tasks located in the root `scripts/` directory:

### 1. `generate-kubeconfig.sh`
Generates a standalone `kubeconfig` file for a specific ServiceAccount.
```bash
./scripts/generate-kubeconfig.sh <sa-name> <namespace>
```

### 2. `setup-user.sh`
Automates Linux user creation, SSH key setup, and provisions them with a kubeconfig.
```bash
./scripts/setup-user.sh <source-kubeconfig-path> <group-name>
```

---

## ✅ Verification

After deploying the chart, you can verify the RBAC resources and test the permissions using the following commands:

### 1. Check Resources
```bash
# Verify ServiceAccounts
kubectl get sa -n <namespace>

# Verify Namespace-level Roles
kubectl get role,rolebinding -n <namespace>

# Verify Cluster-level Roles
kubectl get clusterrole,clusterrolebinding | grep <serviceAccountName>
```

### 2. Test Permissions
Use the `auth can-i` command to simulate the ServiceAccount's permissions:

```bash
# Test Namespace permissions (e.g., list pods)
kubectl auth can-i list pods --as=system:serviceaccount:<namespace>:<namespace-sa-name> -n <namespace>

# Test Cluster permissions (e.g., list nodes)
kubectl auth can-i list nodes --as=system:serviceaccount:<namespace>:<cluster-sa-name>
```

## 🚀 Usage in Applications

To use these ServiceAccounts in your application pods, you must specify the `serviceAccountName` in the Pod's `spec`.

### Example Pod Spec
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test-pod
spec:
  serviceAccountName: rbac-sa  # Use the SA name defined in values.yaml
  containers:
    - name: app
      image: my-app-image
```

> [!IMPORTANT]
> **Namespace Scope**: Even if a ServiceAccount has `ClusterRole` permissions, the `ServiceAccount` resource itself still resides in a specific namespace.

---

## 💡 Best Practices
- **Least Privilege**: Only enable `rbac.cluster.enabled` if your application strictly requires cluster-wide visibility.
- **Dedicated SAs**: Use different names for `serviceAccountName` in namespace and cluster sections to maintain identity separation.
- **Granular Rules**: Define your `rules` as specifically as possible.

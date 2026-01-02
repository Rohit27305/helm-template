#!/bin/bash

# ==============================
# CONFIG (Defaults from chart)
# ==============================
SA_NAME="${1:-rbac-sa}"
NAMESPACE="${2:-demo}"
KUBECONFIG_FILE="${3:-${SA_NAME}.kubeconfig}"

echo "🔧 Generating kubeconfig for ServiceAccount: $SA_NAME in Namespace: $NAMESPACE"

# ==============================
# VALIDATION
# ==============================
kubectl get sa "$SA_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "❌ Error: ServiceAccount $SA_NAME not found in namespace $NAMESPACE"
  exit 1
}

# ==============================
# CLUSTER DETAILS
# ==============================
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA=$(kubectl config view --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

# ==============================
# TOKEN (Attempt to use Secret first for persistence, then Token API)
# ==============================
# Try to find a secret-based token first (v < 1.24 or explicit secret)
SA_TOKEN=$(kubectl get secret -n "$NAMESPACE" -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='$SA_NAME')].data.token}" | base64 --decode 2>/dev/null)

if [ -z "$SA_TOKEN" ]; then
  echo "⚠️  Permanent Secret token not found, generating short-lived token using Token API..."
  SA_TOKEN=$(kubectl create token "$SA_NAME" -n "$NAMESPACE" --duration=24h)
fi

if [ -z "$SA_TOKEN" ]; then
  echo "❌ Error: Failed to generate or retrieve token"
  exit 1
fi

# ==============================
# CREATE KUBECONFIG
# ==============================
cat <<EOF > "$KUBECONFIG_FILE"
apiVersion: v1
kind: Config

clusters:
- name: $CLUSTER_NAME
  cluster:
    server: $CLUSTER_SERVER
    certificate-authority-data: $CLUSTER_CA

users:
- name: $SA_NAME
  user:
    token: $SA_TOKEN

contexts:
- name: ${SA_NAME}-context
  context:
    cluster: $CLUSTER_NAME
    user: $SA_NAME
    namespace: $NAMESPACE

current-context: ${SA_NAME}-context
EOF

chmod 600 "$KUBECONFIG_FILE"
echo "✅ Kubeconfig created: $KUBECONFIG_FILE"
echo "➡️  Test with:"
echo "   KUBECONFIG=$(pwd)/$KUBECONFIG_FILE kubectl get pods"

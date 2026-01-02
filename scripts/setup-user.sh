#!/bin/bash

# ==============================
# CONFIG
# ==============================
KUBECONFIG_SOURCE="${1:-./rbac-sa.kubeconfig}"
GROUP_NAME="${2:-devusers}"

# ==============================
# INPUT: Username
# ==============================
read -p "Enter Linux username to create: " username

if [ -z "$username" ]; then
    echo "❌ Error: Username cannot be empty"
    exit 1
fi

# Default password
password="${username}123"
echo "Default password set as '$password' for user $username."

# ==============================
# INPUT: SSH Key
# ==============================
echo "Paste the content of your id_rsa.pub key below (press Ctrl+D to finish):"
ssh_key_content=$(cat)

# ==============================
# GROUP CREATION
# ==============================
if ! getent group "$GROUP_NAME" > /dev/null 2>&1; then
    sudo groupadd "$GROUP_NAME"
    echo "Group '$GROUP_NAME' created."
else
    echo "Group '$GROUP_NAME' already exists."
fi

# ==============================
# USER CREATION
# ==============================
if id "$username" &>/dev/null; then
    echo "⚠️ User '$username' already exists. Adding to group '$GROUP_NAME'..."
    sudo usermod -aG "$GROUP_NAME" "$username"
else
    sudo useradd -m -G "$GROUP_NAME" -s /bin/bash "$username"
    echo "$username:$password" | sudo chpasswd
    echo "User '$username' created and added to group '$GROUP_NAME'."
fi

# ==============================
# SSH SETUP
# ==============================
sudo -u "$username" bash -c "
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo \"$ssh_key_content\" > ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
"
echo "✅ SSH key added successfully for $username."

# ==============================
# KUBECONFIG SETUP
# ==============================
if [ -f "$KUBECONFIG_SOURCE" ]; then
    sudo -u "$username" bash -c "
        mkdir -p ~/.kube
        cp $KUBECONFIG_SOURCE ~/.kube/config
        chmod 600 ~/.kube/config
    "
    echo "✅ Kubernetes config set for $username using '$KUBECONFIG_SOURCE'."
else
    echo "⚠️ Warning: '$KUBECONFIG_SOURCE' not found. Kubeconfig not set for $username."
fi

# ==============================
# OUTPUT
# ==============================
echo "🎉 Setup for '$username' complete!"
echo "🔐 Access with: ssh $username@<your-node-ip>"

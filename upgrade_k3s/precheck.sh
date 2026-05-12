#!/bin/bash
# pre-upgrade-check.sh

# Run this script before upgrading K3s to verify cluster health

set -e

echo "=== K3s Pre-Upgrade Checklist ==="

# Check current K3s version
echo ""
echo "1. Current K3s version:"
kubectl version

# Check node status
echo ""
echo "2. Node status (all should be Ready):"
kubectl get nodes -o wide

# Check for pending pods
echo ""
echo "3. Checking for non-running pods:"
PENDING=$(kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | grep -v "NAMESPACE" | wc -l)
if [ "$PENDING" -gt 0 ]; then
    echo "WARNING: Found $PENDING pods not in Running/Succeeded state:"
    kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
else
    echo "OK: All pods are healthy"
fi

# Check etcd health (for embedded etcd)
echo ""
echo "4. Checking etcd health (if using embedded etcd):"
if k3s etcd-snapshot list &>/dev/null; then
    echo "etcd is accessible"
    # Create a pre-upgrade snapshot
    SNAPSHOT_NAME="pre-upgrade-$(date +%Y%m%d-%H%M%S)"
    k3s etcd-snapshot save --name "$SNAPSHOT_NAME"
    echo "Created etcd snapshot: $SNAPSHOT_NAME"
else
    echo "External datastore or etcd not accessible from this node"
fi

# Check available disk space
echo ""
echo "5. Disk space on /var/lib/rancher:"
df -h /var/lib/rancher 2>/dev/null || df -h /

# Check K3s service status
echo ""
echo "6. K3s service status:"
systemctl is-active k3s || systemctl is-active k3s-agent

echo ""
echo "=== Pre-upgrade checks complete ==="
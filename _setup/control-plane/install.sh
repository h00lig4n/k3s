#!/bin/bash
set -euo pipefail

: "${K3S_TOKEN:?Must export K3S_TOKEN}"

DOMAIN="${1:?Usage: $0 <domain> [calico-version]}"
CALICO_VERSION="${2:-v3.27.3}"

CALICO_OPERATOR_URL="https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"

echo "===> Using Calico version: ${CALICO_VERSION}"
echo "===> Operator URL: ${CALICO_OPERATOR_URL}"

echo "===> Installing k3s with flannel disabled"

export INSTALL_K3S_EXEC="
  server
  --flannel-backend=none
  --write-kubeconfig-mode 644
  --token ${K3S_TOKEN}
  --tls-san 192.168.30.10
  --tls-san 192.168.30.50
  --tls-san k3s
  --tls-san k3s.${DOMAIN}
  --disable servicelb
"

curl -sfL https://get.k3s.io | sh -

echo "===> Waiting for Kubernetes API"
until kubectl get nodes >/dev/null 2>&1; do
  sleep 2
done

echo "===> Removing NotReady nodes (powered off nodes)"
for node in $(kubectl get nodes --no-headers | awk '$2 ~ /NotReady/ {print $1}'); do
  echo "Deleting stale node $node"
  kubectl delete node "$node" --ignore-not-found
done

echo "===> Installing Tigera operator (CREATE, not apply)"
kubectl create -f "${CALICO_OPERATOR_URL}" || true

echo "===> Waiting for Installation CRD"
until kubectl get crd installations.operator.tigera.io >/dev/null 2>&1; do
  sleep 2
done

echo "===> Waiting for tigera-operator pod"
until kubectl get pods -n tigera-operator \
  | grep tigera-operator \
  | grep Running >/dev/null 2>&1; do
  sleep 2
done

echo "===> Applying Calico Installation (VXLAN)"

cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    bgp: Disabled
    ipPools:
      - blockSize: 26
        cidr: 10.42.0.0/16
        encapsulation: VXLAN
        natOutgoing: Enabled
        nodeSelector: all()
EOF

echo "===> Waiting for calico-node DaemonSet"
until kubectl get daemonset calico-node -n calico-system >/dev/null 2>&1; do
  sleep 2
done

echo "===> Waiting for all calico-node pods Ready"
until kubectl get pods -n calico-system \
  | grep calico-node \
  | awk '{print $2}' \
  | grep -v "1/1" >/dev/null 2>&1; do
  sleep 2
done

echo "===> Final node status:"
kubectl get nodes

echo "===> Calico installation complete."
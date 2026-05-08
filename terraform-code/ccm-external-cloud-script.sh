# 1. Create the secret with your Hetzner token + private network ID
kubectl -n kube-system create secret generic hcloud \
  --from-literal=token=<your_hcloud_token> \
  --from-literal=network=<network_id_from_terraform_output>

# 2. Add the chart and install
helm repo add hcloud https://charts.hetzner.cloud
helm repo update hcloud

helm install hccm hcloud/hcloud-cloud-controller-manager \
  -n kube-system \
  --set networking.enabled=true
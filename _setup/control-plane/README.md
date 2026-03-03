# Control Plane DR

[Calico K3S](https://docs.tigera.io/calico/latest/getting-started/kubernetes/k3s/quickstart)

Install script installs Calico. It expects a token and domain name. You can override version.

```bash
export K3S_TOKEN="my-token"
./install-k3s-calico-safe.sh mydomain.com v3.28.0
```

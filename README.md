# k3s - Bare Metal K3S Setup
This is run on a Raspberry Pi Cluster (currently 5x Raspberry PI 4 8Mb).
NFS running on separate Debian Linux box.

# Goals
- TLS For everything, even if the cluster is not exposed to the Internet.
  - Traefik ingress for HTTPS and TCP.
- HA dual Control Plane Nodes and external PostGreSQL database.
  - After database connectivity issues I have move to single node with backup of K3S db.
  - Have installed Galera on cluster nodes and may attempt HA again in the future. Still have single point of failure with NFS anyway.
- Migrate Home Assistant to an easier to maintain distributed container architecture.
- Ability to move devices between nodes seamlessly.
- Migrate existing debian linux server as pure a NAS.
- AI On Raspberry PI.
- Fun with Kubernetes.
- Host own developed apps.

# TODO
  - Network policy, connected to namespaces. 

# Installed Kubernetes Components

## Cert Manager
Using subdomain to provide TLS support on internal network.
[CPanel Plugin](https://github.com/jamesorlakin/cert-manager-cpanel-dns-webhook)

This creates a default wildcard certificate, this is an internal cluster so that is fine.

### Instructions
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/<latest-version>/cert-manager.yaml
kubectl apply -f https://raw.githubusercontent.com/jamesorlakin/cert-manager-cpanel-dns-webhook/master/deploy/<latest-version>.yaml
kubectl apply -f certmanager/secret.yaml
kubectl apply -f certmanager/issuer.yaml
kubectl apply -f certmanager/default-cert.yaml
```

## Generic Device Plugin
To be able to move Zigbee, Zwave and other devices between nodes and have the pods follow.
[Generic Device Plugin](https://github.com/squat/generic-device-plugin)
Update the daemonset with new device addresses.

### Instructions
```
kubectl apply -f generic-device-plugin/daemonset.yaml
```

## Sealed Secrets
Would like to be able to store everything in GIT.
[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)

### Instructions
Installed client as extension to VSCode or kubeseal via documentation.
Run the follow, updating [<latest-version>](https://github.com/bitnami-labs/sealed-secrets/releases) from here. Keep the keys backed-up, but somewhere secure. Public key will be needed to encrypt.
```
openssl req -x509 -days 730 -nodes -newkey rsa:4096 -keyout sealed-secret.key -out sealed-secret.crt -subj "/CN=sealed-secret/O=sealed-secret"
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/<latest-version>/controller.yaml
kubectl -n kube-system create secret tls sealed-secret-keys --cert=sealed-secret.crt --key=sealed-secret.key
kubectl -n kube-system label secret sealed-secret-keys sealedsecrets.bitnami.com/sealed-secrets-key=active
```

## Kubernetes Reflector
[Kubernetes Reflector](https://github.com/emberstack/kubernetes-reflector) is used to copy resources between namespaces.
It is used here to copy the wildcard TLS certificate to all namespaces.

### Instructions
  **NOTE**: Install this **before** Cert Manager.
```
kubectl -n kube-system apply -f https://github.com/emberstack/kubernetes-reflector/releases/latest/download/reflector.yaml
```

## Kube-Vip
This is used to provide a single IP address for a HA K3S without having an external load balancer.
Update the IP address in the daemonset.yaml with your common IP address. Can match the first IP in MetalLB IP pool as long as no port conflicts with Traefik.

**NOTE: This is ONLY needed with HA K3S setup.

### Installation
```
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml<br>
kubectl apply -f kube-vip/daemonset.yaml
```

## MetalLB
Using MetalLB instead of the default load balancer. Gives us some nice options to expose a service, although I prefer Ingress.
**NOTE**: I will probably remove this as since Traefik TCP endpoints are working I don't need to expose services directly.

### Installation
**NOTE:** The openssl command works only on linux. 
```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/{{latest-metallb-version}}/config/manifests/metallb-native.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f config.yaml
```

The bgp config file isn't used yet. Need to connect the cluster to a different port on the Edge Router and setup BGP first. Might do it sometime.

## Traefik
Default installation with K3S. Sucessfully used for HTTPS and for TCP. TCP was easy when I actually understood what needed to be done... 
Aim is to avoid using MetalLB to expose services outside of the cluster and rely solely on Ingress.

### Instructions
  **NOTE**: Install MetalLB first otherwise we don't have a Load Balancer. Perhaps because I removed the default one?
```
kubectl apply -f traefik/secret.yaml
kubectl apply -f traefik/middleware.yaml
kubectl apply -f traefik/tls-store.yaml
kubectl apply -f traefik/ingress.yaml
```
The following needs to be done on the control plane node, not through remote kubectl:
```On control plane node deploy traefik-config.yaml to /var/lib/rancher/k3s/server/manifests/traefik-config.yaml```

## Longhorn
High speed USB sticks in all the worker nodes to host longhorn.
**NOTE**: This has been to unstable and I'm not using it right now. Need to investigate if USB latency or network is issue. 
Probably would be a winner with non-USB high speed storage. 

## NFS
Separate debian linux server hosting:
- slow NFS (magnetic disks)
- faster NFS (SSD disks)
- Backups

### Installation
  1. kubectl create namespace external-storage<br>
  2. Deploy to /var/lib/rancher/k3s/server/manifests/nfs.yaml from nfs/nfs.yaml<br>
  3. Deploy to /var/lib/rancher/k3s/server/manifests/nfs.yaml from nfs/nfs-slow.yaml<br>
  
# Hosted Resources (Images)

## Container Registry and UI
For personal application development.

### Installation
  1. kubectl apply -f https://raw.githubusercontent.com/squat/generic-device-plugin/main/manifests/generic-device-plugin.yaml
     
## ESP Home
This is used to connect to [ESPHome](https://esphome.io/) devices. I use the bluetooth proxies and voice control.
[Guide](https://esphome.io/guides/getting_started_command_line.html)

### Installation
  1. Install the container and spin it up.
  2. In Home Assistant add ESP Home Integration.
  3. Set host as esphome and port as 6052.

  **NOTE:** Unless you enable hostNetwork=true then you will need to update domain on every device as it defaults to local and will not resolve.
  I don't do this and manually manage it.

### Grafana
Making nice graphs.

### Home Assistant
Refer to [home assistant repository](https://github.com/h00lig4n/hass) for configuration options.

- Traefik Ingress with certificate.
- Zigbee running as separate container.
- MQTT running as separate container.

**NOTE:** Not using hostNetwork=true. This does mess up Home Assistant discovery mechanisms, but the security trade-off is too high.
It can be enabled temporarily to get it working, but make sure you add your node to the trusted_proxies list (temporarily).

#### TLS Setup
Traefik with let's encrypt. Don't forget to add the correct addresses to Configuration.yaml
```
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.42.0.0/16
```

#### HACS Installation
Links:
- https://hacs.xyz/docs/use/configuration/basic/
- https://hacs.xyz/docs/use/download/download/#to-download-hacs-container
  
HACS needs to be manually installed. 
1. Shell into the container: ```kubectl exec --stdin --tty hass-8869787cd-jtxtb -n hass  -- /bin/sh```.
2. Run ```wget -O - https://get.hacs.xyz | bash -``` to download HACS.
3. Restart Home Assistant.
4. Clear browser cache and open Home Assistant.
5. navigate to Settings -> Devices & Services.
6. Add Integration HACS.
7. Follow prompts to authorize.

### InfluxDB
For Home Assistant. Used to store sensor data for longer periods of time to see trends.
### Minecraft
The kids still play this!

### Mosquitto Broker
For Home Assistant. To be able to separate upgrades of Home Assistant from MQTT.
The ClusterIP service does not use TLS and is not exposed outside of the cluster.
The LoadBalancer service only exposes the TLS endpoint.

Wildcard certificate for domain is used and is created separately by CertManager/Let's Encrypt.

There is a custom readiness check implemented. It is deployed as a script saved as a secret (it contains user and password).
This is then mounted into the container and called from the readinessprobe.

### Prometheus
### MySQL
### UNMS
Ubiquiti network at home.
### WordPress
### Zigbee to MQTT
For Home Assistant. To be able to separate upgrades of Home Assistant from Zigbee.[Zigbee2MQTT](https://www.zigbee2mqtt.io/)<br>
Make sure

#### Installation
  **NOTE:** This requires [Generic Device Plugin](#-generic-device-plugin) to be configured and working.

  1. kubectl apply -f zigbee2mqtt/secret.yaml<br>
  2. kubectl apply -f zigbee2mqtt/pvc.yaml<br>
  3. kubectl apply -f zigbee2mqtt/deployment.yaml<br>
  4. kubectl apply -f zigbee2mqtt/ingress.yaml<br>
  
### ZWave
For Home Assistant. To be able to separate upgrades of Home Assistant from ZWave.

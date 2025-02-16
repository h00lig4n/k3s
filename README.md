# k3s - Bare Metal K3S Setup
This is run on a Raspberry Pi Cluster (currently 5x Raspberry PI 4 8Mb).
NFS running on separate Debian Linux box.

## Goals
- TLS For everything, even if the cluster is not exposed to the Internet.
  - Traefik ingress for HTTPS and TCP.
- HA dual Control Plane Nodes and external PostGreSQL database.
  - After database connectivity issues I have move to single node with backup focus and fast recovery.
  - Have installed Galera on cluster nodes and may attempt HA again in the future. Still have single point of failure with NFS anyway.
- Migrate Home Assistant to an easier to maintain distributed container architecture.
- Ability to move Zigbee/ZWave USB devices between nodes seamlessly.
- Migrate existing debian linux server as pure a NAS.
- AI On Raspberry PI.
- Gitops with ArgoCD.
- Fun with Kubernetes.
- Host own developed apps.

## TODO
  - Network policy, connected to namespaces.
  - Prometheus

## Hardware Setup
In progress ...
5 x Raspberry PI 4 8gb
1 x USB Zwave Controller
1 x Zigbee Controller

Prepare SD card
1. SD Card Preparation using Raspberry PI Imager
    - shift control x to get att advanced.
    - Set user root user and password
    - set hostname
    - enable ssh and paste public key
    - OS Raspberry PI OS Lite 64
2. Boot Up.
    - Update /boot/cmdline.txt by adding the cgroups line to this file. 	cgroup_memory=1 cgroup_enable=memory
    - Update config.txt set dtparam=audio=off 
    - Update IP Tables as shown below, and then reboot.
      ```
      sudo apt install iptables -y
    	sudo iptables -F
    	sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
    	sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
    	sudo reboot
      ```
4. K3S Inital Setup
    Single Control Plane
    ```
    curl -sfL https://get.k3s.io | sh -s - --token "$KEY GOES HERE" --write-kubeconfig-mode 644 --tls-san 192.168.0.200 --tls-san k3s \
    --tls-san k3s.$DOMAIN_NAME --node-taint CriticalAddonsOnly=true:NoExecute --disable servicelb
    ```
5. Setup kubectl on PC.
    a. Create .kube folder<br>
    b. Create Config file<br>
    b. Copy contents of cat /etc/rancher/k3s/k3s.yaml from master node to config file<br>
    d. download kubectl to this folder<br>
    e. update PATH in environment variables with this folder<br>
    f. On master node get your K3S token: ```sudo k3s kubectl -n kubernetes-dashboard describe secret admin-user-token | grep '^token'```<br>
    g. Update kubeconfig on your PC, add Token: <tokenhere> to user section.<br>

6. Install NFS client on NAS (should already be installed) apt-get install -y nfs-common

## K3S Installation Order.
Since moving to ArgoCD I am in the process of deciding the optimum installation order.
This is my best guess to get ArgoCD installation in place as quickly as possible.

1. Setup namespaces: ```kubectl apply --f namespaces.yaml```<br>
2. Setup NFS. The ```nfs/nfs.yaml``` needs to be place here: ```/var/lib/rancher/k3s/server/manifests/nfs.yaml```<br>
3. Setup [#sealed-secrets](Sealed Secrets).<br>
3. Setup [#kubernetes-reflector](Kubernetes Relector)<br>
3. Setup [#cert-manager]<br>
4. Configure [#traefik]<br>
5. Setup ArgoCD<br>

## Installed Kubernetes Components
### Argo CD
[Argo CD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -n argocd -f argocd/ingressroute.yaml
kubectl apply -n argocd -f argocd/argocd-cmd-params.yaml
```

### Cert Manager
Using subdomain to provide TLS support on internal network.
[CPanel Plugin](https://github.com/jamesorlakin/cert-manager-cpanel-dns-webhook)

This creates a default wildcard certificate, this is an internal cluster so that is fine.

#### Instructions
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/<latest-version>/cert-manager.yaml
kubectl apply -f https://raw.githubusercontent.com/jamesorlakin/cert-manager-cpanel-dns-webhook/master/deploy/<latest-version>.yaml
```
Then apply the files in the cert-amanger folder.

### Generic Device Plugin
To be able to move Zigbee, Zwave and other devices between nodes and have the pods follow.
[Generic Device Plugin](https://github.com/squat/generic-device-plugin)
Update the daemonset with your device addresses and then apply.
```
kubectl apply -f generic-device-plugin/daemonset.yaml
```

### Sealed Secrets
Would like to be able to store everything in GIT.
[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)

#### Instructions
Install kubeseal.
Run the follow, updating [<latest-version>](https://github.com/bitnami-labs/sealed-secrets/releases) from here. Keep the keys backed-up, but somewhere secure. Public key will be needed to encrypt.
I haven't looked into key rotation so far.
```
openssl req -x509 -days <number> -nodes -newkey rsa:4096 -keyout sealed-secret.key -out sealed-secret.crt -subj "/CN=sealed-secret/O=sealed-secret"
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/<latest-version>/controller.yaml
kubectl -n kube-system create secret tls sealed-secret-keys --cert=sealed-secret.crt --key=sealed-secret.key
kubectl -n kube-system label secret sealed-secret-keys sealedsecrets.bitnami.com/sealed-secrets-key=active
```

### Kubernetes Reflector
[Kubernetes Reflector](https://github.com/emberstack/kubernetes-reflector) is used to copy resources between namespaces.
It is used here to copy the wildcard TLS certificate to all namespaces.

#### Instructions
**NOTE**: Install this **before** Cert Manager.
```
kubectl -n kube-system apply -f https://github.com/emberstack/kubernetes-reflector/releases/latest/download/reflector.yaml
```

### Kube-Vip
**NOTE:** This is ONLY needed with HA K3S setup.
This is used to provide a single IP address for a HA K3S without having an external load balancer.
Update the IP address in the daemonset.yaml with your common IP address. Can match the first IP in MetalLB IP pool as long as no port conflicts with Traefik.

#### Installation
```
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
kubectl apply -f kube-vip/daemonset.yaml
```

### MetalLB
Using MetalLB instead of the default load balancer. Gives us some nice options to expose a service, although I prefer Ingress.
**NOTE**: I will probably remove this as since Traefik TCP endpoints are working I don't need to expose services directly.

#### Installation
**NOTE:** This openssl command works only on linux. 
```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/{{latest-metallb-version}}/config/manifests/metallb-native.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f config.yaml
```
The bgp config file isn't used yet. Need to connect the cluster to a different port on the Edge Router and setup BGP first. Might do it sometime.

### Traefik
Default installation with K3S. Sucessfully used for HTTPS and for TCP. TCP was easy when I actually understood what needed to be done... 
Aim is to avoid using MetalLB to expose services outside of the cluster and rely solely on Ingress.
Might have a look at Traefik v3 soon.

#### Instructions
**NOTE**: Install MetalLB first otherwise we don't have a Load Balancer. Probably because I removed the default one?

Apply the files in the traefik folder except for the traefik-config.yaml (see below).

The following needs to be done on the control plane node, not through remote kubectl:
On control plane node copy ```traefik-config.yaml``` to ```/var/lib/rancher/k3s/server/manifests/traefik-config.yaml```

### Longhorn
High speed USB sticks in all the worker nodes to host longhorn.
**NOTE**: This has been to unstable and I'm not using it right now. Need to investigate if USB latency or network is issue. 
Probably would be a winner with non-USB high speed storage. 

### NFS
Separate debian linux server hosting:
- slow NFS (magnetic disks)
- faster NFS (SSD disks)
- Backups

#### Installation
1. Copy ```nfs/nfs.yaml``` to ```/var/lib/rancher/k3s/server/manifests/nfs.yaml```
  
## Hosted Resources (Images) ArgoCD Managed
This is all managed by ArgoCD. The following are the manual instructions. 

### Container Registry and UI
For personal application development. Kubectl Apply the yaml files in the corresponding folder.

### Generic Device Plugin
```kubectl apply -f https://raw.githubusercontent.com/squat/generic-device-plugin/main/manifests/generic-device-plugin.yaml```
     
### ESP Home
This is used to connect to [ESPHome](https://esphome.io/) devices. I use the bluetooth proxies and voice control.
[Guide](https://esphome.io/guides/getting_started_command_line.html)

#### Installation
1. Install the container and spin it up.
2. In Home Assistant add ESP Home Integration.
3. Set host as esphome and port as 6052.

**NOTE:** Unless you enable hostNetwork=true then you will need to update domain on every device as it defaults to local and will not resolve.
I don't do this and manually manage it as I really don't want to open the container like this.

### Grafana
Making nice graphs. Kubectl Apply the yaml files in the corresponding folder.

### Home Assistant
I have a separate [repository](https://github.com/h00lig4n/hass) concerned with Home Assistant configuration.

Related containers:
- Zigbee2MQTT.
- Mosquitto.
- InfluxDb
- Grafana
- EspHome
- OpenWakeWord
- ZWaveJS

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

The follow documentation should be moved to [repository](https://github.com/h00lig4n/hass).

#### HACS Installation
Links:
- https://hacs.xyz/docs/use/configuration/basic/
- https://hacs.xyz/docs/use/download/download/#to-download-hacs-container
  
HACS needs to be manually installed. 
1. Shell into the container: ```kubectl exec --stdin --tty hass-container-name -n hass  -- /bin/sh```.
2. Run ```wget -O - https://get.hacs.xyz | bash -``` to download HACS.
3. Restart Home Assistant.
4. Clear browser cache and open Home Assistant.
5. navigate to Settings -> Devices & Services.
6. Add Integration HACS.
7. Follow prompts to authorize.

### InfluxDB
For Home Assistant. Used to store sensor data for longer periods of time to see trends.
Kubectl Apply the yaml files in the corresponding folder.

### Minecraft
This folder might need updating.
The kids still play this!
Kubectl Apply the yaml files in the corresponding folder.

### Mosquitto Broker
For Home Assistant. To be able to separate upgrades of Home Assistant from MQTT.
All accessed via Traefik.

Wildcard certificate for domain is used and is created separately by CertManager/Let's Encrypt.
There is a custom readiness check implemented. It is deployed as a script saved as a secret (it contains user and password).
This is then mounted into the container and called from the readiness probe.

### Prometheus
TODO
### UNMS
Out of date folder.
Ubiquiti network at home.
### WordPress
Use it as a test environment before publish.
### Zigbee2MQTT
For Home Assistant. 
To be able to separate upgrades of Home Assistant from Zigbee.[Zigbee2MQTT](https://www.zigbee2mqtt.io/)<br>

**NOTE:** This requires [Generic Device Plugin](#-generic-device-plugin) to be configured and working.
Kubectl Apply the yaml files in the corresponding folder.
  
### ZWave
For Home Assistant. To be able to separate upgrades of Home Assistant from ZWave.
**NOTE:** This requires [Generic Device Plugin](#-generic-device-plugin) to be configured and working.
Kubectl Apply the yaml files in the corresponding folder.

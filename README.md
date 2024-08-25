# k3s - Bare Metal K3S Setup
This is run on a Raspberry Pi Cluster (currently 5x Raspberry PI 4 8Mb).

## Goals
- TLS For everything, even if the cluster is not exposed to the Internet.
  - Traefik ingress for HTTPS.
  - MetalLB for exposing TCP/UDP over TLS.
    - Investigate getting Traefik to work for TCP.
- Single Control Plane Node (experimented with HA dual Control Plane Nodes and external PostGre DB but had problems).
- Migrate Home Assistant to an easier to maintain distributed container architecture.
- Ability to move devices between nodes seamlessly.
- Migrate existing debian linux server as pure a NAS.
- Fun with Kubernetes.
- Host own developed apps. 

## TODO
- Namespace. Everything is installed in default at the moment.
  - Network policy, connected to namespaces. 

## Installed Kubernetes Components

### Generic Device Plugin
To be able to move Zigbee, Zwave and other devices between nodes.

```[Generic Device Plugin](https://github.com/squat/generic-device-plugin)```

### Multus CNI
Used for attaching multiple networks. Needed for discovery mechanisms in Home Assistant
[Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni)

### Traefik
Default installation with K3S.
Sucessfully used for HTTPS, not managed to get TCP to work yet.

### MetalLB
Run the following on the master node:

```kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml```

```kubectl apply -f metallb.yaml``` It contains tolerations.

```kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)```

The bgp config file isn't used yet. Need to connect the cluster to a different port on the Edge Router and setup BGP first.

### CertManager for CPanel
Using subdomain to provide TLS support on internal network.
[CPanel Plugin](https://github.com/jamesorlakin/cert-manager-cpanel-dns-webhook)

### Longhorn
High speed USB sticks in all the worker nodes to host longhorn.
**NOTE**: This has been to unstable. Need to investigate if USB latency or network is issue.

### NFS
Separate debian linux server hosting:
- slow NFS (magnetic disks)
- faster NFS (SSD disks)
- Backups

## Hosted Resources (Images)
### Container Registry and UI
For personal application development.
kubectl apply -f https://raw.githubusercontent.com/squat/generic-device-plugin/main/manifests/generic-device-plugin.yaml
### ESP Home
This is used to connect to [ESPHome](https://esphome.io/) devices. I use the bluetooth proxies.

[Guide](https://esphome.io/guides/getting_started_command_line.html)
1.Install the container and spin it up.
2.In Home Assistant add ESP Home Integration.
3.Set host as esphome and port as 6052.

### Grafana
Making nice graphs.
### Home Assistant
Refer to [home assistant repository](https://github.com/h00lig4n/hass) for configuration options.

- Traefik Ingress with certificate.
- Zigbee running as separate container.
- MQTT running as separate container.

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
### Prometheus
### MySQL
### UNMS
Ubiquiti network at home.
### WordPress
### Zigbee to MQTT
For Home Assistant. To be able to separate upgrades of Home Assistant from Zigbee.
### ZWave
For Home Assistant. To be able to separate upgrades of Home Assistant from ZWave.

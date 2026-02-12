# AI Setup K3S
This is old and needs updating

## Ollama

### K3S Node Setup

This has not been deployed on a Raspberry PI, it was far too slow.
Specialized NVidia node is used instead.

1. Choose Minimal Debian (Trixie) installation, SSH and tools is sufficient.
2. k3s generally put stuff under ```/var``` so consider that when partitioning.
3. Setup SSH login
  a. Create ```~/.ssh/authorized_keys``` on current user. Paste in the public key
  b. Folder chmod 700 file 600.
4. Prepare local-path storage folder under ```/srv``` or wherever you installed.
  a. ```sudo mkdir -p /srv/k3s-local-path```
  b. ```sudo chmod 755 /srv/k3s-local-path```
5. Install iptables for k3s ```sudo apt install -y iptables```
6. Install Nvidia drivers:
  a. ```sudo nano /etc/apt/sources.list``` and update to the following (leave deb-src unchanged).
  b. ```sudo apt update```
  c. ```sudo apt install nvidia-driver```
  d. You might need to reboot due to Kernel changes.
  e. use ```nvidia-smi``` to check it works.
7. Soft lock kernel to avoid GPU driver issues.
  a. ```sudo apt install linux-image-amd64 linux-headers-amd64``` if not present.
  b. ```sudo apt-mark hold linux-image-amd64 linux-headers-amd64```
8. Install Nvidia container repo:
  a. ```sudo apt install -y curl ca-certificates gnupg```
  b. ```curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit.gpg```
  c. ```curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit.gpg] https://#' \
        | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list```
  d. ```sudo apt update```
  e. ```sudo apt install -y nvidia-container-toolkit```
  f. ```nvidia-container-cli --version```
9. Install K3S with normal agent installation but add taint and labels:
  a. ```kubectl taint node k3s6 nvidia.com/gpu=true:NoSchedule```
  b. ```kubectl label node k3s6 node-role.kubernetes.io/ai=true```
  c. Configure containerd for nvidia ```sudo nvidia-ctk runtime configure --runtime=containerd```

### Maintainance

if nvidia-smi stops working:
1. ```sudo apt install --reinstall nvidia-driver```
2. ```sudo reboot```

Kernel Upgrade:
1. Unhold ```sudo apt-mark unhold linux-image-amd64 linux-headers-amd64```
2. Normal apy update/upgrad

## OpenWebUi

Documentation pending

### OpenWebUI Settings

### Documents

## Qdrant

Vector database for RAG.

## Searxng

Installation was a pain. Trial and error with configuration files needing write after startup.

1. Make sure you add json support in the config.
2. Remove most of the engines as they don't add much for this usage.

## Tika

Used for extracting text from documents.
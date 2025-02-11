# ARGO CD

## Sidecar for Environment Variable replacement using ConfigManagementPlugin concept.
**NOTE:** This is an anti-pattern and should not be done with production.

## Create container (this tagets arm64 for Raspeberry PI)
1. Build ```docker build . --build-arg BUILDPLATFORM=linux/arm64 --tag your-registry/envsubst-cmp-plugin:latest```
2. Build ```docker push your-registry/envsubst-cmp-plugin:latest```




## Installation
1. Create Namespace: ```kubectl create namespace argocd```
2. Deploy configuration : ``` kubectl apply -f argocd-cmd-params-cm.yaml -n argocd```
3. 


# With Traefik, need to run without TLS in the cluster

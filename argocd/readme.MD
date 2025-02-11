# ARGO CD

## Sidecar for Environment Variable replacement using ConfigManagementPlugin concept.
**NOTE:** This is an anti-pattern and should not be done with production.

This plugin will read in all -yaml files in an application and replace environment variables. 
Environment variables can either be defined globally in the sidecar (as done here, refer to patch) or can be set per application.

## Create container (this tagets arm64 for Raspeberry PI)
1. Build ```docker build . --build-arg BUILDPLATFORM=linux/arm64 --tag your-registry/envsubst-cmp-plugin:latest```
2. Push ```docker push your-registry/envsubst-cmp-plugin:latest```

## Installation
1. Create Namespace: ```kubectl create namespace argocd```
2. Deploy configuration to disable TLS (for Traefik ingress to work, no re-encrypt support): ``` kubectl apply -f argocd-cmd-params-cm.yaml -n argocd```
3. Deploy ArgoCD: ```kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml```
4. Follow [ArgoCD documentation](https://argo-cd.readthedocs.io/en/stable/getting_started/) to fix password.
5. Patch argocd-repo-server: ```kubectl patch deployment argocd-repo-server --patch argocd-repo-server-patch.yaml -n argocd```
6. Wait for redeployment and then we are ready to configure applications.

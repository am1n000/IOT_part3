#!/bin/bash

# Create a K3d Kubernetes cluster named "iot-ael-rhai"
# - Maps ports for HTTP (8080 -> 80), HTTPS (8443 -> 443), and custom app (8888 -> 8888) on the load balancer
sudo k3d cluster create iot-ael-rhai -p 8080:80@loadbalancer -p 8443:443@loadbalancer -p 8888:8888@loadbalancer

# Create a namespace for ArgoCD (a GitOps continuous delivery tool)
sudo kubectl create namespace argocd

# Create a namespace for the development environment
sudo kubectl create namespace dev

# Save the K3d cluster kubeconfig to the default Kubernetes config location
# This allows `kubectl` commands to interact with the newly created cluster
k3d kubeconfig get iot-ael-rhai > ~/.kube/config

# Deploy ArgoCD in the "argocd" namespace by applying the official installation YAML from GitHub
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Patch the ArgoCD service to change its type to LoadBalancer, making it accessible externally
sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for the ArgoCD deployment to roll out successfully
sudo kubectl -n argocd rollout status deployment argocd-server

# Retrieve and decode the initial admin password for ArgoCD, then print it to the console
sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Apply the ArgoCD application configuration from a local YAML file (./apps/argocd.yaml)
# This defines applications managed by ArgoCD in the "argocd" namespace
sudo kubectl apply -f ./apps/argocd.yaml -n argocd

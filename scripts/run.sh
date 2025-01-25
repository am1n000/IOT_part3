#!/bin/bash

sudo k3d cluster delete dev-cluster

sudo k3d cluster create dev-cluster -p "8888:30080"

sudo kubectl create namespace argocd

sudo kubectl create namespace dev

sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo kubectl wait --for=condition=ready --timeout=600s pod --all -n argocd

ARGOCD_PASSWORD=$(sudo kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)
echo "ArgoCD admin password: $ARGOCD_PASSWORD"

sudo kubectl apply -f "../confs/app.yaml"

while true; do
    POD_STATE=$(sudo kubectl get po -n dev --output="jsonpath={.items..phase}")
    if [[ "$POD_STATE" == "Running" ]]; then
        echo "Application is running."
        break
    ficlear
    echo "Creating app, waiting..."
    sleep 10
done

sudo kubectl port-forward svc/argocd-server -n argocd 8080:443


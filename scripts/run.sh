#!/bin/bash

check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed." >&2
        exit 1
    fi
}

echo "Deleting existing cluster..."
sudo k3d cluster delete dev-cluster 2>/dev/null

echo "Creating new K3D cluster..."
sudo k3d cluster create dev-cluster -p "8888:30080"
check_success "Cluster creation"

echo "Creating ArgoCD namespace..."
sudo kubectl create namespace argocd
check_success "Namespace creation"

echo "Installing ArgoCD..."
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
check_success "ArgoCD installation"

echo "Waiting for ArgoCD pods to be ready..."
sudo kubectl wait --for=condition=Ready pods --all -n argocd
check_success "ArgoCD readiness"

echo "Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(sudo kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)
check_success "Fetching admin password"
echo "ArgoCD initial admin password: $ARGOCD_PASSWORD"

echo "Creating development namespace..."
sudo kubectl create namespace dev
check_success "Dev namespace creation"

echo "Deploying application..."
sudo kubectl apply -f ../confs/app.yaml
check_success "Application deployment"

echo "Waiting for application pods to start..."
while true; do
    POD_STATE=$(sudo kubectl get po -n dev --output="jsonpath={.items..phase}")
    if [[ "$POD_STATE" == "Running" ]]; then
        echo "Application is running."
        break
    fi
    echo "Creating app, waiting..."
    sleep 10
done

echo "Starting port-forwarding for ArgoCD..."
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &
check_success "Port-forwarding setup"

echo "Setup completed. Access ArgoCD at https://localhost:8080"

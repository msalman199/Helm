# 🚀 Helm and Kubernetes Networking

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge\&logo=kubernetes\&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge\&logo=helm\&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge\&logo=docker\&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge\&logo=linux\&logoColor=black)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge\&logo=nginx\&logoColor=white)
![YAML](https://img.shields.io/badge/YAML-CB171E?style=for-the-badge\&logo=yaml\&logoColor=white)

> 🧭 **Hands-on Kubernetes networking lab using Helm, kind, NGINX Ingress, namespaces, DNS, NetworkPolicies, and Helm dependencies.**

---

## 📌 Table of Contents

* [🎯 Lab Objectives](#-lab-objectives)
* [🧰 Prerequisites](#-prerequisites)
* [🏗️ Lab Architecture](#️-lab-architecture)
* [💻 Technology Stack](#-technology-stack)
* [⚙️ Environment Setup](#️-environment-setup)
* [🌐 Task 1 — Helm Networking and Ingress](#-task-1--helm-networking-and-ingress)
* [🔗 Task 2 — Cross-Namespace Networking](#-task-2--cross-namespace-networking)
* [🛡️ Network Policies](#️-network-policies)
* [📦 Umbrella Helm Chart](#-umbrella-helm-chart)
* [🧪 Verification and Testing](#-verification-and-testing)
* [🐛 Troubleshooting](#-troubleshooting)
* [🧹 Cleanup](#-cleanup)
* [📚 Key Concepts](#-key-concepts)
* [🏆 Conclusion](#-conclusion)

---

## 🎯 Lab Objectives

By completing this lab, you will learn how to:

* 🔹 Install and configure Helm on a Kubernetes cluster
* 🔹 Deploy applications using Helm charts
* 🔹 Configure Kubernetes Ingress for external access
* 🔹 Implement service-to-service communication
* 🔹 Create custom Helm charts containing networking components
* 🔹 Implement cross-namespace communication
* 🔹 Configure Kubernetes NetworkPolicies
* 🔹 Use Helm chart dependencies
* 🔹 Troubleshoot Kubernetes networking problems

These objectives are directly aligned with the original lab material.

---

## 🧰 Prerequisites

Before starting, you should have:

* 🐳 Basic Docker knowledge
* ☸️ Basic Kubernetes knowledge
* 📝 Familiarity with YAML
* 🐧 Basic Linux command-line experience
* 🌐 Understanding of DNS, load balancing, and Ingress
* 📦 Experience working with containerized applications

The original lab specifically assumes familiarity with Pods, Services, Deployments, YAML, Linux, DNS, load balancing, and Ingress.

---

# 🏗️ Lab Architecture

The lab builds a multi-tier Kubernetes application architecture:

```text
                         ┌─────────────────────┐
                         │       Browser       │
                         │    / HTTP Client    │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │   NGINX Ingress     │
                         │     Controller      │
                         └──────────┬──────────┘
                                    │
                   ┌────────────────┴────────────────┐
                   │                                 │
                   ▼                                 ▼
          ┌─────────────────┐              ┌─────────────────┐
          │    Frontend     │              │     Web App     │
          │    Namespace    │              │     Service     │
          └────────┬────────┘              └─────────────────┘
                   │
                   │ Cross-Namespace
                   ▼
          ┌─────────────────┐
          │     Backend     │
          │    Namespace    │
          └────────┬────────┘
                   │
                   │ TCP 3306
                   ▼
          ┌─────────────────┐
          │     MySQL       │
          │    Database     │
          │    Namespace    │
          └─────────────────┘
```

---

# 💻 Technology Stack

| Technology        | Purpose                       |
| ----------------- | ----------------------------- |
| ☸️ Kubernetes     | Container orchestration       |
| ⛵ Helm            | Kubernetes package management |
| 🐳 Docker         | Container runtime             |
| 🧪 kind           | Local Kubernetes cluster      |
| 🔧 kubectl        | Kubernetes CLI                |
| 🌐 NGINX Ingress  | External HTTP access          |
| 🛡️ NetworkPolicy | Network traffic control       |
| 🐧 Linux          | Lab operating system          |
| 📝 YAML           | Kubernetes configuration      |

---

# ⚙️ Environment Setup

The lab environment uses a Linux-based machine where the required tools are installed manually.

## 🔧 Step 1 — Update Linux

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 🐳 Step 2 — Install Docker

```bash
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker $USER

sudo systemctl start docker
sudo systemctl enable docker

newgrp docker
```

Verify:

```bash
docker --version
```

---

## ☸️ Step 3 — Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

Verify:

```bash
kubectl version --client
```

---

## 🧪 Step 4 — Install kind

The lab uses kind `v0.20.0`.

```bash
curl -Lo ./kind \
https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

chmod +x ./kind

sudo mv ./kind /usr/local/bin/kind
```

Verify:

```bash
kind version
```

---

## ⛵ Step 5 — Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

---

# 🌐 Task 1 — Helm Networking and Ingress

## 🧱 Step 1 — Create kind Cluster

Create the cluster configuration:

```bash
cat << EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP

- role: worker

- role: worker
EOF
```

Create the cluster:

```bash
kind create cluster \
--config=kind-config.yaml \
--name=helm-networking-lab
```

Verify:

```bash
kubectl cluster-info \
--context kind-helm-networking-lab
```

---

# 🌐 Step 2 — Install NGINX Ingress Controller

```bash
kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Wait for the controller:

```bash
kubectl wait \
--namespace ingress-nginx \
--for=condition=ready pod \
--selector=app.kubernetes.io/component=controller \
--timeout=90s
```

Verify:

```bash
kubectl get pods -n ingress-nginx
```

---

# 📦 Step 3 — Create Web Application Helm Chart

Create the chart:

```bash
helm create webapp-chart
cd webapp-chart
```

Configure `values.yaml`:

```yaml
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: webapp.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false
```

The original lab configures the application with two replicas, an NGINX image, ClusterIP service, and NGINX Ingress for `webapp.local`.

---

# 🚀 Step 4 — Deploy Web Application

```bash
helm install webapp ./webapp-chart
```

Verify:

```bash
kubectl get pods
kubectl get services
kubectl get ingress
helm list
```

---

# 🌍 Step 5 — Configure Local DNS

Add the local hostname:

```bash
echo "127.0.0.1 webapp.local" | \
sudo tee -a /etc/hosts
```

Test:

```bash
sleep 30

curl -H "Host: webapp.local" http://localhost
```

---

# 🔀 Step 6 — Deploy API Application

Create another chart:

```bash
cd ..
helm create api-chart
cd api-chart
```

Configure the API Ingress with:

```yaml
ingress:
  enabled: true
  className: "nginx"

  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /

  hosts:
    - host: webapp.local
      paths:
        - path: /api
          pathType: Prefix
```

Deploy:

```bash
helm install api-service ./
```

Verify:

```bash
kubectl get ingress
```

The lab uses `webapp.local` for the web application and `/api` for the second application.

---

# 🔗 Task 2 — Cross-Namespace Networking

Create three namespaces:

```bash
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database
```

Verify:

```bash
kubectl get namespaces
```

The lab uses separate `frontend`, `backend`, and `database` namespaces to demonstrate service communication across namespace boundaries.

---

# 🗄️ Database Helm Chart

Create the database chart:

```bash
helm create database-chart
cd database-chart
```

The lab uses MySQL 8.0 with a ClusterIP service on port `3306`.

Deploy:

```bash
helm install mysql-db ./ \
--namespace database
```

Verify:

```bash
kubectl get pods -n database
kubectl get services -n database
```

---

# ⚙️ Backend Helm Chart

Create the backend:

```bash
cd ..
helm create backend-chart
cd backend-chart
```

The backend connects to:

```text
mysql-db.database.svc.cluster.local
```

This demonstrates Kubernetes DNS-based service discovery across namespaces.

Deploy:

```bash
helm install backend-service ./ \
--namespace backend
```

Verify:

```bash
kubectl get pods -n backend
kubectl get configmaps -n backend
kubectl get secrets -n backend
```

---

# 🖥️ Frontend Helm Chart

Create the frontend:

```bash
cd ..
helm create frontend-chart
cd frontend-chart
```

Configure the backend endpoint:

```yaml
backend:
  host: "backend-service.backend.svc.cluster.local"
  port: 8080
```

Configure the Ingress:

```yaml
ingress:
  enabled: true
  className: "nginx"

  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /

  hosts:
    - host: frontend.local
      paths:
        - path: /
          pathType: Prefix
```

Deploy:

```bash
helm install frontend-service ./ \
--namespace frontend
```

Add local DNS:

```bash
echo "127.0.0.1 frontend.local" | \
sudo tee -a /etc/hosts
```

Verify:

```bash
kubectl get pods -n frontend
kubectl get ingress -n frontend
```

---

# 🔄 Cross-Namespace Communication

## 🧪 Test Database Connectivity

From the backend namespace:

```bash
kubectl run test-db-connection \
--image=mysql:8.0 \
--rm -it \
--restart=Never \
--namespace=backend \
-- mysql \
-h mysql-db.database.svc.cluster.local \
-u appuser \
-papppassword \
-e "SHOW DATABASES;"
```

---

## 🧪 Test Backend Connectivity

From the frontend namespace:

```bash
kubectl run test-backend-connection \
--image=curlimages/curl \
--rm -it \
--restart=Never \
--namespace=frontend \
-- curl -v \
http://backend-service.backend.svc.cluster.local:8080
```

---

## 🌐 Test Frontend Ingress

```bash
curl \
-H "Host: frontend.local" \
http://localhost
```

---

# 🛡️ Network Policies

NetworkPolicies are introduced to control traffic between namespaces. The lab creates policies for the database and backend tiers.

## 🗄️ Database Policy

The database policy allows traffic from the backend namespace to MySQL on TCP port `3306`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy

metadata:
  name: database-network-policy
  namespace: database

spec:
  podSelector: {}

  policyTypes:
  - Ingress

  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: backend

    ports:
    - protocol: TCP
      port: 3306
```

---

## ⚙️ Backend Policy

The backend policy controls:

```text
Frontend → Backend
Backend → Database
Backend → DNS
```

The original policy allows frontend ingress on TCP `8080`, database egress on TCP `3306`, and DNS traffic on TCP/UDP port `53`.

Apply policies:

```bash
kubectl label namespace backend name=backend
kubectl label namespace frontend name=frontend
kubectl label namespace database name=database

kubectl apply -f database-network-policy.yaml
kubectl apply -f backend-network-policy.yaml
```

Verify:

```bash
kubectl get networkpolicies --all-namespaces
```

---

# 📦 Umbrella Helm Chart

The lab also creates a complete stack using an umbrella Helm chart.

Create it:

```bash
cd ..
helm create full-stack-chart
cd full-stack-chart
```

Remove default templates:

```bash
rm -rf templates/*
```

The umbrella chart contains:

```text
full-stack-chart/
├── Chart.yaml
├── values.yaml
└── charts/
    ├── database-chart
    ├── backend-chart
    └── frontend-chart
```

The dependency structure is defined in `Chart.yaml`:

```yaml
dependencies:
- name: database-chart
  version: "0.1.0"
  repository: "file://../database-chart"
  condition: database.enabled

- name: backend-chart
  version: "0.1.0"
  repository: "file://../backend-chart"
  condition: backend.enabled

- name: frontend-chart
  version: "0.1.0"
  repository: "file://../frontend-chart"
  condition: frontend.enabled
```

Update dependencies:

```bash
helm dependency update
```

The source lab explicitly uses local file-based Helm dependencies for the database, backend, and frontend charts.

---

# 🧪 Verification and Testing

## 📋 Check Helm Releases

```bash
helm list --all-namespaces
```

---

## ☸️ Check Pods

```bash
kubectl get pods --all-namespaces
```

---

## 🔌 Check Services

```bash
kubectl get services --all-namespaces
```

---

## 🌐 Check Ingress

```bash
kubectl get ingress --all-namespaces
```

---

## 🧪 Test Applications

```bash
curl -H "Host: webapp.local" http://localhost

curl -H "Host: frontend.local" http://localhost
```

---

## 🛡️ Check NetworkPolicies

```bash
kubectl describe networkpolicy -n database

kubectl describe networkpolicy -n backend
```

These verification commands follow the testing section of the original lab.

---

# 🐛 Troubleshooting

## ❌ Ingress Not Working

Check the controller:

```bash
kubectl get pods -n ingress-nginx
```

Check Ingress:

```bash
kubectl get ingress --all-namespaces
```

Check controller logs:

```bash
kubectl logs \
-n ingress-nginx \
deployment/ingress-nginx-controller
```

Ensure the correct Ingress class is configured.

---

## ❌ DNS Resolution Failure

Check the Service:

```bash
kubectl get services --all-namespaces
```

Test Kubernetes DNS:

```bash
kubectl run test-dns \
--image=busybox \
--rm -it \
--restart=Never \
-- nslookup \
mysql-db.database.svc.cluster.local
```

Kubernetes service DNS follows the pattern:

```text
service-name.namespace.svc.cluster.local
```

The source lab identifies incorrect service DNS and missing services as common causes of resolution failures.

---

## ❌ NetworkPolicy Blocking Traffic

Check policies:

```bash
kubectl get networkpolicies --all-namespaces
```

Inspect:

```bash
kubectl describe networkpolicy -n database
kubectl describe networkpolicy -n backend
```

Confirm namespace labels:

```bash
kubectl get namespaces --show-labels
```

---

## ❌ Pod Problems

Check Pods:

```bash
kubectl get pods --all-namespaces
```

Check logs:

```bash
kubectl logs -n frontend deployment/frontend-service

kubectl logs -n backend deployment/backend-service

kubectl logs -n database deployment/mysql-db
```

---

## 🔌 Check Endpoints

```bash
kubectl get endpoints --all-namespaces
```

---

# 🧹 Cleanup

Remove Helm releases:

```bash
helm uninstall webapp

helm uninstall api-service

helm uninstall mysql-db -n database

helm uninstall backend-service -n backend

helm uninstall frontend-service -n frontend
```

Delete namespaces:

```bash
kubectl delete namespace frontend backend database
```

Delete NetworkPolicies:

```bash
kubectl delete -f database-network-policy.yaml

kubectl delete -f backend-network-policy.yaml
```

Delete the kind cluster:

```bash
kind delete cluster \
--name=helm-networking-lab
```

Remove local DNS entries:

```bash
sudo sed -i '/webapp.local/d' /etc/hosts

sudo sed -i '/frontend.local/d' /etc/hosts

sudo sed -i '/fullstack.local/d' /etc/hosts
```

The cleanup procedure follows the original lab's Helm, namespace, NetworkPolicy, kind-cluster, and `/etc/hosts` cleanup steps.

---

# 📚 Key Concepts

### ⛵ Helm Charts

Helm packages Kubernetes applications and simplifies application deployment and management.

### ☸️ Kubernetes Networking

Kubernetes networking provides service discovery, DNS resolution, and communication between workloads.

### 🌐 Ingress

Ingress provides external HTTP/HTTPS access to services inside a Kubernetes cluster.

### 🛡️ NetworkPolicy

NetworkPolicies control allowed traffic between Pods and namespaces.

### 🔗 Cross-Namespace Communication

Kubernetes Services can communicate across namespaces using Kubernetes DNS names.

### 🕸️ Service Mesh

Service mesh is an architectural pattern for managing service-to-service communication in microservice environments.

These are the major concepts identified in the source lab.

---

# 🏆 Learning Outcomes

After completing this lab, you should be able to:

* ✅ Build a local Kubernetes cluster with kind
* ✅ Install and use Helm
* ✅ Create custom Helm charts
* ✅ Deploy multi-tier applications
* ✅ Configure NGINX Ingress
* ✅ Implement Kubernetes service discovery
* ✅ Communicate between namespaces
* ✅ Configure NetworkPolicies
* ✅ Manage Helm dependencies
* ✅ Troubleshoot Kubernetes networking
* ✅ Validate application connectivity

---

# 🏁 Conclusion

This lab demonstrates how **Helm and Kubernetes networking** can be combined to deploy and manage a multi-tier application.

You created a Kubernetes environment with kind, installed Helm and NGINX Ingress, deployed multiple Helm charts, implemented cross-namespace communication, configured NetworkPolicies, and created an umbrella Helm chart with dependencies.

The skills developed in this lab provide a foundation for more advanced Kubernetes topics including:

```text
Helm
  │
  ├── Kubernetes Deployments
  │
  ├── Services
  │
  ├── Ingress
  │
  ├── DNS
  │
  ├── Namespaces
  │
  ├── NetworkPolicies
  │
  └── Helm Dependencies
          │
          ▼
     Production
     Kubernetes
     Networking
```

---

## ⭐ Lab Status

| Component                  | Status |
| -------------------------- | ------ |
| Docker                     | ✅      |
| kubectl                    | ✅      |
| kind                       | ✅      |
| Helm                       | ✅      |
| Kubernetes Cluster         | ✅      |
| NGINX Ingress              | ✅      |
| Web Application            | ✅      |
| API Application            | ✅      |
| Frontend                   | ✅      |
| Backend                    | ✅      |
| MySQL Database             | ✅      |
| Cross-Namespace Networking | ✅      |
| NetworkPolicies            | ✅      |
| Helm Dependencies          | ✅      |
| Verification               | ✅      |

---

<div align="center">

### 🚀 Helm + Kubernetes Networking

**Deploy • Connect • Secure • Troubleshoot**

⭐ **Happy Kubernetes Learning!** ⭐

</div>

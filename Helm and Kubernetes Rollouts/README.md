# 🚀 Helm and Kubernetes Rollouts

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-Container%20Orchestration-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes">
  <img src="https://img.shields.io/badge/Helm-Package%20Manager-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm">
  <img src="https://img.shields.io/badge/Docker-Containerization-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/kind-Kubernetes%20in%20Docker-FF6B6B?style=for-the-badge&logo=kubernetes&logoColor=white" alt="kind">
  <img src="https://img.shields.io/badge/Linux-Ubuntu-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux">
  <img src="https://img.shields.io/badge/NGINX-Ingress-009639?style=for-the-badge&logo=nginx&logoColor=white" alt="NGINX">
</p>

<p align="center">
  <b>🎯 Progressive Delivery • Canary Deployments • Blue-Green Deployments • Rolling Updates • Automated Rollbacks</b>
</p>

---

## 📌 Lab Overview

This lab provides a practical implementation of **Helm-based Kubernetes application rollouts** using a local Kubernetes cluster created with **kind**.

The lab starts by preparing a complete Kubernetes and Helm environment and then progressively implements multiple deployment strategies:

* 🔄 Rolling Updates
* 🐤 Canary Deployments
* 🔵🟢 Blue-Green Deployments
* ↩️ Manual Rollbacks
* 🤖 Automated Rollbacks
* ❤️ Health Checks
* 📊 Deployment Monitoring
* ⚡ Load Testing

The complete lab demonstrates how Helm and Kubernetes can be combined to perform safer application releases with controlled traffic exposure, health validation, and recovery mechanisms.

---

## 🎯 Lab Objectives

By completing this lab, you will learn how to:

* ⚙️ Install and configure Helm on Kubernetes
* 📦 Create Helm charts for application deployment
* 🐤 Implement canary deployments using Helm
* 🔵🟢 Execute blue-green deployment strategies
* 🔄 Perform rolling updates with Helm
* ↩️ Execute rollback operations when deployments fail
* 📊 Monitor deployment status and health checks
* 🚀 Understand progressive delivery patterns in Kubernetes

---

## 🧰 Prerequisites

Before starting, you should have:

* ☸️ Basic understanding of Kubernetes concepts such as Pods, Services, and Deployments
* 📝 Familiarity with YAML configuration files
* 🐧 Basic Linux command-line knowledge
* 📦 Understanding of containerization concepts
* ⌨️ Knowledge of `kubectl` commands

---

## 🏗️ Lab Environment

The lab uses a Linux-based cloud machine provided through the **Al Nafi training environment**.

The machine is provided as a bare-metal Linux environment without the required tools pre-installed. Docker, kubectl, kind, and Helm are installed during the lab.

### 🗺️ Architecture

```text
                         🌐 Client
                            │
                            ▼
                    ┌───────────────┐
                    │ NGINX Ingress │
                    │   Controller  │
                    └───────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
        🔵 Blue App    🐤 Canary App   🟢 Green App
              │             │             │
              └─────────────┼─────────────┘
                            │
                            ▼
                    ☸️ Kubernetes
                         Cluster
                          kind
                            │
                            ▼
                         Docker
```

---

# 🛠️ Task 1 — Set Up Helm for Deployments

## 1️⃣ Install Docker

Update the package index and install the required packages:

```bash
sudo apt update

sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
```

Add Docker's repository and install Docker:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

Enable Docker:

```bash
sudo usermod -aG docker $USER

sudo systemctl start docker
sudo systemctl enable docker

newgrp docker
```

---

## 2️⃣ Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/

kubectl version --client
```

---

## 3️⃣ Install kind

Install **kind — Kubernetes in Docker**:

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

chmod +x ./kind

sudo mv ./kind /usr/local/bin/kind

kind version
```

---

## 4️⃣ Install Helm

Install Helm 3:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version
```

### ✅ Verify Tools

```bash
docker --version
kubectl version --client
kind version
helm version
```

---

# ☸️ Task 2 — Create Kubernetes Cluster

Create a kind configuration:

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
kind create cluster --config=kind-config.yaml --name=helm-lab
```

Verify:

```bash
kubectl cluster-info --context kind-helm-lab
kubectl get nodes
```

Expected architecture:

```text
┌─────────────────────────────┐
│       kind: helm-lab        │
│                             │
│  ┌───────────────────────┐  │
│  │    Control Plane      │  │
│  └───────────────────────┘  │
│                             │
│  ┌─────────┐ ┌─────────┐   │
│  │ Worker  │ │ Worker  │   │
│  └─────────┘ └─────────┘   │
└─────────────────────────────┘
```

---

# 🌐 Task 3 — Install NGINX Ingress Controller

Install the NGINX Ingress Controller:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Wait for the controller:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

Verify:

```bash
kubectl get pods -n ingress-nginx
```

---

# 📦 Task 4 — Create Sample Application

Create the application directory:

```bash
mkdir -p ~/helm-lab/sample-app
cd ~/helm-lab/sample-app
```

Create the Dockerfile:

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

Create Version 1:

```html
<h1>Sample Application - Version 1.0</h1>
<p>This is the initial version of our application</p>
<p>Deployment Strategy: Initial Release</p>
```

Build the image:

```bash
docker build -t sample-app:v1.0 .
kind load docker-image sample-app:v1.0 --name=helm-lab
```

---

## 🆕 Build Version 2

Create the Version 2 page and build the updated image:

```bash
cp index-v2.html index.html

docker build -t sample-app:v2.0 .

kind load docker-image sample-app:v2.0 --name=helm-lab
```

Version 2 represents the updated release used during the canary, blue-green, and rolling-update exercises.

---

# ⛵ Task 5 — Create Helm Chart

Create a new Helm chart:

```bash
cd ~/helm-lab

helm create sample-app-chart

cd sample-app-chart
```

Update `Chart.yaml`:

```yaml
apiVersion: v2
name: sample-app-chart
description: A Helm chart for sample application with deployment strategies
type: application
version: 0.1.0
appVersion: "1.0"
```

---

## ⚙️ Configure `values.yaml`

The chart supports:

* Replica configuration
* Container image versions
* Services
* Ingress
* Resource limits
* Rolling updates
* Canary settings
* Blue-green settings

Example:

```yaml
replicaCount: 3

image:
  repository: sample-app
  pullPolicy: Never
  tag: "v1.0"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: "nginx"

strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1

canary:
  enabled: false
  weight: 10

blueGreen:
  enabled: false
```

The source lab configures three replicas, `sample-app` as the image repository, `Never` as the image pull policy for the locally loaded images, and RollingUpdate as the default deployment strategy.

---

# 🔄 Task 6 — Rolling Updates

Install the initial application:

```bash
helm install sample-app ./sample-app-chart
```

Verify:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

Check rollout:

```bash
kubectl rollout status deployment/sample-app-sample-app-chart
```

Configure local DNS:

```bash
echo "127.0.0.1 sample-app.local" | sudo tee -a /etc/hosts
```

Test:

```bash
curl -H "Host: sample-app.local" http://localhost/
```

---

## 🚀 Upgrade to Version 2

```bash
helm upgrade sample-app ./sample-app-chart \
  --set image.tag=v2.0
```

Monitor the rollout:

```bash
kubectl rollout status deployment/sample-app-sample-app-chart --watch
```

Watch Pods:

```bash
kubectl get pods -w
```

The lab also provides a continuous curl-based check to observe application availability during the update.

---

# 📜 Task 7 — Rollout History

View Kubernetes rollout history:

```bash
kubectl rollout history deployment/sample-app-sample-app-chart
```

Inspect specific revisions:

```bash
kubectl rollout history deployment/sample-app-sample-app-chart --revision=1

kubectl rollout history deployment/sample-app-sample-app-chart --revision=2
```

View Helm release history:

```bash
helm history sample-app
```

---

# ↩️ Task 8 — Rollback Strategy

Simulate a failed deployment:

```bash
helm upgrade sample-app ./sample-app-chart \
  --set image.tag=v3.0-nonexistent
```

Check the Pods:

```bash
kubectl get pods
kubectl rollout status deployment/sample-app-sample-app-chart
```

Rollback with Kubernetes:

```bash
kubectl rollout undo deployment/sample-app-sample-app-chart
```

Or rollback using Helm:

```bash
helm rollback sample-app 2
```

Verify:

```bash
kubectl get pods

curl -H "Host: sample-app.local" http://localhost/
```

This demonstrates how Helm and Kubernetes can recover from an unsuccessful application release.

---

# 🐤 Task 9 — Canary Deployment

A canary deployment releases a new version to a small percentage of traffic before full production promotion.

Create `canary-values.yaml`:

```yaml
replicaCount: 1

image:
  repository: sample-app
  pullPolicy: Never
  tag: "v2.0"

nameOverride: "canary"
fullnameOverride: "sample-app-canary"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"

canary:
  enabled: true
  weight: 10
```

Deploy the canary:

```bash
helm install sample-app-canary ./sample-app-chart \
  -f canary-values.yaml
```

Verify:

```bash
kubectl get deployments
kubectl get pods
```

Test traffic distribution:

```bash
for i in {1..20}; do
  curl -s -H "Host: sample-app.local" http://localhost/ |
    grep -o "Version [0-9.]*"
  sleep 1
done
```

### 📊 Canary Flow

```text
                  Incoming Traffic
                         │
                         ▼
                 ┌───────────────┐
                 │ NGINX Ingress │
                 └───────┬───────┘
                         │
              ┌──────────┴──────────┐
              │                     │
           90% │                  10%│
              ▼                     ▼
        🔵 Version 1          🐤 Version 2
          Production             Canary
```

---

# 📈 Task 10 — Promote Canary

Increase canary traffic to 50%:

```bash
helm upgrade sample-app-canary ./sample-app-chart \
  -f canary-values.yaml \
  --set ingress.annotations."nginx\.ingress\.kubernetes\.io/canary-weight"=50
```

Test:

```bash
for i in {1..20}; do
  curl -s -H "Host: sample-app.local" http://localhost/ |
    grep -o "Version [0-9.]*"
  sleep 1
done
```

Promote Version 2:

```bash
helm upgrade sample-app ./sample-app-chart \
  --set image.tag=v2.0
```

Remove the canary:

```bash
helm uninstall sample-app-canary
```

Verify:

```bash
kubectl get deployments

curl -H "Host: sample-app.local" http://localhost/
```

The source workflow moves from limited canary exposure to 50% traffic and finally promotes Version 2 to the main application.

---

# 🔵🟢 Task 11 — Blue-Green Deployment

Blue-green deployments maintain two application environments:

* 🔵 **Blue** — current production version
* 🟢 **Green** — new version

Create `green-values.yaml`:

```yaml
replicaCount: 3

image:
  repository: sample-app
  pullPolicy: Never
  tag: "v2.0"

nameOverride: "green"
fullnameOverride: "sample-app-green"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false

blueGreen:
  enabled: true
  environment: "green"
```

Deploy Green:

```bash
helm install sample-app-green ./sample-app-chart \
  -f green-values.yaml
```

Verify:

```bash
kubectl get deployments
kubectl get services
```

Test Green:

```bash
kubectl port-forward service/sample-app-green 8080:80 &
PORT_FORWARD_PID=$!

curl http://localhost:8080/

kill $PORT_FORWARD_PID
```

The source lab deploys Version 2 as the Green environment while keeping the existing environment available for comparison and traffic switching.

---

# 🔀 Task 12 — Switch Blue-Green Traffic

Create a traffic-switching script:

```bash
cat << 'EOF' > switch-traffic.sh
#!/bin/bash

ENVIRONMENT=$1

if [ "$ENVIRONMENT" = "blue" ]; then
    kubectl patch ingress sample-app-sample-app-chart -p '{"spec":{"rules":[{"host":"sample-app.local","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"sample-app-sample-app-chart","port":{"number":80}}}}]}}]}}'
    echo "Traffic switched to BLUE environment"

elif [ "$ENVIRONMENT" = "green" ]; then
    kubectl patch ingress sample-app-sample-app-chart -p '{"spec":{"rules":[{"host":"sample-app.local","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"sample-app-green","port":{"number":80}}}}]}}]}}'
    echo "Traffic switched to GREEN environment"

else
    echo "Usage: $0 [blue|green]"
    exit 1
fi
EOF

chmod +x switch-traffic.sh
```

Switch to Green:

```bash
./switch-traffic.sh green

curl -H "Host: sample-app.local" http://localhost/
```

Switch back to Blue:

```bash
./switch-traffic.sh blue

curl -H "Host: sample-app.local" http://localhost/
```

### 🔄 Blue-Green Flow

```text
              🌐 User Traffic
                    │
                    ▼
              NGINX Ingress
                    │
           ┌────────┴────────┐
           │                 │
           ▼                 ▼
       🔵 BLUE            🟢 GREEN
       v1.0                v2.0
           │                 │
           └───────┬─────────┘
                   │
              Switch Traffic
```

---

# 📊 Task 13 — Deployment Monitoring

Create `monitor-deployment.sh`:

```bash
#!/bin/bash

DEPLOYMENT_NAME=$1
NAMESPACE=${2:-default}

if [ -z "$DEPLOYMENT_NAME" ]; then
    echo "Usage: $0 <deployment-name> [namespace]"
    exit 1
fi

echo "Monitoring deployment: $DEPLOYMENT_NAME in namespace: $NAMESPACE"

kubectl rollout status deployment/$DEPLOYMENT_NAME \
  -n $NAMESPACE \
  --timeout=300s

echo -e "\nFinal Deployment Status:"
kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE

echo -e "\nPod Status:"
kubectl get pods \
  -l app.kubernetes.io/name=$(echo $DEPLOYMENT_NAME | cut -d'-' -f1) \
  -n $NAMESPACE

echo -e "\nRollout History:"
kubectl rollout history deployment/$DEPLOYMENT_NAME -n $NAMESPACE
```

Make it executable:

```bash
chmod +x monitor-deployment.sh
```

Run:

```bash
./monitor-deployment.sh sample-app-sample-app-chart
```

---

# ❤️ Task 14 — Health Check Script

Create `health-check.sh`:

```bash
#!/bin/bash

URL=$1
EXPECTED_VERSION=$2
MAX_ATTEMPTS=${3:-30}
DELAY=${4:-2}

if [ -z "$URL" ] || [ -z "$EXPECTED_VERSION" ]; then
    echo "Usage: $0 <url> <expected-version> [max-attempts] [delay]"
    exit 1
fi

echo "Health checking $URL for version $EXPECTED_VERSION"

for i in $(seq 1 $MAX_ATTEMPTS); do
    echo -n "Attempt $i: "

    RESPONSE=$(curl -s -H "Host: sample-app.local" $URL 2>/dev/null)

    if echo "$RESPONSE" | grep -q "Version $EXPECTED_VERSION"; then
        echo "SUCCESS - Found expected version $EXPECTED_VERSION"
        exit 0
    else
        FOUND_VERSION=$(echo "$RESPONSE" |
          grep -o "Version [0-9.]*" || echo "No version found")

        echo "WAITING - Found: $FOUND_VERSION"
    fi

    sleep $DELAY
done

echo "FAILED - Expected version not found"
exit 1
```

Make executable:

```bash
chmod +x health-check.sh
```

Test:

```bash
./health-check.sh http://localhost/ "1.0" 5 1
```

---

# 🤖 Task 15 — Automated Rollback

The lab introduces an automated rollback workflow that:

1. Stores the current Helm revision
2. Performs an upgrade
3. Waits for Kubernetes rollout completion
4. Performs a health check
5. Automatically rolls back when deployment or health validation fails

Example usage:

```bash
./auto-rollback.sh \
  sample-app \
  ./sample-app-chart \
  v999.0 \
  http://localhost/
```

Test a successful deployment:

```bash
./auto-rollback.sh \
  sample-app \
  ./sample-app-chart \
  v2.0 \
  http://localhost/
```

### 🤖 Automated Deployment Flow

```text
        🚀 New Release
              │
              ▼
       Helm Upgrade
              │
              ▼
       Kubernetes Rollout
              │
        ┌─────┴─────┐
        │           │
     Success      Failure
        │           │
        ▼           ▼
   Health Check   ↩️ Rollback
        │
   ┌────┴────┐
   │         │
Healthy    Unhealthy
   │         │
   ▼         ▼
 ✅ Done   ↩️ Rollback
```

---

# 🧪 Task 16 — Verification and Testing

Verify Deployments:

```bash
kubectl get deployments
```

Verify Services:

```bash
kubectl get services
```

Verify Ingress:

```bash
kubectl get ingress
```

Verify Helm releases:

```bash
helm list
```

Test application:

```bash
curl -H "Host: sample-app.local" http://localhost/
```

Check rollout history:

```bash
kubectl rollout history deployment/sample-app-sample-app-chart

helm history sample-app
```

These verification commands cover the primary Kubernetes resources, Helm releases, application accessibility, and deployment history required by the lab.

---

# ⚡ Task 17 — Performance Testing

Create a simple load-testing script:

```bash
cat << 'EOF' > load-test.sh
#!/bin/bash

URL=${1:-http://localhost/}
REQUESTS=${2:-100}
CONCURRENT=${3:-10}

echo "Load testing $URL with $REQUESTS requests, $CONCURRENT concurrent"

for i in $(seq 1 $CONCURRENT); do
    (
        for j in $(seq 1 $((REQUESTS/CONCURRENT))); do
            curl -s -H "Host: sample-app.local" \
              $URL > /dev/null
            echo -n "."
        done
    ) &
done

wait

echo -e "\nLoad test completed"
EOF

chmod +x load-test.sh
```

Run:

```bash
./load-test.sh http://localhost/ 50 5
```

The provided lab uses 50 requests with 5 concurrent workers as its example load test.

---

# 🔍 Useful Kubernetes Commands

### 📦 Pods

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### 🚀 Deployments

```bash
kubectl get deployments
kubectl describe deployment <deployment-name>
kubectl rollout status deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>
```

### ↩️ Rollback

```bash
kubectl rollout undo deployment/<deployment-name>

kubectl rollout undo deployment/<deployment-name> \
  --to-revision=<revision-number>
```

### ⛵ Helm

```bash
helm list
helm status sample-app
helm history sample-app
helm upgrade sample-app ./sample-app-chart
helm rollback sample-app <revision>
helm uninstall sample-app
```

---

# 🐛 Troubleshooting

## ❌ Pods Stuck in Pending

Check node resources:

```bash
kubectl describe nodes
```

Inspect Pod events:

```bash
kubectl describe pod <pod-name>
```

Check resource requests:

```bash
kubectl get pods -o yaml | grep -A 5 resources
```

---

## ❌ Ingress Not Working

Check the controller:

```bash
kubectl get pods -n ingress-nginx
```

Inspect Ingress:

```bash
kubectl describe ingress
```

Check endpoints:

```bash
kubectl get endpoints
```

---

## ❌ Helm Upgrade Fails

Check release status:

```bash
helm status <release-name>
```

Run a debug dry run:

```bash
helm upgrade <release-name> <chart> \
  --debug \
  --dry-run
```

If required:

```bash
helm upgrade <release-name> <chart> --force
```

---

## ❌ Rollback Not Working

Check rollout history:

```bash
kubectl rollout history deployment/<deployment-name>
```

Rollback to a specific revision:

```bash
kubectl rollout undo deployment/<deployment-name> \
  --to-revision=<revision-number>
```

Check the final status:

```bash
kubectl rollout status deployment/<deployment-name>
```

These troubleshooting scenarios and commands are included in the original lab material.

---

# 🧹 Cleanup

Remove Helm releases:

```bash
helm uninstall sample-app

helm uninstall sample-app-green 2>/dev/null || true
```

Delete the kind cluster:

```bash
kind delete cluster --name=helm-lab
```

Remove the local host entry:

```bash
sudo sed -i '/sample-app.local/d' /etc/hosts
```

Remove the lab directory:

```bash
rm -rf ~/helm-lab
```

The cleanup procedure removes the Helm releases, kind cluster, local host configuration, and lab files.

---

# 📚 Deployment Strategy Comparison

| Strategy              | Main Purpose                                   | Traffic Approach            | Rollback               |
| --------------------- | ---------------------------------------------- | --------------------------- | ---------------------- |
| 🔄 Rolling Update     | Gradual replacement                            | Mixed during rollout        | Fast                   |
| 🐤 Canary             | Test new release with limited users            | Percentage-based            | Very fast              |
| 🔵🟢 Blue-Green       | Maintain two complete environments             | Switch between environments | Instant traffic switch |
| ↩️ Helm Rollback      | Recover from failed release                    | Previous revision           | Fast                   |
| 🤖 Automated Rollback | Automatically recover after validation failure | Automated                   | Automatic              |

---

# 🧠 Key Concepts Learned

### ⛵ Helm

Helm provides package management and release management for Kubernetes applications.

### 🔄 Rolling Update

Gradually replaces old Pods with new Pods while attempting to maintain application availability.

### 🐤 Canary Deployment

Introduces a new version to a small percentage of traffic before increasing exposure.

### 🔵🟢 Blue-Green Deployment

Maintains two environments and switches traffic between them after validating the new version.

### ↩️ Rollback

Returns an application to a previously working release or deployment revision.

### ❤️ Health Check

Validates that the expected application version is responding correctly.

### 🤖 Progressive Delivery

Controls application rollout gradually to reduce deployment risk.

---

# 🏆 Lab Completion Checklist

* [ ] 🐳 Docker installed and configured
* [ ] ☸️ kubectl installed
* [ ] 🧰 kind installed
* [ ] ⛵ Helm installed
* [ ] ☸️ kind Kubernetes cluster created
* [ ] 🌐 NGINX Ingress Controller installed
* [ ] 📦 Sample application created
* [ ] 🏗️ Docker images v1.0 and v2.0 built
* [ ] ⛵ Helm chart created
* [ ] 🔄 Rolling update completed
* [ ] 📜 Rollout history inspected
* [ ] ↩️ Manual rollback tested
* [ ] 🐤 Canary deployment implemented
* [ ] 📈 Canary traffic promoted
* [ ] 🔵🟢 Blue-green deployment implemented
* [ ] 🔀 Traffic switching tested
* [ ] 📊 Deployment monitoring configured
* [ ] ❤️ Health check script tested
* [ ] 🤖 Automated rollback tested
* [ ] ⚡ Load test executed
* [ ] 🧹 Lab environment cleaned up

---

# 🎓 Conclusion

This lab demonstrates a complete **Helm and Kubernetes progressive delivery workflow**.

You configured a local Kubernetes environment with kind, created a Helm-managed application, and implemented multiple production-oriented deployment strategies including **rolling updates, canary deployments, blue-green deployments, and rollback mechanisms**.

You also created monitoring, health-check, automated rollback, and load-testing scripts to improve deployment reliability.

These techniques help DevOps and platform engineers achieve:

* 🛡️ Reduced deployment risk
* ⚡ Faster recovery
* 🔄 Safer application updates
* 🟢 Improved availability
* 📊 Better deployment visibility
* 🚀 Controlled progressive delivery

The combination of **Helm + Kubernetes** provides a strong foundation for reliable and enterprise-oriented application deployment workflows.

---

## 🛠️ Technology Stack

<p align="center">

<img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black">
<img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white">
<img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white">
<img src="https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white">
<img src="https://img.shields.io/badge/kind-FF6B6B?style=for-the-badge&logo=kubernetes&logoColor=white">
<img src="https://img.shields.io/badge/kubectl-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white">
<img src="https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white">
<img src="https://img.shields.io/badge/Bash-121011?style=for-the-badge&logo=gnu-bash&logoColor=white">

</p>

---

<p align="center">
  <b>🚀 Helm • Kubernetes • Progressive Delivery • DevOps</b>
</p>

<p align="center">
  ⭐ Keep Learning • Keep Automating • Keep Deploying ⭐
</p>

# 🚀 Helm in Multi-Cluster Environments

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"/>
  <img src="https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm"/>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/kind-2D3748?style=for-the-badge&logo=kubernetes&logoColor=white" alt="kind"/>
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux"/>
  <img src="https://img.shields.io/badge/Bash-121011?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash"/>
</p>

<p align="center">
  <b>🌐 Multi-Cluster Kubernetes Deployment & Helm Automation Lab</b>
</p>

<p align="center">
  <i>Deploy, manage, update, monitor, and validate Helm applications across Development, Staging, and Production Kubernetes clusters.</i>
</p>

---

## 📖 Overview

This lab demonstrates how to use **Helm** to manage applications across multiple Kubernetes clusters running on a single Linux machine using **kind**.

Three separate Kubernetes environments are created:

* 🧪 **Development**
* 🔬 **Staging**
* 🚀 **Production**

A custom Helm chart is then configured with environment-specific values and deployed to each cluster.

The lab also introduces Bash automation scripts for:

* 🚀 Multi-cluster deployments
* 🔄 Cross-cluster application updates
* 📊 Cluster status checking
* 🛠️ Cluster management
* 🧹 Application cleanup
* 🔍 Resource monitoring
* ✅ Application connectivity testing

---

## 🎯 Lab Objectives

By completing this lab, you will learn how to:

* ⚓ Configure Helm for multiple Kubernetes clusters
* ☸️ Create multiple Kubernetes clusters using kind
* 🚀 Deploy applications across multiple clusters
* 🌎 Implement environment-specific Helm configurations
* 🔀 Manage multiple `kubectl` contexts
* 📦 Manage Helm releases across clusters
* 🤖 Automate deployments using Bash scripts
* 🔄 Perform controlled application updates
* 📊 Monitor cluster and application status
* 🔍 Validate cross-cluster deployments
* 🛡️ Apply multi-cluster management best practices

---

## 🧰 Technologies & Tools

| Technology            | Purpose                           |
| --------------------- | --------------------------------- |
| 🐧 **Linux**          | Lab operating system              |
| 🐳 **Docker**         | Container runtime                 |
| ☸️ **Kubernetes**     | Container orchestration           |
| 🏗️ **kind**          | Local Kubernetes cluster creation |
| ⚓ **Helm**            | Kubernetes package management     |
| 🔧 **kubectl**        | Kubernetes CLI                    |
| 🐚 **Bash**           | Deployment automation             |
| 🐘 **PostgreSQL**     | Database deployment               |
| 📦 **Bitnami Charts** | PostgreSQL Helm chart             |
| 🌐 **Nginx**          | Application workload              |

---

## 🏗️ Multi-Cluster Architecture

```text
                         ┌─────────────────────────┐
                         │       Linux Host        │
                         │                         │
                         │  Docker + kind + Helm   │
                         └────────────┬────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
       ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
       │ Development  │       │   Staging    │       │ Production   │
       │   Cluster    │       │   Cluster    │       │   Cluster    │
       ├──────────────┤       ├──────────────┤       ├──────────────┤
       │ dev-cluster  │       │staging-cluster│      │ prod-cluster │
       │              │       │              │       │              │
       │ web-apps     │       │ web-apps     │       │ web-apps     │
       │ databases    │       │ databases    │       │ databases    │
       │ monitoring   │       │ monitoring   │       │ monitoring   │
       └──────────────┘       └──────────────┘       └──────────────┘
              │                       │                       │
              └───────────────────────┼───────────────────────┘
                                      │
                              ┌───────▼────────┐
                              │ Helm Releases  │
                              │ + Automation   │
                              └────────────────┘
```

---

# 🛠️ Lab Setup

## 🔰 Step 1 — Update the Linux System

```bash
sudo apt update

sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
```

✅ **Purpose:** Prepare the Linux system with the packages required for Docker and Kubernetes tooling.

---

## 🐳 Step 2 — Install Docker

### Add Docker GPG Key

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor \
-o /usr/share/keyrings/docker-archive-keyring.gpg
```

### Add Docker Repository

```bash
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Install Docker

```bash
sudo apt update

sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io
```

### Add Current User to Docker Group

```bash
sudo usermod -aG docker $USER
```

### Start and Enable Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

🎯 **Result:** Docker is ready to provide the container runtime used by kind.

---

## ☸️ Step 3 — Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

### Verify

```bash
kubectl version --client
```

✅ **Expected:** The kubectl client version should be displayed.

---

## 🏗️ Step 4 — Install kind

```bash
curl -Lo ./kind \
https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

chmod +x ./kind

sudo mv ./kind /usr/local/bin/kind
```

### Verify

```bash
kind version
```

🎯 **Purpose:** kind creates Kubernetes clusters using Docker containers.

---

## ⚓ Step 5 — Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Verify

```bash
helm version
```

🎉 **Helm is now ready for Kubernetes application management.**

---

## 🔄 Step 6 — Apply Docker Group Changes

```bash
newgrp docker
```

> 💡 Alternatively, log out and log back in.

---

# ☸️ Task 1 — Create Multiple Kubernetes Clusters

## 🏭 Step 7 — Create Production Cluster Configuration

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: production

nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "environment=production"

- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "environment=production"
```

Save as:

```text
prod-cluster-config.yaml
```

---

## 🧪 Step 8 — Create Staging Cluster Configuration

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: staging

nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "environment=staging"

- role: worker
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "environment=staging"
```

Save as:

```text
staging-cluster-config.yaml
```

---

## 💻 Step 9 — Create Development Cluster Configuration

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: development

nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "environment=development"
```

Save as:

```text
dev-cluster-config.yaml
```

---

## 🚀 Step 10 — Create All Three Clusters

```bash
kind create cluster --config=prod-cluster-config.yaml

kind create cluster --config=staging-cluster-config.yaml

kind create cluster --config=dev-cluster-config.yaml
```

---

## 🔍 Step 11 — Verify Clusters

```bash
kind get clusters
```

Expected environments:

```text
production
staging
development
```

Check Kubernetes contexts:

```bash
kubectl config get-contexts
```

🎯 **Milestone:** Three independent Kubernetes clusters are now available.

---

# 🔀 Task 2 — Configure kubectl Contexts

## 🏷️ Step 12 — Rename Contexts

```bash
kubectl config rename-context kind-production prod-cluster

kubectl config rename-context kind-staging staging-cluster

kubectl config rename-context kind-development dev-cluster
```

Verify:

```bash
kubectl config get-contexts
```

---

## 🔌 Step 13 — Test Cluster Connectivity

### Development

```bash
kubectl config use-context dev-cluster
kubectl get nodes -o wide
```

### Staging

```bash
kubectl config use-context staging-cluster
kubectl get nodes -o wide
```

### Production

```bash
kubectl config use-context prod-cluster
kubectl get nodes -o wide
```

✅ **Success Indicator:** Each context should return the nodes belonging to its cluster.

---

# ⚓ Task 3 — Configure Helm

## 📚 Step 14 — Add Helm Repositories

### Production

```bash
kubectl config use-context prod-cluster

helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update
```

### Staging

```bash
kubectl config use-context staging-cluster

helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update
```

### Development

```bash
kubectl config use-context dev-cluster

helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update
```

---

## 📁 Step 15 — Create Namespaces

Each cluster receives:

```text
web-apps
databases
monitoring
```

### Development

```bash
kubectl config use-context dev-cluster

kubectl create namespace web-apps
kubectl create namespace databases
kubectl create namespace monitoring
```

### Staging

```bash
kubectl config use-context staging-cluster

kubectl create namespace web-apps
kubectl create namespace databases
kubectl create namespace monitoring
```

### Production

```bash
kubectl config use-context prod-cluster

kubectl create namespace web-apps
kubectl create namespace databases
kubectl create namespace monitoring
```

---

# 📦 Task 4 — Create a Custom Helm Chart

## 🏗️ Step 16 — Generate Helm Chart

```bash
helm create multi-cluster-app

cd multi-cluster-app
```

The resulting chart provides the basic structure for deploying the application across all environments.

---

## ⚙️ Step 17 — Configure Default Values

The chart uses:

```yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

environment:
  name: "default"
  config:
    database_url: "localhost:5432"
    api_endpoint: "http://localhost:8080"
    log_level: "info"
```

Additional configuration includes:

* 🧠 Resource requests and limits
* 🔄 Autoscaling
* 🌐 Service configuration
* 🔐 Environment configuration
* 🏷️ Node selectors
* ⚖️ Affinity
* 🚧 Tolerations

---

# 🚀 Task 5 — Environment-Specific Configuration

## 🟢 Production

Production is configured with:

* 3 replicas
* Higher CPU and memory allocations
* Autoscaling from 3 to 10 replicas
* Production API endpoint
* Warning-level logging

```yaml
replicaCount: 3

environment:
  name: "production"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
```

---

## 🟡 Staging

Staging uses:

* 2 replicas
* Moderate resource allocation
* Autoscaling from 2 to 5 replicas
* Debug logging

```yaml
replicaCount: 2

environment:
  name: "staging"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
```

---

## 🔵 Development

Development uses:

* 1 replica
* Lower resource allocation
* Autoscaling disabled
* Debug logging

```yaml
replicaCount: 1

environment:
  name: "development"

autoscaling:
  enabled: false
```

---

# 🧩 Task 6 — Environment-Aware Helm Deployment

The deployment template uses Helm variables such as:

```yaml
environment: {{ .Values.environment.name }}
```

Environment variables are injected into the container:

```yaml
env:
  - name: ENVIRONMENT
    value: {{ .Values.environment.name }}

  - name: DATABASE_URL
    value: {{ .Values.environment.config.database_url }}

  - name: API_ENDPOINT
    value: {{ .Values.environment.config.api_endpoint }}

  - name: LOG_LEVEL
    value: {{ .Values.environment.config.log_level }}
```

🎯 **Benefit:** One Helm chart can be reused across multiple environments while environment-specific settings remain in separate values files.

---

# 🚀 Task 7 — Deploy Across Multiple Clusters

## 🔵 Step 18 — Development Deployment

```bash
kubectl config use-context dev-cluster

helm install dev-app . \
  -f values-dev.yaml \
  -n web-apps
```

Verify:

```bash
kubectl get pods -n web-apps
kubectl get services -n web-apps
```

---

## 🟡 Step 19 — Staging Deployment

```bash
kubectl config use-context staging-cluster

helm install staging-app . \
  -f values-staging.yaml \
  -n web-apps
```

Verify:

```bash
kubectl get pods -n web-apps
kubectl get services -n web-apps
```

---

## 🟢 Step 20 — Production Deployment

```bash
kubectl config use-context prod-cluster

helm install prod-app . \
  -f values-prod.yaml \
  -n web-apps
```

Verify:

```bash
kubectl get pods -n web-apps
kubectl get services -n web-apps
```

---

# 🤖 Task 8 — Automate Multi-Cluster Deployment

## 🚀 `deploy-multi-cluster.sh`

The deployment script automates:

1. Context switching
2. Namespace verification
3. Helm deployment
4. Release upgrades
5. Rollout verification

Example:

```bash
./deploy-multi-cluster.sh
```

The deployment order is:

```text
Development
     ↓
Staging
     ↓
Production
```

---

# 📊 Task 9 — Cluster Status Management

## 🔍 `check-multi-cluster-status.sh`

The status script checks:

* ⚓ Helm releases
* 🟢 Pod status
* 🌐 Services
* 📦 Deployment details

Run:

```bash
./check-multi-cluster-status.sh
```

---

# 🔄 Task 10 — Cross-Cluster Application Updates

## 🛠️ `update-multi-cluster.sh`

The update script supports controlled application updates.

Default image tag:

```text
1.22
```

Run:

```bash
./update-multi-cluster.sh 1.22
```

Deployment sequence:

```text
Development
      ↓
Staging
      ↓
Production
```

🎯 This provides a simple progressive deployment workflow.

---

# 🐘 Task 11 — Deploy PostgreSQL

PostgreSQL is deployed using the Bitnami Helm chart.

## 🔵 Development

```bash
kubectl config use-context dev-cluster

helm install dev-postgres bitnami/postgresql \
  --set auth.postgresPassword=devpassword \
  --set primary.persistence.size=1Gi \
  -n databases
```

## 🟡 Staging

```bash
kubectl config use-context staging-cluster

helm install staging-postgres bitnami/postgresql \
  --set auth.postgresPassword=stagingpassword \
  --set primary.persistence.size=2Gi \
  --set primary.resources.requests.memory=256Mi \
  -n databases
```

## 🟢 Production

```bash
kubectl config use-context prod-cluster

helm install prod-postgres bitnami/postgresql \
  --set auth.postgresPassword=prodpassword \
  --set primary.persistence.size=5Gi \
  --set primary.resources.requests.memory=512Mi \
  --set primary.resources.limits.memory=1Gi \
  -n databases
```

> ⚠️ **Security Note:** The lab demonstrates passwords directly in commands. In a real production environment, use Kubernetes Secrets, an external secrets manager, or another secure secret-management mechanism rather than committing credentials to Git.

---

# 🔎 Task 12 — Verify PostgreSQL

### Development

```bash
kubectl config use-context dev-cluster

kubectl get pods -n databases
kubectl get pvc -n databases
```

### Staging

```bash
kubectl config use-context staging-cluster

kubectl get pods -n databases
kubectl get pvc -n databases
```

### Production

```bash
kubectl config use-context prod-cluster

kubectl get pods -n databases
kubectl get pvc -n databases
```

---

# 🛠️ Task 13 — Cluster Management Automation

## `manage-clusters.sh`

The management utility provides several commands:

```text
status
deploy
update
cleanup
resources
help
```

### Display Help

```bash
./manage-clusters.sh --help
```

### Check Status

```bash
./manage-clusters.sh status
```

### Show Resources

```bash
./manage-clusters.sh resources
```

### Update Applications

```bash
./manage-clusters.sh update 1.22
```

### Cleanup

```bash
./manage-clusters.sh cleanup
```

---

# 🧪 Verification & Testing

## 🔍 Step 14 — Verify Helm Releases

### Development

```bash
kubectl config use-context dev-cluster
helm list --all-namespaces
```

### Staging

```bash
kubectl config use-context staging-cluster
helm list --all-namespaces
```

### Production

```bash
kubectl config use-context prod-cluster
helm list --all-namespaces
```

---

## 🌐 Step 15 — Test Application Connectivity

The lab uses Kubernetes port forwarding to test the deployed application.

```bash
kubectl port-forward \
  service/dev-app-multi-cluster-app \
  8080:80 \
  -n web-apps
```

Then test:

```bash
curl -s http://localhost:8080 | head -n 5
```

Repeat the connectivity validation for staging and production.

---

## 🔐 Step 16 — Validate Environment Variables

Retrieve the application pod:

```bash
kubectl get pods \
  -n web-apps \
  -l app.kubernetes.io/name=multi-cluster-app
```

Inspect environment variables:

```bash
kubectl exec <POD_NAME> \
  -n web-apps -- \
  env | grep -E \
  "(ENVIRONMENT|DATABASE_URL|API_ENDPOINT|LOG_LEVEL)"
```

🎯 This confirms that each cluster receives its intended environment-specific configuration.

---

# 🐛 Troubleshooting

## ❌ Cluster Creation Failure

Check Docker:

```bash
sudo systemctl status docker
```

Restart Docker:

```bash
sudo systemctl restart docker
```

Remove failed clusters:

```bash
kind delete clusters --all
```

Recreate a cluster:

```bash
kind create cluster \
  --config=dev-cluster-config.yaml
```

---

## ❌ Helm Deployment Failure

Check Helm release status:

```bash
helm status <release-name> -n <namespace>
```

Inspect deployment:

```bash
kubectl describe deployment \
  <deployment-name> \
  -n <namespace>
```

Check application logs:

```bash
kubectl logs \
  -l app.kubernetes.io/name=multi-cluster-app \
  -n <namespace>
```

---

## ❌ kubectl Context Problem

List contexts:

```bash
kubectl config get-contexts
```

Switch manually:

```bash
kubectl config use-context <context-name>
```

Check the active context:

```bash
kubectl config current-context
```

---

# 🏆 Multi-Cluster Best Practices

## 🌍 1. Environment Separation

✅ Use separate values files
✅ Use environment-specific configurations
✅ Define appropriate resource requests and limits

---

## 🚀 2. Progressive Deployment

Recommended workflow:

```text
       ┌──────────────┐
       │ Development  │
       └──────┬───────┘
              │
              ▼
       ┌──────────────┐
       │   Staging    │
       └──────┬───────┘
              │
              ▼
       ┌──────────────┐
       │ Production   │
       └──────────────┘
```

✅ Test development
✅ Validate staging
✅ Deploy production
✅ Implement rollback procedures

---

## 🔐 3. Security

✅ Use separate secrets for each environment
✅ Implement RBAC
✅ Protect cluster credentials
✅ Secure inter-cluster communication
✅ Never commit production credentials to Git

---

## 📊 4. Monitoring & Observability

A production implementation should consider:

* 📈 Resource monitoring
* 📝 Centralized logging
* 🚨 Deployment alerts
* 🔍 Application health checks
* 📊 Cluster-wide metrics

---

# 📂 Suggested Project Structure

```text
multi-cluster-helm/
│
├── multi-cluster-app/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   ├── values-prod.yaml
│   │
│   ├── templates/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── ...
│   │
│   └── charts/
│
├── prod-cluster-config.yaml
├── staging-cluster-config.yaml
├── dev-cluster-config.yaml
│
├── deploy-multi-cluster.sh
├── check-multi-cluster-status.sh
├── update-multi-cluster.sh
└── manage-clusters.sh
```

---

# 🎓 Learning Outcomes

After completing this lab, you should understand how to:

```text
☸️ Create multiple Kubernetes clusters
        ↓
🔀 Manage kubectl contexts
        ↓
⚓ Configure Helm
        ↓
📦 Build reusable Helm charts
        ↓
⚙️ Create environment-specific values
        ↓
🚀 Deploy applications
        ↓
🤖 Automate deployments
        ↓
🔄 Perform controlled updates
        ↓
📊 Monitor cluster resources
        ↓
🔍 Validate application behavior
```

---

# 🏁 Conclusion

This lab demonstrates a practical **multi-cluster Helm management workflow** using kind, Kubernetes, Docker, Helm, kubectl, Bash automation, and PostgreSQL.

You created:

* ☸️ Development, staging, and production Kubernetes clusters
* ⚓ Helm repositories and releases
* 📦 A reusable multi-cluster Helm chart
* ⚙️ Environment-specific values files
* 🚀 Automated deployment workflows
* 🔄 Cross-cluster update automation
* 📊 Status and resource-management scripts
* 🐘 PostgreSQL deployments
* 🔍 Connectivity and configuration validation

The resulting workflow provides a foundation for more advanced enterprise DevOps practices such as **GitOps, CI/CD integration, automated testing, security scanning, compliance validation, centralized observability, and progressive delivery**.

---

## ⭐ Key Takeaways

> 💡 **One Helm chart + multiple values files = reusable multi-environment deployments.**

> 🔀 **kubectl contexts make it possible to manage multiple clusters from one machine.**

> 🤖 **Automation scripts reduce repetitive multi-cluster operations.**

> 🚀 **Development → Staging → Production provides a controlled deployment path.**

> 🔐 **Production environments require proper secret management and RBAC.**

---

## 🏅 Skills Demonstrated

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-Expertise-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white"/>
  <img src="https://img.shields.io/badge/Helm-Charts-0F1689?style=for-the-badge&logo=helm&logoColor=white"/>
  <img src="https://img.shields.io/badge/Docker-Containers-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
  <img src="https://img.shields.io/badge/Bash-Automation-121011?style=for-the-badge&logo=gnubash&logoColor=white"/>
  <img src="https://img.shields.io/badge/DevOps-Multi--Cluster-orange?style=for-the-badge"/>
</p>

<p align="center">
  <b>🚀 Learn • Automate • Deploy • Monitor • Scale 🚀</b>
</p>

# Installing Helm

## 📦 Lab Overview

This lab provides a hands-on introduction to **Helm**, the package manager for Kubernetes. You will build a local Kubernetes environment using **Docker, kubectl, and Minikube**, install Helm, connect it to the Kubernetes cluster, configure Helm repositories, deploy an NGINX application, and practice essential Helm release-management operations.

The lab is designed to establish the foundation required for managing Kubernetes applications with Helm in modern DevOps and GitOps environments.

---

## 🎯 Lab Objectives

By the end of this lab, you will be able to:

* Understand Helm and its role in Kubernetes package management.
* Install Helm on a Linux system.
* Configure Helm to communicate with a Kubernetes cluster.
* Add and manage Helm chart repositories.
* Search for and inspect Helm charts.
* Install applications using Helm charts.
* Manage Helm releases using common commands.
* Upgrade and roll back Helm releases.
* Customize deployments using Helm values files.
* Render Kubernetes manifests using `helm template`.
* Troubleshoot common Helm, Kubernetes, Docker, and Minikube issues.
* Clean up Helm releases and Kubernetes resources.

---

## 📋 Prerequisites

Before starting this lab, you should have:

* Basic knowledge of Linux command-line operations.
* Fundamental understanding of Kubernetes concepts.
* Familiarity with Pods, Services, and Deployments.
* Basic knowledge of YAML syntax.
* Basic understanding of package managers.
* Access to a Linux-based lab environment.

---

## 🖥️ Lab Environment

This lab uses an **Al Nafi Linux cloud machine**.

The provided machine is initially bare metal without the required Kubernetes tooling, so you will install the necessary components during the lab.

### Tools Used

| Tool               | Purpose                        |
| ------------------ | ------------------------------ |
| Linux              | Lab operating system           |
| Docker             | Container runtime              |
| kubectl            | Kubernetes command-line client |
| Minikube           | Local Kubernetes cluster       |
| Helm 3             | Kubernetes package manager     |
| NGINX              | Test application               |
| Bitnami Repository | Helm chart source              |

---

# 🔎 What Is Helm?

**Helm** is a package manager for Kubernetes. It simplifies the deployment and management of Kubernetes applications by packaging Kubernetes resources into reusable **Helm Charts**.

A Helm Chart can contain:

* Deployments
* Services
* ConfigMaps
* Secrets
* Ingress resources
* ServiceAccounts
* PersistentVolumeClaims
* RBAC resources
* Other Kubernetes manifests

Instead of manually managing many YAML files, Helm allows applications to be installed and configured using reusable charts and values.

### Helm Architecture

```text
             Helm CLI
                |
                v
        Helm Chart Repository
                |
                v
          Helm Chart
                |
                v
       Kubernetes Cluster
                |
        +-------+-------+
        |       |       |
      Pods   Services  Config
```

---

# 🚀 Task 1: Set Up the Environment

## 1.1 Update System Packages

Update the Linux package index and upgrade installed packages:

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 1.2 Install Required Dependencies

Install the utilities required throughout the lab:

```bash
sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release
```

Verify the tools:

```bash
curl --version
wget --version
```

---

# 🐳 1.3 Install Docker

Docker will be used as the container driver for Minikube.

### Add Docker's GPG Key

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### Add Docker Repository

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Update Package Index

```bash
sudo apt update
```

### Install Docker

```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io
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

Refresh the current shell:

```bash
newgrp docker
```

Verify Docker:

```bash
docker --version
```

Test Docker:

```bash
docker run hello-world
```

---

# ☸️ 1.4 Install kubectl

`kubectl` is the command-line tool used to communicate with Kubernetes.

Download the latest stable Linux AMD64 release:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

Make it executable:

```bash
chmod +x kubectl
```

Move it into the system PATH:

```bash
sudo mv kubectl /usr/local/bin/
```

Verify:

```bash
kubectl version --client
```

---

# ⛵ 1.5 Install Minikube

Minikube creates a local Kubernetes cluster suitable for this lab.

Download Minikube:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
```

Make it executable:

```bash
chmod +x minikube-linux-amd64
```

Move it into the system PATH:

```bash
sudo mv minikube-linux-amd64 /usr/local/bin/minikube
```

Verify:

```bash
minikube version
```

---

# ☸️ 1.6 Start the Kubernetes Cluster

Start Minikube using Docker:

```bash
minikube start --driver=docker
```

Check the cluster:

```bash
kubectl cluster-info
```

Check Kubernetes nodes:

```bash
kubectl get nodes
```

Expected output should show the Minikube node in a `Ready` state.

---

# ⎈ Task 2: Install Helm

## 2.1 Install Helm Using the Official Script

Install Helm 3 using the official installation script:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify that Helm is available:

```bash
which helm
```

---

## Alternative: Manual Helm Installation

Download a Helm release:

```bash
wget https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz
```

Extract the archive:

```bash
tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
```

Move the Helm binary:

```bash
sudo mv linux-amd64/helm /usr/local/bin/helm
```

Clean up:

```bash
rm -rf linux-amd64 helm-v3.13.0-linux-amd64.tar.gz
```

> **Note:** For new environments, prefer the official installation method or a currently supported Helm release rather than relying on an old hard-coded version.

---

# 🔍 2.2 Verify Helm Installation

Check the Helm version:

```bash
helm version
```

Display Helm help:

```bash
helm help
```

You should receive Helm build information similar to:

```text
version.BuildInfo{Version:"v3.x.x", ...}
```

---

# 🔗 Task 3: Configure Helm with Kubernetes

## 3.1 Verify Kubernetes Context

Check the active Kubernetes context:

```bash
kubectl config current-context
```

With Minikube, the expected context is generally:

```text
minikube
```

Verify Kubernetes access:

```bash
kubectl get nodes
```

Test Helm against the cluster:

```bash
helm list
```

An empty release list is acceptable. The important point is that the command completes without a Kubernetes connection error.

---

# 📦 3.2 Add Helm Repositories

Add the Bitnami repository:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Update repository information:

```bash
helm repo update
```

List repositories:

```bash
helm repo list
```

### About the Old Stable Repository

The historical Helm `stable` repository was retired. Therefore, this lab focuses on the Bitnami repository rather than depending on the legacy:

```text
https://charts.helm.sh/stable
```

---

# 🔎 3.3 Search Helm Charts

Search for NGINX:

```bash
helm search repo nginx
```

Search Bitnami charts:

```bash
helm search repo bitnami
```

Inspect the NGINX chart:

```bash
helm show chart bitnami/nginx
```

Display available chart values:

```bash
helm show values bitnami/nginx
```

---

# 🚀 Task 4: Test the Helm Installation

## 4.1 Install NGINX

Install an NGINX application using the Bitnami Helm chart:

```bash
helm install my-nginx bitnami/nginx
```

Check the release:

```bash
helm status my-nginx
```

List Helm releases:

```bash
helm list
```

---

# ☸️ 4.2 Verify the Deployment

Check Pods:

```bash
kubectl get pods
```

Check Services:

```bash
kubectl get services
```

Get detailed information about the NGINX Service:

```bash
kubectl describe service my-nginx
```

Wait for the Pods to become ready:

```bash
kubectl get pods -w
```

---

# 🌐 4.3 Access NGINX

Minikube can expose the Service locally.

Get the Service URL:

```bash
minikube service my-nginx --url
```

Test the returned URL:

```bash
curl $(minikube service my-nginx --url)
```

If the deployment is working correctly, the response should contain the NGINX welcome page.

---

# 🧰 4.4 Explore Helm Commands

### View Release History

```bash
helm history my-nginx
```

### View Configured Values

```bash
helm get values my-nginx
```

### View All Release Information

```bash
helm get all my-nginx
```

### Display Chart Information

```bash
helm show chart bitnami/nginx
```

### Display Chart Values

```bash
helm show values bitnami/nginx
```

These commands are useful when troubleshooting deployments and understanding how a Helm release was configured.

---

# 🔄 4.5 Upgrade and Roll Back a Release

Upgrade the NGINX release:

```bash
helm upgrade my-nginx bitnami/nginx --set service.type=NodePort
```

Check the release history:

```bash
helm history my-nginx
```

The upgrade should create a new revision.

Rollback to the first revision:

```bash
helm rollback my-nginx 1
```

Verify the history:

```bash
helm history my-nginx
```

This demonstrates one of Helm's major advantages: release revisions allow deployments to be rolled back when an upgrade causes problems.

---

# 🧹 4.6 Clean Up the Test Release

Uninstall the release:

```bash
helm uninstall my-nginx
```

Verify:

```bash
helm list
```

Check Kubernetes resources:

```bash
kubectl get pods
```

---

# ⚙️ Task 5: Advanced Helm Configuration

## 5.1 Create a Custom Values File

Create a custom values file:

```bash
cat > custom-nginx-values.yaml <<'EOF'
replicaCount: 2

service:
  type: NodePort
  port: 80

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

ingress:
  enabled: false
EOF
```

Review the file:

```bash
cat custom-nginx-values.yaml
```

---

# 🚀 5.2 Install Using Custom Values

Deploy NGINX with the custom configuration:

```bash
helm install custom-nginx bitnami/nginx -f custom-nginx-values.yaml
```

Check the Helm release:

```bash
helm status custom-nginx
```

Check the Pods:

```bash
kubectl get pods
```

Check the Service:

```bash
kubectl get services
```

---

# 🧩 5.3 Render Helm Templates

Helm can render Kubernetes manifests without actually installing the application.

Render the chart:

```bash
helm template custom-nginx bitnami/nginx \
  -f custom-nginx-values.yaml
```

Save the generated manifests:

```bash
helm template custom-nginx bitnami/nginx \
  -f custom-nginx-values.yaml > rendered-manifests.yaml
```

View the generated file:

```bash
cat rendered-manifests.yaml
```

This is especially useful for:

* Debugging charts.
* Reviewing generated manifests.
* Validating configurations.
* GitOps workflows.
* CI/CD pipelines.
* Security reviews.

---

# 🛠️ Troubleshooting

## Issue 1: Docker Permission Denied

If Docker returns permission errors:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Test:

```bash
docker ps
```

If the problem persists, log out and log back in.

---

## Issue 2: Minikube Will Not Start

Check Minikube status:

```bash
minikube status
```

Delete the existing cluster:

```bash
minikube delete
```

Start it again:

```bash
minikube start --driver=docker
```

Check the cluster:

```bash
kubectl get nodes
```

---

## Issue 3: Helm Repository Errors

List configured repositories:

```bash
helm repo list
```

Update them:

```bash
helm repo update
```

Remove and re-add Bitnami if necessary:

```bash
helm repo remove bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

---

## Issue 4: kubectl Cannot Connect to Kubernetes

Check the current context:

```bash
kubectl config current-context
```

Check Minikube:

```bash
minikube status
```

Update the context:

```bash
minikube update-context
```

Test the cluster:

```bash
kubectl get nodes
```

---

## Issue 5: Helm Release Is Not Ready

Check release status:

```bash
helm status custom-nginx
```

Check Pods:

```bash
kubectl get pods
```

Inspect a Pod:

```bash
kubectl describe pod <pod-name>
```

Check recent events:

```bash
kubectl get events --sort-by=.lastTimestamp
```

---

# ✅ Verification Checklist

Before completing the lab, verify the following:

* [ ] Docker is installed and running.
* [ ] `kubectl version --client` works.
* [ ] Minikube is installed.
* [ ] Minikube is running.
* [ ] `kubectl get nodes` shows a Ready node.
* [ ] `helm version` works.
* [ ] `helm repo list` displays the configured repository.
* [ ] `helm search repo nginx` returns chart results.
* [ ] A Helm chart can be installed.
* [ ] `helm list` displays installed releases.
* [ ] Kubernetes Pods are running.
* [ ] Kubernetes Services are available.
* [ ] `helm history` displays release revisions.
* [ ] A Helm release can be upgraded.
* [ ] A Helm release can be rolled back.
* [ ] A custom values file can be used.
* [ ] `helm template` successfully renders manifests.
* [ ] Helm releases can be uninstalled.

---

# 🧹 Lab Cleanup

Remove the custom NGINX release:

```bash
helm uninstall custom-nginx
```

Verify:

```bash
helm list
kubectl get pods
```

Stop Minikube:

```bash
minikube stop
```

Remove generated files:

```bash
rm -f custom-nginx-values.yaml rendered-manifests.yaml
```

Optionally delete the entire Minikube cluster:

```bash
minikube delete
```

---

# 📚 Essential Helm Commands

| Command            | Purpose                            |
| ------------------ | ---------------------------------- |
| `helm version`     | Display Helm version               |
| `helm help`        | Display Helm help                  |
| `helm repo add`    | Add a chart repository             |
| `helm repo list`   | List configured repositories       |
| `helm repo update` | Update repository indexes          |
| `helm search repo` | Search available charts            |
| `helm show chart`  | Display chart metadata             |
| `helm show values` | Display chart configuration values |
| `helm install`     | Install a Helm release             |
| `helm list`        | List Helm releases                 |
| `helm status`      | Display release status             |
| `helm get values`  | Display release values             |
| `helm get all`     | Display release information        |
| `helm history`     | Display release revisions          |
| `helm upgrade`     | Upgrade an existing release        |
| `helm rollback`    | Roll back a release                |
| `helm uninstall`   | Remove a release                   |
| `helm template`    | Render Kubernetes manifests        |

---

# 🧠 Key Concepts Learned

### Helm Chart

A package containing Kubernetes resource templates and configuration metadata.

### Release

A running instance of a Helm Chart inside a Kubernetes cluster.

### Values

Configuration parameters used to customize a Helm Chart.

### Repository

A location where Helm Charts are stored and distributed.

### Revision

A versioned state of a Helm release. Revisions make upgrades and rollbacks possible.

### Template

A Kubernetes manifest containing Helm expressions that are rendered using chart values.

---

# 🔄 Helm Deployment Workflow

```text
Developer
    |
    v
Helm Values
    |
    v
Helm Chart
    |
    v
helm install / upgrade
    |
    v
Kubernetes API Server
    |
    v
+-----------------------+
| Kubernetes Resources  |
|                       |
| Deployment             |
| Pods                   |
| Service                |
| ConfigMaps             |
| Secrets                |
+-----------------------+
```

---

# 🎓 Conclusion

Congratulations! You have successfully completed **Lab 1: Installing Helm**.

During this lab, you:

* Built a local Kubernetes environment using Minikube.
* Installed Docker, kubectl, and Minikube.
* Installed Helm 3.
* Connected Helm to a Kubernetes cluster.
* Configured a Helm chart repository.
* Searched for Kubernetes charts.
* Installed an NGINX application using Helm.
* Inspected Helm releases and chart configuration.
* Upgraded and rolled back a Helm release.
* Created a custom Helm values file.
* Rendered Kubernetes manifests with `helm template`.
* Troubleshot common Helm and Kubernetes problems.
* Cleaned up Helm and Kubernetes resources.

## 💡 Why Helm Matters

Helm is an important Kubernetes and DevOps tool because it provides a consistent way to package, configure, deploy, upgrade, and roll back Kubernetes applications.

Instead of manually maintaining large collections of Kubernetes YAML manifests, teams can use reusable charts with configurable values. This becomes particularly valuable when managing multiple environments such as development, staging, and production.

Helm also integrates well with **CI/CD, GitOps, Kubernetes, and Argo CD**, making it an important skill for modern Cloud DevOps Engineers.

---

# 🚀 Next Steps

After completing this lab, continue with advanced Helm topics:

1. Create your own Helm Chart.
2. Understand Helm Chart directory structure.
3. Work with Helm templates.
4. Use template functions and pipelines.
5. Manage Helm dependencies.
6. Create environment-specific values files.
7. Implement Helm in CI/CD pipelines.
8. Deploy Helm applications through Argo CD.
9. Apply Helm security and best practices.
10. Build production-grade Helm charts.

---

## 🏆 Lab Outcome

**Installing Helm — Completed**

You now have the foundational knowledge required to use Helm for Kubernetes application deployment and management, providing a strong foundation for advanced Kubernetes, GitOps, and DevOps workflows.

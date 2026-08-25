# 🧪 Helm Chart Testing

![Helm](https://img.shields.io/badge/Helm-Chart%20Testing-0F1689?style=for-the-badge\&logo=helm\&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Testing-326CE5?style=for-the-badge\&logo=kubernetes\&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED?style=for-the-badge\&logo=docker\&logoColor=white)
![Kind](https://img.shields.io/badge/Kind-Local%20Cluster-1D2B53?style=for-the-badge\&logo=kubernetes\&logoColor=white)
![kubectl](https://img.shields.io/badge/kubectl-CLI-326CE5?style=for-the-badge\&logo=kubernetes\&logoColor=white)
![YAML](https://img.shields.io/badge/YAML-Configuration-CB171E?style=for-the-badge\&logo=yaml\&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Ubuntu-E95420?style=for-the-badge\&logo=ubuntu\&logoColor=white)

> 🚀 **A practical Kubernetes lab for designing, executing, automating, and troubleshooting Helm chart tests using Helm test hooks.**

---

## 📚 Table of Contents

* [🎯 Lab Objectives](#-lab-objectives)
* [📋 Prerequisites](#-prerequisites)
* [🏗️ Lab Environment](#️-lab-environment)
* [🛠️ Technologies Used](#️-technologies-used)
* [🔧 Task 1 - Environment Preparation](#-task-1---environment-preparation)
* [🧪 Task 2 - Helm Test Hooks](#-task-2---helm-test-hooks)
* [🚀 Task 3 - Run Helm Tests](#-task-3---run-helm-tests)
* [📊 Test Scenarios](#-test-scenarios)
* [🤖 Test Automation](#-test-automation)
* [🐛 Troubleshooting](#-troubleshooting)
* [🧹 Lab Cleanup](#-lab-cleanup)
* [🏆 What You Learned](#-what-you-learned)
* [🌍 Real-World Applications](#-real-world-applications)

---

## 🎯 Lab Objectives

By completing this lab, you will learn how to:

* 🧠 Understand the importance of testing Helm charts.
* 🪝 Configure and use Helm test hooks.
* 🧪 Create automated chart validation scenarios.
* 🔍 Validate deployments, services, replicas, and configuration.
* 📈 Perform basic performance testing.
* 🔄 Test Helm upgrades and rollbacks.
* 🤖 Automate Helm testing workflows.
* 🐛 Troubleshoot failed Helm tests.
* 🔗 Prepare Helm testing workflows for CI/CD pipelines.

---

## 📋 Prerequisites

Before starting, you should have:

* ☸️ Basic Kubernetes knowledge.
* 📝 Familiarity with YAML.
* 💻 Basic Linux command-line experience.
* 📦 Understanding of containers.
* ⛵ Basic Helm knowledge.
* 🔧 Familiarity with Pods, Services, and Deployments.

---

## 🏗️ Lab Environment

This lab uses the **Al Nafi Linux cloud environment**.

The machine starts as a bare-metal Linux environment without the required DevOps tools, so you will install:

| Technology      | Purpose                           |
| --------------- | --------------------------------- |
| 🐧 Ubuntu/Linux | Lab operating system              |
| 🐳 Docker       | Container runtime                 |
| ☸️ Kind         | Local Kubernetes cluster          |
| ⚙️ kubectl      | Kubernetes CLI                    |
| ⛵ Helm          | Kubernetes package manager        |
| 📝 YAML         | Kubernetes and Helm configuration |
| 🐚 Bash         | Automation and testing scripts    |

---

## 🛠️ Technologies Used

### ☸️ Kubernetes Stack

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square\&logo=kubernetes\&logoColor=white)
![Kind](https://img.shields.io/badge/Kind-1D2B53?style=flat-square\&logo=kubernetes\&logoColor=white)
![kubectl](https://img.shields.io/badge/kubectl-326CE5?style=flat-square\&logo=kubernetes\&logoColor=white)

### ⛵ Helm

![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat-square\&logo=helm\&logoColor=white)

Used for:

* Chart packaging
* Templating
* Deployment
* Testing
* Upgrades
* Rollbacks
* Release management

### 🐳 Containerization

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square\&logo=docker\&logoColor=white)

Docker provides the container runtime used by Kind.

### 🐧 Linux

![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=flat-square\&logo=ubuntu\&logoColor=white)

Used for:

* Package installation
* CLI operations
* Bash automation
* Kubernetes administration

---

# 🔧 Task 1 - Environment Preparation

## 1️⃣ Update the System

```bash
sudo apt update && sudo apt upgrade -y
```

Install required utilities:

```bash
sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release
```

---

## 2️⃣ Install Docker

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```

Add the current user to the Docker group:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Verify:

```bash
docker --version
```

✅ **Expected result:** Docker should return its installed version.

---

## 3️⃣ Install Kind

Kind provides the local Kubernetes environment.

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

Verify:

```bash
kind --version
```

---

## 4️⃣ Install kubectl

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

## 5️⃣ Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

---

## 6️⃣ Create the Kind Cluster

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
EOF
```

Create the cluster:

```bash
kind create cluster --config=kind-config.yaml --name=helm-testing
```

Verify:

```bash
kubectl cluster-info
kubectl get nodes
```

🎉 **Milestone:** Your local Kubernetes testing environment is ready.

---

# 🧪 Task 2 - Helm Test Hooks

## 1️⃣ Create the Project

```bash
mkdir -p ~/helm-testing-lab
cd ~/helm-testing-lab

mkdir -p webapp/templates webapp/tests
```

The project will contain:

```text
helm-testing-lab/
└── webapp/
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── _helpers.tpl
    │   └── tests/
    │       ├── test-connection.yaml
    │       ├── test-service.yaml
    │       ├── test-replicas.yaml
    │       ├── test-serviceaccount.yaml
    │       ├── test-performance.yaml
    │       └── test-config.yaml
    └── tests/
```

---

## 2️⃣ Create the Deployment

Create:

```text
webapp/templates/deployment.yaml
```

The Deployment template defines:

* 📦 NGINX container
* 🔢 Configurable replica count
* 🌐 HTTP port
* ❤️ Liveness probe
* 💚 Readiness probe
* 🏷️ Helm-generated labels

The deployment uses Helm values such as:

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.21-alpine"
```

---

## 3️⃣ Create the Service

The Service exposes the application internally inside Kubernetes.

Important configuration:

```yaml
service:
  type: ClusterIP
  port: 80
```

The test Pods use this Service to validate connectivity.

---

## 4️⃣ Create Helm Helpers

The `_helpers.tpl` file centralizes reusable Helm template functions.

It provides:

* 🏷️ Chart names
* 🔖 Release names
* 📌 Labels
* 🔗 Selector labels
* 📦 Fully qualified resource names

This keeps Kubernetes templates cleaner and easier to maintain.

---

## 5️⃣ Create `Chart.yaml`

The chart metadata defines:

```yaml
apiVersion: v2
name: webapp
description: A simple web application Helm chart for testing
type: application
version: 0.1.0
appVersion: "1.0.0"
```

---

## 6️⃣ Configure `values.yaml`

Example configuration:

```yaml
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21-alpine"

service:
  type: ClusterIP
  port: 80

tests:
  enabled: true
  image:
    repository: curlimages/curl
    tag: "7.85.0"
```

💡 **Best Practice:** Keep environment-specific configuration inside `values.yaml` instead of hardcoding values into templates.

---

# 🪝 Helm Test Hooks

Helm test hooks are Kubernetes resources annotated with:

```yaml
annotations:
  "helm.sh/hook": test
```

When you execute:

```bash
helm test webapp-test
```

Helm creates and executes these test resources.

A typical test Pod includes:

```yaml
restartPolicy: Never
```

and:

```yaml
"helm.sh/hook": test
```

---

## 🔌 Connection Test

The connection test validates whether the application can be reached through its Kubernetes Service.

```bash
helm test webapp-test --namespace helm-testing
```

Expected behavior:

```text
curl → Kubernetes Service → Web Application
```

---

## 🌐 Service Availability Test

The service test performs an HTTP request:

```bash
curl -f http://<service>:80/
```

If the request succeeds, the test exits with:

```bash
exit 0
```

If the request fails:

```bash
exit 1
```

---

## 🔢 Replica Validation Test

The replica test uses Kubernetes API access to compare:

```text
Expected replicas
        ↓
Actual ready replicas
        ↓
PASS / FAIL
```

The test requires a dedicated ServiceAccount and RBAC configuration.

---

# 🔐 Test RBAC

The test ServiceAccount is granted permission to inspect Deployments.

The Role allows:

```yaml
apiGroups:
  - apps
resources:
  - deployments
verbs:
  - get
  - list
```

The RoleBinding connects the Role with the test ServiceAccount.

🔒 **Security principle:** Give test workloads only the permissions they actually require.

---

# 🚀 Task 3 - Run Helm Tests

## 1️⃣ Validate the Chart

Run:

```bash
helm lint webapp/
```

Render the templates:

```bash
helm template webapp webapp/ --debug
```

Check dependencies:

```bash
helm dependency list webapp/
```

### 🔍 What these commands do

| Command                | Purpose                 |
| ---------------------- | ----------------------- |
| `helm lint`            | Finds chart problems    |
| `helm template`        | Renders Kubernetes YAML |
| `helm dependency list` | Displays dependencies   |

---

## 2️⃣ Install the Chart

Create the namespace:

```bash
kubectl create namespace helm-testing
```

Install:

```bash
helm install webapp-test webapp/ \
  --namespace helm-testing \
  --wait
```

Verify:

```bash
helm list --namespace helm-testing
kubectl get all --namespace helm-testing
```

---

## 3️⃣ Run Helm Tests

Run all tests:

```bash
helm test webapp-test --namespace helm-testing
```

Display test logs:

```bash
helm test webapp-test \
  --namespace helm-testing \
  --logs
```

Check test Pods:

```bash
kubectl get pods \
  --namespace helm-testing \
  -l "helm.sh/hook=test"
```

🎯 **Expected result:** All test hooks should complete successfully.

---

# 📊 Test Scenarios

This lab implements multiple testing layers.

| Test             | Validation                    |
| ---------------- | ----------------------------- |
| 🔌 Connection    | Application connectivity      |
| 🌐 Service       | Service availability          |
| 🔢 Replicas      | Expected ready replicas       |
| ⚡ Performance    | HTTP response timing          |
| ⚙️ Configuration | Service, image, and resources |
| 🔄 Upgrade       | Post-upgrade functionality    |
| ↩️ Rollback      | Post-rollback functionality   |

---

# ⚡ Performance Testing

A performance test sends multiple HTTP requests:

```text
Request 1
Request 2
Request 3
...
Request 10
```

It records response times using:

```bash
curl -w "Response time: %{time_total}s\n"
```

This provides a simple way to identify unexpected application response delays.

> 💡 This is a lightweight lab exercise, not a replacement for production load-testing tools.

---

# ⚙️ Configuration Testing

The configuration test validates Kubernetes resources such as:

* Service type
* Container image
* CPU limits
* Memory limits

Example:

```bash
kubectl get service
kubectl get deployment
```

This helps catch configuration errors before they reach production.

---

# 🔄 Helm Upgrade Testing

Create upgrade values:

```yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.22-alpine"

service:
  port: 8080
```

Upgrade:

```bash
helm upgrade webapp-test webapp/ \
  --namespace helm-testing \
  --values webapp-upgrade-values.yaml \
  --wait
```

Run tests again:

```bash
helm test webapp-test \
  --namespace helm-testing \
  --logs
```

Review history:

```bash
helm history webapp-test \
  --namespace helm-testing
```

---

# ↩️ Helm Rollback Testing

Rollback to revision 1:

```bash
helm rollback webapp-test 1 \
  --namespace helm-testing \
  --wait
```

Run tests:

```bash
helm test webapp-test \
  --namespace helm-testing
```

Verify:

```bash
helm history webapp-test \
  --namespace helm-testing
```

Check replicas:

```bash
kubectl get deployment webapp-test \
  --namespace helm-testing \
  -o jsonpath='{.spec.replicas}'
```

🎯 **Goal:** Prove that the application remains functional after a rollback.

---

# 🤖 Test Automation

Create:

```text
test-automation.sh
```

The automation workflow performs:

```text
Install Chart
     ↓
Check Deployment
     ↓
Run Tests
     ↓
Upgrade Chart
     ↓
Check Deployment
     ↓
Run Tests
     ↓
Rollback
     ↓
Run Tests
     ↓
Report Result
```

Make it executable:

```bash
chmod +x test-automation.sh
```

Run:

```bash
./test-automation.sh
```

The script uses:

```bash
set -e
```

so unexpected command failures stop the workflow.

---

# 📄 Test Reporting

Create:

```text
generate-test-report.sh
```

The report collects:

* 📋 Helm release information
* 🧪 Test results
* 🚀 Deployment status
* 📦 Pod status
* 🌐 Service status
* 📝 Test Pod logs

Run:

```bash
chmod +x generate-test-report.sh
./generate-test-report.sh
```

A log file is generated:

```text
test-results.log
```

---

# 🐛 Troubleshooting

## ❌ Issue 1: Test Pods Are Not Starting

Inspect Pod details:

```bash
kubectl describe pod \
  -l "helm.sh/hook=test" \
  --namespace helm-testing
```

Check nodes:

```bash
kubectl top nodes
kubectl describe nodes
```

Verify the test image:

```bash
docker pull curlimages/curl:7.85.0
```

---

## ❌ Issue 2: Service Connection Fails

Check Services:

```bash
kubectl get services \
  --namespace helm-testing
```

Check endpoints:

```bash
kubectl get endpoints \
  --namespace helm-testing
```

Check Pod readiness:

```bash
kubectl get pods \
  --namespace helm-testing \
  -o wide
```

Test connectivity manually:

```bash
kubectl run debug-pod \
  --image=curlimages/curl:7.85.0 \
  --rm -it \
  --restart=Never \
  --namespace helm-testing \
  -- curl -f http://webapp-test:80/
```

---

## ❌ Issue 3: RBAC Permission Errors

Check ServiceAccounts:

```bash
kubectl get serviceaccount \
  --namespace helm-testing
```

Check RoleBindings:

```bash
kubectl get rolebindings \
  --namespace helm-testing
```

Check permissions:

```bash
kubectl auth can-i get deployments \
  --as=system:serviceaccount:helm-testing:webapp-test-test-sa \
  --namespace helm-testing
```

Expected:

```text
yes
```

---

# 🔍 Useful Debugging Commands

### Helm

```bash
helm list -A
helm status webapp-test -n helm-testing
helm history webapp-test -n helm-testing
helm get all webapp-test -n helm-testing
```

### Kubernetes

```bash
kubectl get pods -n helm-testing
kubectl get deployments -n helm-testing
kubectl get services -n helm-testing
kubectl get events -n helm-testing
```

### Test Logs

```bash
kubectl get pods \
  -n helm-testing \
  -l "helm.sh/hook=test"

kubectl logs <test-pod> -n helm-testing
```

---

# 🧹 Lab Cleanup

Remove the Helm release:

```bash
helm uninstall webapp-test \
  --namespace helm-testing
```

Delete the namespace:

```bash
kubectl delete namespace helm-testing
```

Delete the Kind cluster:

```bash
kind delete cluster --name=helm-testing
```

Remove lab files:

```bash
cd ~
rm -rf helm-testing-lab
```

---

# 🏆 What You Learned

By completing this lab, you gained practical experience with:

### ⛵ Helm

* Helm charts
* Chart templates
* `values.yaml`
* Helm releases
* Helm hooks
* Helm tests
* Helm upgrades
* Helm rollbacks

### ☸️ Kubernetes

* Deployments
* Services
* Pods
* Namespaces
* ServiceAccounts
* Roles
* RoleBindings
* Kubernetes API access

### 🧪 Testing

* Connection testing
* Service testing
* Replica validation
* Configuration testing
* Performance testing
* Upgrade testing
* Rollback testing

### 🤖 Automation

* Bash automation
* Automated test execution
* Test result collection
* Test reporting
* CI/CD-ready workflows

---

# 🌍 Real-World Applications

Helm chart testing is valuable in production environments because it helps teams:

✅ Catch configuration errors early
✅ Validate Kubernetes deployments automatically
✅ Reduce deployment failures
✅ Test upgrades before production rollout
✅ Verify rollback behavior
✅ Improve CI/CD reliability
✅ Reduce manual validation
✅ Increase deployment confidence

Typical workflow:

```text
Developer
   ↓
Helm Chart
   ↓
helm lint
   ↓
helm template
   ↓
Deploy to Test Cluster
   ↓
helm test
   ↓
Upgrade / Rollback Tests
   ↓
CI/CD Pipeline
   ↓
Production
```

---

# 💡 Helm Testing Best Practices

### 1. 🧪 Test Critical Functionality

Focus tests on application behavior that must work after deployment.

### 2. 🔒 Follow Least Privilege

Test Pods should receive only the Kubernetes permissions they require.

### 3. 🧹 Clean Up Test Resources

Use:

```yaml
helm.sh/hook-delete-policy
```

to prevent unnecessary test resources from accumulating.

### 4. 🔄 Test Upgrades

A chart that works during installation can still fail during an upgrade.

### 5. ↩️ Test Rollbacks

Validate that previous versions can be restored safely.

### 6. 🤖 Automate Testing

Run chart validation automatically in CI/CD pipelines.

### 7. 📊 Keep Test Results

Save logs and test reports to simplify troubleshooting and auditing.

---

# 🧠 Key Takeaways

> **Helm testing transforms chart deployment from a manual process into a repeatable and verifiable workflow.**

The most important workflow from this lab is:

```text
📝 Create Chart
      ↓
🔍 Lint Chart
      ↓
🎨 Render Templates
      ↓
🚀 Install Release
      ↓
🧪 Execute Helm Tests
      ↓
📊 Analyze Results
      ↓
🔄 Test Upgrade
      ↓
↩️ Test Rollback
      ↓
🤖 Automate Everything
```

---

# 🎓 Lab Completion

🎉 **Congratulations!**

You have completed a comprehensive **Helm Chart Testing** lab and built a testing workflow capable of validating:

```text
        ┌─────────────────────┐
        │     Helm Chart      │
        └──────────┬──────────┘
                   ↓
          ┌─────────────────┐
          │   helm lint     │
          └────────┬────────┘
                   ↓
          ┌─────────────────┐
          │ helm template   │
          └────────┬────────┘
                   ↓
          ┌─────────────────┐
          │ Helm Deployment │
          └────────┬────────┘
                   ↓
       ┌───────────┴───────────┐
       ↓           ↓           ↓
   Connection   Service     Replicas
      Test        Test         Test
       │           │           │
       └───────────┼───────────┘
                   ↓
           Configuration
              Testing
                   ↓
             Performance
                Testing
                   ↓
              Upgrade Test
                   ↓
             Rollback Test
                   ↓
            🤖 Automation
```

### 🚀 Skills Developed

**Kubernetes • Helm • Docker • Kind • kubectl • YAML • Bash • RBAC • Testing • Automation • CI/CD**

---

⭐ **If this lab helped you build practical Kubernetes and DevOps skills, consider documenting your results and sharing your learning journey.**

**Happy Testing! 🧪☸️⛵**

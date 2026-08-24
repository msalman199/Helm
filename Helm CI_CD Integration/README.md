<div align="center">

# 🔄 Helm CI/CD Integration

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Kind](https://img.shields.io/badge/Kind-4051B5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Level](https://img.shields.io/badge/Level-Advanced-red?style=for-the-badge)

*Build a Node.js app, package it as a Helm chart, and drive build → lint → deploy → test through a Jenkins pipeline*

</div>

---

## 📑 Table of Contents

- [🎯 Learning Objectives](#-learning-objectives)
- [📋 Prerequisites](#-prerequisites)
- [🖥️ Lab Environment](#️-lab-environment)
- [⚙️ Task 1: Environment Preparation](#️-task-1-environment-preparation)
- [📦 Task 2: Build the Application and Helm Chart](#-task-2-build-the-application-and-helm-chart)
- [🔧 Task 3: Build and Run the Jenkins CI/CD Pipeline](#-task-3-build-and-run-the-jenkins-cicd-pipeline)
- [✅ Task 4: Verify the CI/CD Pipeline End to End](#-task-4-verify-the-cicd-pipeline-end-to-end)
- [🏆 Expected Outcomes](#-expected-outcomes)
- [🔧 Troubleshooting](#-troubleshooting-1)
- [📚 Key Concepts](#-key-concepts)
- [✅ Conclusion](#-conclusion-1)

---

## 🎯 Learning Objectives

| # | Objective |
|---|-----------|
| 1 | Set up Jenkins on a Linux machine and configure it for Kubernetes/Helm operations |
| 2 | Build a sample application and package it as a Helm chart |
| 3 | Create a Jenkins pipeline that builds, tests, and deploys the application using Helm |
| 4 | Implement Helm chart tests that validate a running release |
| 5 | Verify a complete CI/CD run end to end, including Helm release status and application health |

---

## 📋 Prerequisites

| Requirement | Details |
|---|---|
| Kubernetes fundamentals | Basic understanding of pods, services, and deployments |
| Helm basics | Familiarity with Helm charts and basic commands (`helm install`, `helm upgrade`) |
| Git | Basic knowledge of Git version control |
| CI/CD concepts | Understanding of general build, test, and deploy stages |
| Linux CLI | Comfort with the Linux command line and editing YAML files |

---

## 🖥️ Lab Environment

> 🧪 This lab is performed entirely on a single, isolated Linux practice machine that you own or have been assigned for training purposes. All tools are installed from scratch as part of the exercise; no pre-installed software is assumed.

**Required tools** (installed during the lab, exact commands provided in Task 1):

| Tool | Purpose |
|---|---|
| Docker | Builds and runs container images |
| Kind (Kubernetes in Docker) | Local Kubernetes cluster for the lab |
| kubectl | Kubernetes CLI |
| Helm 3 | Chart packaging, linting, install, and testing |
| Jenkins (with OpenJDK 17) | CI/CD pipeline engine |
| Git | Version control backing the Jenkins pipeline's SCM checkout |

---

## ⚙️ Task 1: Environment Preparation

### 🐳 Subtask 1.1: Install Docker, Kind, kubectl, and Helm

```bash
# 🔄 Update package manager and install prerequisites
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip apt-transport-https ca-certificates gnupg lsb-release

# 🐳 Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

# 🔍 Verify Docker
docker --version

# 🎡 Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind --version

# ☸️ Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# ⛵ Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### ☸️ Subtask 1.2: Create a Local Kubernetes Cluster

```bash
cat << 'EOF' > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
EOF

kind create cluster --config=kind-config.yaml --name=helm-cicd

kubectl cluster-info
kubectl get nodes
```

> **📦 Deliverable:** `kubectl get nodes` shows one node named `helm-cicd-control-plane` with status `Ready`.

### 🔧 Subtask 1.3: Install Jenkins

```bash
# ☕ Install Java (required by Jenkins)
sudo apt install -y openjdk-17-jdk
java -version

# 📦 Add Jenkins repository and install
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins --no-pager

# 🔑 Retrieve initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Open a browser to `http://localhost:8080`, paste the initial admin password, choose **Install suggested plugins**, and create an admin user.

Then install two additional plugins via **Manage Jenkins > Plugins > Available plugins**: **Pipeline** (usually already installed with the suggested set) and **Git**. Restart Jenkins after installation if prompted:

```bash
sudo systemctl restart jenkins
```

### 🔐 Subtask 1.4: Give Jenkins Access to Docker and Kubernetes

```bash
# 🐳 Allow Jenkins to run Docker commands
sudo usermod -aG docker jenkins

# ☸️ Give Jenkins access to the kubeconfig for the Kind cluster
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

sudo systemctl restart jenkins

# 🔍 Verify Jenkins can reach the cluster
sudo -u jenkins kubectl get nodes
sudo -u jenkins helm version
```

> **📦 Deliverable:** `sudo -u jenkins kubectl get nodes` returns the same node list as your own user, confirming Jenkins has cluster access.

---

## 📦 Task 2: Build the Application and Helm Chart

### 🖋️ Subtask 2.1: Create the Sample Application

```bash
mkdir -p ~/helm-cicd-demo
cd ~/helm-cicd-demo

cat << 'EOF' > app.js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Helm CI/CD Demo!',
    version: process.env.APP_VERSION || '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});
EOF

cat << 'EOF' > package.json
{
  "name": "helm-cicd-demo",
  "version": "1.0.0",
  "description": "Demo app for Helm CI/CD integration",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

cat << 'EOF' > Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
EOF
```

### ⛵ Subtask 2.2: Create and Customize the Helm Chart

```bash
helm create helm-cicd-demo-chart
cd helm-cicd-demo-chart

cat << 'EOF' > values.yaml
replicaCount: 2

image:
  repository: helm-cicd-demo
  pullPolicy: IfNotPresent
  tag: "latest"

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

ingress:
  enabled: false

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: false

env:
  - name: APP_VERSION
    value: "1.0.0"
EOF

cat << 'EOF' > templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "helm-cicd-demo-chart.fullname" . }}
  labels:
    {{- include "helm-cicd-demo-chart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "helm-cicd-demo-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "helm-cicd-demo-chart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          env:
            {{- toYaml .Values.env | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
EOF

cat << 'EOF' > templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "helm-cicd-demo-chart.fullname" . }}
  labels:
    {{- include "helm-cicd-demo-chart.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "helm-cicd-demo-chart.selectorLabels" . | nindent 4 }}
EOF

cd ..
```

### 🧪 Subtask 2.3: Add Helm Chart Tests

Create a `tests` subdirectory in the chart with test pods that reference the service by its fully qualified in-cluster DNS name, so the tests reliably resolve the service regardless of release name or namespace.

```bash
mkdir -p helm-cicd-demo-chart/templates/tests

cat << 'EOF' > helm-cicd-demo-chart/templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "helm-cicd-demo-chart.fullname" . }}-test-connection"
  labels:
    {{- include "helm-cicd-demo-chart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  restartPolicy: Never
  containers:
    - name: wget
      image: busybox:1.36
      command: ['wget']
      args:
        - '-O'
        - '-'
        - 'http://{{ include "helm-cicd-demo-chart.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.service.port }}/health'
EOF

cat << 'EOF' > helm-cicd-demo-chart/templates/tests/test-health.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "helm-cicd-demo-chart.fullname" . }}-test-health"
  labels:
    {{- include "helm-cicd-demo-chart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-weight": "2"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  restartPolicy: Never
  containers:
    - name: curl
      image: curlimages/curl:8.8.0
      command: ['curl']
      args:
        - '-f'
        - 'http://{{ include "helm-cicd-demo-chart.fullname" . }}.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.service.port }}/health'
EOF
```

Using the fully qualified `<service>.<namespace>.svc.cluster.local` name guarantees the test pods resolve the correct Service via cluster DNS regardless of which namespace the release is installed into.

### 🚀 Subtask 2.4: Build the Image and Validate the Chart Locally

```bash
cd ~/helm-cicd-demo

docker build -t helm-cicd-demo:latest .

kind load docker-image helm-cicd-demo:latest --name=helm-cicd

helm lint ./helm-cicd-demo-chart

helm install demo-app ./helm-cicd-demo-chart --wait --timeout=120s

kubectl get pods
kubectl get svc

helm test demo-app

helm uninstall demo-app
```

> **📦 Deliverable:** `helm lint` reports `0 chart(s) linted, 0 chart(s) failed`, `helm test demo-app` shows both `test-connection` and `test-health` pods with status `Passed`, and `helm uninstall demo-app` removes the release cleanly.

---

## 🔧 Task 3: Build and Run the Jenkins CI/CD Pipeline

### 🗃️ Subtask 3.1: Initialize Git and Add a Jenkinsfile

```bash
cd ~/helm-cicd-demo

cat << 'EOF' > .gitignore
node_modules/
*.log
.DS_Store
EOF

git init
git config user.email "student@example.com"
git config user.name "Student"
git add .
git commit -m "Initial commit: app, Dockerfile, Helm chart with tests"
```

Create the Jenkins pipeline definition:

```bash
cat << 'EOF' > Jenkinsfile
pipeline {
    agent any

    environment {
        DOCKER_IMAGE   = 'helm-cicd-demo'
        HELM_CHART_PATH = './helm-cicd-demo-chart'
        RELEASE_NAME   = 'helm-cicd-demo'
        NAMESPACE      = 'default'
        KUBECONFIG     = '/var/lib/jenkins/.kube/config'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                echo 'Building Docker image...'
                sh """
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                    kind load docker-image ${DOCKER_IMAGE}:${BUILD_NUMBER} --name=helm-cicd
                """
            }
        }

        stage('Lint Helm Chart') {
            steps {
                echo 'Linting Helm chart...'
                sh "helm lint ${HELM_CHART_PATH}"
            }
        }

        stage('Dry Run') {
            steps {
                echo 'Validating chart rendering with dry-run...'
                sh """
                    helm upgrade --install ${RELEASE_NAME} ${HELM_CHART_PATH} \
                        --set image.tag=${BUILD_NUMBER} \
                        --namespace ${NAMESPACE} \
                        --dry-run --debug
                """
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying application with Helm...'
                sh """
                    helm upgrade --install ${RELEASE_NAME} ${HELM_CHART_PATH} \
                        --set image.tag=${BUILD_NUMBER} \
                        --namespace ${NAMESPACE} \
                        --wait --timeout=180s
                """
            }
        }

        stage('Helm Test') {
            steps {
                echo 'Running Helm chart tests...'
                sh "helm test ${RELEASE_NAME} --namespace ${NAMESPACE}"
            }
        }
    }

    post {
        always {
            echo 'Pipeline run finished, collecting status...'
            sh "helm list --namespace ${NAMESPACE} || true"
            sh "kubectl get pods --namespace ${NAMESPACE} || true"
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Rolling back release...'
            sh "helm rollback ${RELEASE_NAME} --namespace ${NAMESPACE} || true"
        }
    }
}
EOF

git add Jenkinsfile
git commit -m "Add Jenkins pipeline for build, lint, deploy, and test stages"
```

### 🖱️ Subtask 3.2: Create the Jenkins Pipeline Job

1. Open Jenkins at `http://localhost:8080`.
2. Click **New Item**, enter the name `helm-cicd-demo`, select **Pipeline**, and click **OK**.
3. Under **Pipeline**, set **Definition** to **Pipeline script from SCM**.
4. Set **SCM** to **Git** and **Repository URL** to the absolute path of your project, for example `/home/<your-username>/helm-cicd-demo` (a local file path is a valid Git repository URL for Jenkins).
5. Set **Branch Specifier** to `*/main` (or `*/master`, matching your default branch — check with `git branch`).
6. Set **Script Path** to `Jenkinsfile`.
7. Click **Save**.

### ▶️ Subtask 3.3: Run the Pipeline

Click **Build Now** on the `helm-cicd-demo` job, then open **Console Output** to watch the stages execute in order: `Checkout`, `Build Image`, `Lint Helm Chart`, `Dry Run`, `Deploy`, `Helm Test`.

> **📦 Deliverable:** the build finishes with status `SUCCESS`, and the console output shows `helm lint` passing, the Helm release upgraded/installed, and both Helm tests reported as `Passed`.

---

## ✅ Task 4: Verify the CI/CD Pipeline End to End

### 📋 Subtask 4.1: Verify the Helm Release

```bash
helm list --namespace default
```

> **✅ Expected output:** a row for `helm-cicd-demo` with `STATUS` equal to `deployed` and a `REVISION` number matching the number of times the pipeline has run.

### 🔍 Subtask 4.2: Check Pod Status

```bash
kubectl get pods --namespace default -l app.kubernetes.io/instance=helm-cicd-demo

kubectl describe deployment helm-cicd-demo-helm-cicd-demo-chart --namespace default
```

> **✅ Expected output:** two pods in `Running` state with `READY 1/1`, matching `replicaCount: 2` in `values.yaml`.

### 🌐 Subtask 4.3: Test the Application Endpoint

```bash
kubectl port-forward svc/helm-cicd-demo-helm-cicd-demo-chart 8081:80 --namespace default &
sleep 5

curl -s http://localhost:8081/health
curl -s http://localhost:8081/

kill %1
```

> **✅ Expected output:** `{"status":"healthy"}` from `/health` and a JSON body containing `"message":"Hello from Helm CI/CD Demo!"` from `/`.

### 🔁 Subtask 4.4: Validate That the Pipeline Ran Correctly

```bash
# ✅ Confirm Helm test hooks executed and passed
helm test helm-cicd-demo --namespace default

# 🏷️ Confirm the deployed image tag matches the last Jenkins build number
kubectl get deployment helm-cicd-demo-helm-cicd-demo-chart \
  --namespace default \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
echo

# 📜 Confirm release history reflects incremental Jenkins-driven upgrades
helm history helm-cicd-demo --namespace default
```

> **📦 Deliverable:** `helm test` reports both test pods as `Passed`, the printed image reference ends with the tag matching your latest Jenkins `BUILD_NUMBER`, and `helm history` shows a `deployed` status for the most recent revision with the corresponding chart version.

Clean up the cluster resources once verification is complete:

```bash
helm uninstall helm-cicd-demo --namespace default
kind delete cluster --name=helm-cicd
```

---

## 🏆 Expected Outcomes

- A working local Kubernetes cluster (Kind) with a Jenkins instance capable of building Docker images and deploying Helm releases into it
- A Helm chart with deployment, service, and test templates that pass `helm lint` and `helm test`
- A Jenkins pipeline that automatically builds, lints, deploys, and tests the application on each run, with verifiable Helm release history and healthy running pods

---

## 🔧 Troubleshooting

<details>
<summary><strong>Click to expand common issues and solutions</strong></summary>

**Jenkins pipeline fails at the Deploy stage with a permission or connection error to the cluster:**
Check that `/var/lib/jenkins/.kube/config` exists, is owned by `jenkins:jenkins`, and that `sudo -u jenkins kubectl get nodes` succeeds outside the pipeline.

**`helm test` reports the test pods as `Failed` or stuck in `Pending`:**
Run `kubectl logs <test-pod-name>` and `kubectl describe pod <test-pod-name>` to check whether the image could be pulled and whether the service DNS name resolved; confirm the Service was created with `kubectl get svc` before the test ran.

</details>

---

## 📚 Key Concepts

| Concept | Description |
|---|---|
| Helm Chart Test (`helm.sh/hook: test`) | Hook-annotated test Pods, ordered by `helm.sh/hook-weight`, that `helm test` runs post-deploy to validate a live release |
| In-Cluster DNS (`<service>.<namespace>.svc.cluster.local`) | Fully qualified Service address that resolves correctly regardless of release name or target namespace |
| Declarative Jenkins Pipeline | A `Jenkinsfile` defining ordered `stages` plus a `post` block for status reporting and failure handling |
| `helm upgrade --install` | Idempotent deploy pattern — installs on first run, upgrades on every subsequent pipeline run |
| `kind load docker-image` | Loads a locally built image directly into a Kind cluster's node, bypassing the need for a registry |
| `helm rollback` | Reverts a release to a prior revision, used here in the pipeline's `failure` post-action |
| Helm Release History | `helm history` tracks revisions, chart versions, and statuses across repeated `helm upgrade --install` runs |

---

## ✅ Conclusion

In this lab, you installed and configured Jenkins alongside a local Kind Kubernetes cluster, then built a Node.js application and packaged it as a Helm chart complete with deployment, service, and test templates. You implemented a Jenkins pipeline that automated the full CI/CD workflow — building the container image, linting and dry-running the Helm chart, deploying it, and running Helm test hooks to validate the release — and confirmed correctness by inspecting Helm release history, pod status, and live HTTP endpoints. Through this process you practiced core GitOps principles: treating the Helm chart and Jenkinsfile as version-controlled source of truth, using `helm upgrade --install` for idempotent deployments, and relying on automated tests rather than manual checks to gate releases. These same patterns — chart linting, hook-based testing with proper in-cluster DNS references, and pipeline-driven rollback on failure — are directly applicable to production Helm and CI/CD environments, and the troubleshooting steps you practiced here (checking Jenkins user permissions, inspecting test pod logs) form the basis for diagnosing real-world deployment failures.

---

<div align="center">

![Al Nafi](https://img.shields.io/badge/Al%20Nafi-Cybersecurity%20Training-blue?style=for-the-badge)

</div>

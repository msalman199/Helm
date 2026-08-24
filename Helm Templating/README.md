# Helm Templating

## Lab Overview

This lab provides hands-on experience with **Helm templating**, one of the core features of Helm for creating reusable, configurable, and environment-aware Kubernetes manifests.

You will build a Helm chart named `webapp-chart`, customize its templates, use values to parameterize Kubernetes resources, implement conditionals and loops, render and validate manifests, and deploy the resulting release to a local `kind` Kubernetes cluster.

The lab follows the complete Helm workflow:

```text
Create Chart
    ↓
Customize Templates
    ↓
Configure values.yaml
    ↓
helm lint
    ↓
helm template
    ↓
Dry-Run Validation
    ↓
helm install
    ↓
Verify with kubectl
    ↓
helm upgrade
    ↓
Troubleshoot
    ↓
Cleanup
```

---

## Lab Objectives

By the end of this lab, you will be able to:

* Understand Helm templating concepts and syntax.
* Create and customize Helm templates for Kubernetes resources.
* Implement conditionals and loops in Helm charts.
* Use Helm values to parameterize deployments.
* Render and validate Helm templates before deployment.
* Deploy and upgrade Helm releases.
* Debug and troubleshoot Helm templates and Kubernetes workloads.
* Use `kubectl describe`, `kubectl logs`, and Helm commands to diagnose deployment problems.

---

## Prerequisites

Before starting this lab, you should have:

* Basic understanding of Kubernetes concepts such as Pods, Services, and Deployments.
* Familiarity with YAML syntax.
* Basic Linux command-line experience.
* Understanding of containerization concepts.
* Basic knowledge of Helm is helpful but not required.

This lab uses a **local, disposable Kubernetes cluster created with `kind`**. All resources are created in an isolated practice environment and no production or external Kubernetes cluster is required.

---

## Required Tools

The following tools are required:

* Docker
* kubectl
* kind
* Helm

### Install Docker

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

docker --version
```

### Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/

kubectl version --client
```

### Install kind

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

kind version
```

### Install Helm

```bash
curl -fsSL -o get_helm.sh \
  https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh
./get_helm.sh

helm version
```

---

# Create the Practice Cluster

Create a minimal `kind` cluster for the lab:

```bash
cat << 'EOF' > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
EOF

kind create cluster \
  --config=kind-config.yaml \
  --name helm-lab

kubectl cluster-info
kubectl get nodes
```

The cluster should contain a control-plane node similar to:

```text
helm-lab-control-plane
```

The node should eventually show:

```text
STATUS
Ready
```

Verify the active Kubernetes context:

```bash
kubectl config current-context
```

Expected:

```text
kind-helm-lab
```

---

# Task 1: Create and Customize a Helm Chart

## Step 1: Scaffold a New Chart

Create the chart:

```bash
helm create webapp-chart
```

Inspect the generated structure:

```bash
ls -la webapp-chart/
```

A standard Helm chart contains files and directories such as:

```text
webapp-chart/
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── serviceaccount.yaml
    ├── _helpers.tpl
    ├── hpa.yaml
    └── tests/
```

The most important files for this lab are:

| File           | Purpose                       |
| -------------- | ----------------------------- |
| `Chart.yaml`   | Chart metadata                |
| `values.yaml`  | Default configurable values   |
| `templates/`   | Kubernetes resource templates |
| `_helpers.tpl` | Reusable template helpers     |
| `charts/`      | Chart dependencies            |

---

## Step 2: Customize the Deployment Template

Replace the generated Deployment template:

```bash
cat << 'EOF' > webapp-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp-chart.fullname" . }}
  labels:
    {{- include "webapp-chart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "webapp-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "webapp-chart.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "webapp-chart.serviceAccountName" . }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort | default 80 }}
              protocol: TCP
          {{- if .Values.healthcheck.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.healthcheck.path }}
              port: http
            initialDelaySeconds: {{ .Values.healthcheck.initialDelaySeconds }}
            periodSeconds: {{ .Values.healthcheck.periodSeconds }}
          readinessProbe:
            httpGet:
              path: {{ .Values.healthcheck.path }}
              port: http
            initialDelaySeconds: {{ .Values.healthcheck.initialDelaySeconds }}
            periodSeconds: {{ .Values.healthcheck.periodSeconds }}
          {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- if .Values.env }}
          env:
            {{- range $key, $value := .Values.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
          {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
EOF
```

This template demonstrates several important Helm features:

* `.Values`
* `include`
* `if`
* `range`
* `default`
* `toYaml`
* `nindent`

---

## Step 3: Add a Conditional ConfigMap

Create a ConfigMap template:

```bash
cat << 'EOF' > webapp-chart/templates/configmap.yaml
{{- if .Values.config.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "webapp-chart.fullname" . }}-config
  labels:
    {{- include "webapp-chart.labels" . | nindent 4 }}
data:
  {{- range $key, $value := .Values.config.data }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
EOF
```

The entire ConfigMap is controlled by:

```yaml
config:
  enabled: true
```

If it is changed to:

```yaml
config:
  enabled: false
```

the ConfigMap will not be rendered.

---

## Step 4: Configure `values.yaml`

Replace the default values:

```bash
cat << 'EOF' > webapp-chart/values.yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

service:
  type: ClusterIP
  port: 80
  targetPort: 80

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false

nodeSelector: {}

healthcheck:
  enabled: true
  path: /
  initialDelaySeconds: 5
  periodSeconds: 10

env:
  NODE_ENV: production
  LOG_LEVEL: info

config:
  enabled: true
  data:
    app.properties: |
      server.port=8080
      logging.level=INFO
EOF
```

---

## Step 5: Validate the Chart

Run:

```bash
helm lint ./webapp-chart
```

Expected result:

```text
0 chart(s) linted, 0 chart(s) failed
```

Render the Deployment:

```bash
helm template webapp ./webapp-chart \
  --show-only templates/deployment.yaml
```

Render the ConfigMap:

```bash
helm template webapp ./webapp-chart \
  --show-only templates/configmap.yaml
```

The Deployment should contain:

```yaml
env:
  - name: NODE_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "info"
```

The ConfigMap should contain the `app.properties` data.

---

# Task 2: Implement Conditionals and Loops

Helm templates become powerful when conditional logic and iteration are used to generate environment-specific Kubernetes resources.

---

## Step 1: Add Environment-Based Conditional Logic

Replace the Deployment template:

```bash
cat << 'EOF' > webapp-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp-chart.fullname" . }}
  labels:
    {{- include "webapp-chart.labels" . | nindent 4 }}
    {{- if .Values.environment }}
    environment: {{ .Values.environment }}
    {{- end }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "webapp-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "webapp-chart.selectorLabels" . | nindent 8 }}
        {{- if .Values.environment }}
        environment: {{ .Values.environment }}
        {{- end }}
    spec:
      serviceAccountName: {{ include "webapp-chart.serviceAccountName" . }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort | default 80 }}
              protocol: TCP
          {{- if .Values.healthcheck.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.healthcheck.path }}
              port: http
            initialDelaySeconds: {{ .Values.healthcheck.initialDelaySeconds }}
            periodSeconds: {{ .Values.healthcheck.periodSeconds }}
          readinessProbe:
            httpGet:
              path: {{ .Values.healthcheck.path }}
              port: http
            initialDelaySeconds: {{ .Values.healthcheck.initialDelaySeconds }}
            periodSeconds: {{ .Values.healthcheck.periodSeconds }}
          {{- end }}
          {{- if eq .Values.environment "production" }}
          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              cpu: 1000m
              memory: 1Gi
          {{- else if eq .Values.environment "staging" }}
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          {{- else }}
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
          {{- end }}
          env:
            {{- if eq .Values.environment "production" }}
            - name: DEBUG
              value: "false"
            - name: LOG_LEVEL
              value: "warn"
            {{- else }}
            - name: DEBUG
              value: "true"
            - name: LOG_LEVEL
              value: "debug"
            {{- end }}
            {{- range $key, $value := .Values.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
EOF
```

The template now behaves differently depending on:

```yaml
environment: development
```

```yaml
environment: staging
```

or:

```yaml
environment: production
```

The `eq` function compares the environment value.

---

## Step 2: Add a Service Loop

Create the Service template:

```bash
cat << 'EOF' > webapp-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "webapp-chart.fullname" . }}
  labels:
    {{- include "webapp-chart.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    {{- range .Values.servicePorts }}
    - port: {{ .port }}
      targetPort: {{ .targetPort | default .port }}
      protocol: {{ .protocol | default "TCP" }}
      name: {{ .name }}
    {{- end }}
  selector:
    {{- include "webapp-chart.selectorLabels" . | nindent 4 }}
EOF
```

The important section is:

```gotemplate
{{- range .Values.servicePorts }}
```

The `range` function loops over every item in the `servicePorts` list.

---

## Step 3: Configure Multiple Service Ports

Update `values.yaml`:

```bash
cat << 'EOF' > webapp-chart/values.yaml
replicaCount: 1
environment: development

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

service:
  type: ClusterIP
  port: 80
  targetPort: 80

servicePorts:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: 9090
    protocol: TCP

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: false

nodeSelector: {}

healthcheck:
  enabled: true
  path: /
  initialDelaySeconds: 5
  periodSeconds: 10

env:
  NODE_ENV: production

config:
  enabled: true
  data:
    app.properties: |
      server.port=8080
      logging.level=INFO
EOF
```

---

## Step 4: Compare Different Environments

Render the development configuration:

```bash
helm template webapp ./webapp-chart \
  --set environment=development | grep -A2 "DEBUG"
```

Render the production configuration:

```bash
helm template webapp ./webapp-chart \
  --set environment=production | grep -A2 "DEBUG"
```

Render the Service:

```bash
helm template webapp ./webapp-chart \
  --show-only templates/service.yaml
```

The development environment should produce:

```yaml
DEBUG: "true"
```

The production environment should produce:

```yaml
DEBUG: "false"
```

Production also receives larger resource requests and limits.

The Service should contain both:

```text
http
metrics
```

with ports:

```text
80
9090
```

---

# Helm Template Concepts Used

This lab demonstrates several important Helm template features.

| Feature      | Example                    | Purpose                        |
| ------------ | -------------------------- | ------------------------------ |
| Values       | `.Values.image.repository` | Access configuration           |
| Conditionals | `if`                       | Conditionally render resources |
| Comparison   | `eq`                       | Compare values                 |
| Loops        | `range`                    | Iterate over lists/maps        |
| Default      | `default`                  | Provide fallback values        |
| Include      | `include`                  | Reuse helper templates         |
| `toYaml`     | `toYaml .Values.resources` | Convert values to YAML         |
| `nindent`    | `nindent 12`               | Format YAML indentation        |
| Template     | `helm template`            | Render manifests locally       |

---

# Task 3: Deploy, Verify, and Troubleshoot

## Step 1: Lint the Chart

Run:

```bash
helm lint ./webapp-chart
```

Expected:

```text
0 chart(s) linted, 0 chart(s) failed
```

---

## Step 2: Perform a Dry-Run Validation

Render the complete chart and pass it to Kubernetes validation:

```bash
helm template webapp ./webapp-chart | \
  kubectl apply --dry-run=client -f -
```

This allows you to catch Kubernetes manifest problems before installing the release.

---

## Step 3: Install the Helm Release

Install the chart using the production environment:

```bash
helm install webapp ./webapp-chart \
  --set environment=production
```

Check the release:

```bash
helm list
```

Expected release name:

```text
webapp
```

Check the resources:

```bash
kubectl get pods
kubectl get services
kubectl get configmaps
```

The Helm installation should report:

```text
STATUS: deployed
```

---

## Step 4: Verify Deployment Readiness

Check rollout status:

```bash
kubectl rollout status deployment/webapp-webapp-chart \
  --timeout=60s
```

Inspect Pods:

```bash
kubectl get pods -o wide
```

The Pod should eventually reach:

```text
READY
1/1
```

and:

```text
STATUS
Running
```

---

# Troubleshooting Helm Deployments

If the Pod does not become ready, inspect it.

## Describe the Pod

```bash
kubectl describe pod <pod-name>
```

Pay particular attention to the `Events` section.

## View Container Logs

```bash
kubectl logs <pod-name>
```

## View Previous Container Logs

If the container has restarted:

```bash
kubectl logs <pod-name> --previous
```

---

## Common Problems

### ImagePullBackOff

Example:

```text
ImagePullBackOff
```

or:

```text
ErrImagePull
```

Check:

```bash
kubectl describe pod <pod-name>
```

Verify the image configuration:

```yaml
image:
  repository: nginx
  tag: "1.21"
```

---

### CrashLoopBackOff

Check:

```bash
kubectl logs <pod-name>
```

and:

```bash
kubectl logs <pod-name> --previous
```

Look for application startup errors.

---

### Pod Stuck in Pending

Run:

```bash
kubectl describe pod <pod-name>
```

Check the Events section for scheduling errors.

A single-node `kind` cluster has limited CPU and memory. If resource requests are too large, reduce them in `values.yaml`.

---

### Helm Template Parse Errors

If Helm reports a YAML or template parsing error, render only the problematic file:

```bash
helm template webapp ./webapp-chart \
  --show-only templates/deployment.yaml
```

Check for:

* Incorrect indentation.
* Missing `{{- end }}`.
* Incorrect template expressions.
* Invalid YAML generated by a template.
* Incorrect values paths.

For loops, verify:

```gotemplate
{{- range .Values.servicePorts }}
...
{{- end }}
```

For conditionals, verify:

```gotemplate
{{- if .Values.config.enabled }}
...
{{- end }}
```

---

# Step 5: Upgrade the Release

Upgrade the existing release with two replicas and the staging environment:

```bash
helm upgrade webapp ./webapp-chart \
  --set replicaCount=2 \
  --set environment=staging
```

Check the Pods:

```bash
kubectl get pods
```

Verify the replica count:

```bash
kubectl get deployment webapp-webapp-chart \
  -o jsonpath='{.spec.replicas}{"\n"}'
```

Expected:

```text
2
```

Check the effective Helm values:

```bash
helm get values webapp
```

The output should include:

```yaml
replicaCount: 2
environment: staging
```

Check the rollout:

```bash
kubectl rollout status deployment/webapp-webapp-chart \
  --timeout=60s
```

---

# Helm Release Verification

Useful commands for inspecting the release include:

```bash
helm list
```

```bash
helm status webapp
```

```bash
helm get values webapp
```

```bash
helm get manifest webapp
```

```bash
helm history webapp
```

These commands provide visibility into the deployed Helm release and its configuration.

---

# Expected Outcomes

After completing this lab, you should have:

* A working Helm chart named `webapp-chart`.
* A templated Deployment.
* A templated Service.
* A conditional ConfigMap.
* Environment-specific resource configuration.
* Environment-specific `DEBUG` and logging configuration.
* A Service generated using a `range` loop.
* Multiple Service ports generated from `values.yaml`.
* A successfully installed Helm release named `webapp`.
* A successfully upgraded release with two replicas.
* Experience using `helm lint`.
* Experience using `helm template`.
* Experience performing Kubernetes dry-run validation.
* Experience troubleshooting Pods using `kubectl describe` and `kubectl logs`.

---

# Validation Checklist

* [ ] Docker is installed and running.
* [ ] kubectl is installed.
* [ ] kind is installed.
* [ ] Helm is installed.
* [ ] `helm-lab` kind cluster is running.
* [ ] `webapp-chart` has been created.
* [ ] Deployment template contains Helm conditionals.
* [ ] ConfigMap template is conditionally rendered.
* [ ] Service template uses `range`.
* [ ] `values.yaml` contains environment configuration.
* [ ] `helm lint` completes successfully.
* [ ] `helm template` renders valid Kubernetes manifests.
* [ ] Dry-run validation succeeds.
* [ ] `webapp` release is installed.
* [ ] Pods reach `Running` and `Ready`.
* [ ] Deployment rollout succeeds.
* [ ] Release is upgraded to two replicas.
* [ ] `helm get values webapp` shows the expected configuration.
* [ ] Helm release is uninstalled after the lab.
* [ ] The kind cluster is deleted after the lab.

---

# Cleanup

When the lab is complete, remove the Helm release:

```bash
helm uninstall webapp
```

Verify that the release has been removed:

```bash
helm list
```

Delete the practice cluster:

```bash
kind delete cluster --name helm-lab
```

Confirm that the cluster no longer exists:

```bash
kind get clusters
```

---

# Best Practices

When developing production Helm charts:

1. Keep configurable values in `values.yaml`.
2. Avoid hardcoding environment-specific settings in templates.
3. Use `helm lint` before deployment.
4. Use `helm template` to inspect rendered manifests.
5. Use dry-run validation before installing changes.
6. Keep templates readable and consistently indented.
7. Use `_helpers.tpl` for reusable naming and labeling logic.
8. Use conditionals only when they provide meaningful configuration flexibility.
9. Use `range` for repeated resources or configuration items.
10. Keep sensitive credentials out of `values.yaml` and Git repositories.
11. Use explicit image tags instead of relying on mutable tags.
12. Test charts in a disposable Kubernetes environment before production deployment.

---

# Key Helm Workflow

A practical Helm workflow is:

```bash
# Validate
helm lint ./webapp-chart

# Render
helm template webapp ./webapp-chart

# Dry-run
helm template webapp ./webapp-chart | \
  kubectl apply --dry-run=client -f -

# Install
helm install webapp ./webapp-chart

# Inspect
helm status webapp
helm get values webapp

# Upgrade
helm upgrade webapp ./webapp-chart \
  --set replicaCount=2

# Verify
kubectl get pods
kubectl rollout status deployment/webapp-webapp-chart

# Cleanup
helm uninstall webapp
```

---

# Conclusion

In this lab, you built and customized a Helm chart from the ground up and learned how Helm templates transform reusable configuration into Kubernetes manifests.

You practiced using `.Values`, `if`/`else`, `eq`, `range`, `default`, `include`, `toYaml`, and `nindent`. You also created a conditional ConfigMap, implemented environment-specific resource configuration, and generated multiple Service ports from a values list.

The lab covered the complete lifecycle of a Helm application:

```text
helm lint
    ↓
helm template
    ↓
dry-run validation
    ↓
helm install
    ↓
kubectl verification
    ↓
troubleshooting
    ↓
helm upgrade
    ↓
helm get values
    ↓
cleanup
```

These templating, parameterization, validation, deployment, upgrade, and troubleshooting skills form the foundation for creating maintainable and production-grade Helm charts.

---

# Further Practice

After completing this lab, continue by exploring:

* Helm chart hooks.
* Helm library charts.
* Named templates and advanced `_helpers.tpl` usage.
* Helm chart dependencies.
* Environment-specific values files.
* Secrets management with Helm.
* Helm schema validation using `values.schema.json`.
* Helm testing.
* The `helm-unittest` plugin.
* CI/CD pipelines for Helm charts.
* GitOps deployment of Helm charts with Argo CD.

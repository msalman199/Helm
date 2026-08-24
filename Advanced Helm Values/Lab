vanced Helm Values Management for Multi-Environment Deployments
Objectives
By the end of this lab, students will be able to:

Structure a Helm chart to support multiple environment configurations (development, staging, production)
Create and layer environment-specific values files to override defaults safely
Use Helm template helpers and conditional logic to render environment-aware Kubernetes manifests
Validate rendered templates and troubleshoot value overrides before deploying
Clean up all lab resources properly after testing
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes concepts (pods, services, deployments, namespaces)
Familiarity with YAML syntax and structure
Basic knowledge of Helm charts and templates
Comfort with Linux command line operations
This lab assumes you are working in an isolated, self-owned practice environment (a local VM, cloud sandbox, or dedicated lab machine). Install the following tools before beginning:

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install curl and git
sudo apt install -y curl git

# Install Docker (required for Kind)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
docker --version

# Install Kind (Kubernetes in Docker)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind --version

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
Create the local cluster you will use for the rest of the lab:

kind create cluster --name helm-lab
kubectl cluster-info --context kind-helm-lab
kubectl get nodes
Expected result: kubectl get nodes shows one node named helm-lab-control-plane in Ready status.

Task 1: Build a Multi-Environment Helm Chart
Step 1.1: Scaffold the chart
helm create webapp-multi-env
cd webapp-multi-env
ls -la
Deliverable: a webapp-multi-env/ directory containing the default Chart.yaml, values.yaml, templates/, and charts/ produced by helm create.

Step 1.2: Replace the default values file
Replace the generated values.yaml with a structure that supports environment-specific overrides.

cat > values.yaml << 'EOF'
# Default (base) values for webapp-multi-env
global:
  environment: development
  region: us-east-1
  monitoring:
    enabled: false

app:
  name: webapp
  port: 8080

image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent

replicaCount: 1

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

ingress:
  enabled: false
  className: ""
  hosts:
    - host: webapp.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

nodeSelector: {}
tolerations: []
affinity: {}

env:
  - name: APP_ENV
    value: "development"
  - name: LOG_LEVEL
    value: "debug"

configMap:
  enabled: true
  data:
    app.properties: |
      app.name=webapp
      log.level=debug
      database.pool.size=5

healthCheck:
  enabled: true
  livenessProbe:
    httpGet:
      path: /
      port: 8080
    initialDelaySeconds: 10
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 5
EOF
Step 1.3: Create environment override files
mkdir -p values

cat > values/values-dev.yaml << 'EOF'
global:
  environment: development
  monitoring:
    enabled: false

replicaCount: 1

image:
  tag: "1.25"

env:
  - name: APP_ENV
    value: "development"
  - name: LOG_LEVEL
    value: "debug"

configMap:
  enabled: true
  data:
    app.properties: |
      app.name=webapp-dev
      log.level=debug
      database.pool.size=2
EOF

cat > values/values-staging.yaml << 'EOF'
global:
  environment: staging
  monitoring:
    enabled: true

replicaCount: 2

image:
  tag: "1.25"

resources:
  limits:
    cpu: 250m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

env:
  - name: APP_ENV
    value: "staging"
  - name: LOG_LEVEL
    value: "info"

configMap:
  enabled: true
  data:
    app.properties: |
      app.name=webapp-staging
      log.level=info
      database.pool.size=10
      monitoring.enabled=true
EOF

cat > values/values-prod.yaml << 'EOF'
global:
  environment: production
  region: us-west-2
  monitoring:
    enabled: true

replicaCount: 3

image:
  tag: "1.25"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

env:
  - name: APP_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "warn"

configMap:
  enabled: true
  data:
    app.properties: |
      app.name=webapp-production
      log.level=warn
      database.pool.size=50
      monitoring.enabled=true
EOF
Deliverable: three files under values/ (values-dev.yaml, values-staging.yaml, values-prod.yaml), each overriding global.environment, replicaCount, and env relative to the base values.yaml.

Expected result: running ls values/ shows all three files present.

Task 2: Template the Chart to Consume Advanced Values
Step 2.1: Add environment-aware helpers
cat > templates/_helpers.tpl << 'EOF'
{{/*
Expand the name of the chart.
*/}}
{{- define "webapp-multi-env.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "webapp-multi-env.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "webapp-multi-env.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "webapp-multi-env.labels" -}}
helm.sh/chart: {{ include "webapp-multi-env.chart" . }}
{{ include "webapp-multi-env.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/environment: {{ .Values.global.environment }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "webapp-multi-env.selectorLabels" -}}
app.kubernetes.io/name: {{ include "webapp-multi-env.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
EOF
Step 2.2: Update the Deployment template
cat > templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp-multi-env.fullname" . }}
  labels:
    {{- include "webapp-multi-env.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "webapp-multi-env.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "webapp-multi-env.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.app.port }}
              protocol: TCP
          {{- if .Values.healthCheck.enabled }}
          livenessProbe:
            {{- toYaml .Values.healthCheck.livenessProbe | nindent 12 }}
          readinessProbe:
            {{- toYaml .Values.healthCheck.readinessProbe | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          env:
            {{- range .Values.env }}
            - name: {{ .name }}
              value: {{ .value | quote }}
            {{- end }}
          {{- if .Values.configMap.enabled }}
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
          {{- end }}
      {{- if .Values.configMap.enabled }}
      volumes:
        - name: config-volume
          configMap:
            name: {{ include "webapp-multi-env.fullname" . }}-config
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
EOF
Step 2.3: Update the ConfigMap template
cat > templates/configmap.yaml << 'EOF'
{{- if .Values.configMap.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "webapp-multi-env.fullname" . }}-config
  labels:
    {{- include "webapp-multi-env.labels" . | nindent 4 }}
data:
  {{- range $key, $value := .Values.configMap.data }}
  {{ $key }}: |
{{ $value | indent 4 }}
  {{- end }}
  environment: {{ .Values.global.environment | quote }}
  region: {{ .Values.global.region | default "us-east-1" | quote }}
  monitoring-enabled: {{ .Values.global.monitoring.enabled | quote }}
{{- end }}
EOF
Step 2.4: Remove unused default templates
The chart scaffold from helm create includes a hpa.yaml, serviceaccount.yaml, and tests/ directory that reference values (autoscaling, serviceAccount) we removed from values.yaml. Remove them so the chart renders cleanly:

rm -f templates/hpa.yaml templates/serviceaccount.yaml
rm -rf templates/tests
Deliverable: templates/ contains deployment.yaml, configmap.yaml, service.yaml, _helpers.tpl, and NOTES.txt (default). Running helm lint . should report 0 chart(s) failed.

Expected result:

helm lint .
produces output ending in 1 chart(s) linted, 0 chart(s) failed.

Task 3: Deploy, Compare, and Validate Environments
Step 3.1: Render templates for each environment before deploying
helm template webapp-dev . -f values/values-dev.yaml > /tmp/rendered-dev.yaml
helm template webapp-staging . -f values/values-staging.yaml > /tmp/rendered-staging.yaml
helm template webapp-prod . -f values/values-prod.yaml > /tmp/rendered-prod.yaml

grep -A1 "replicas:" /tmp/rendered-dev.yaml
grep -A1 "replicas:" /tmp/rendered-staging.yaml
grep -A1 "replicas:" /tmp/rendered-prod.yaml
Expected result: dev shows replicas: 1, staging shows replicas: 2, production shows replicas: 3, confirming the override files are being applied correctly.

Step 3.2: Create namespaces and deploy each environment
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

helm install webapp-dev . --namespace development --values values/values-dev.yaml
helm install webapp-staging . --namespace staging --values values/values-staging.yaml
helm install webapp-prod . --namespace production --values values/values-prod.yaml
Deliverable: three Helm releases (webapp-dev, webapp-staging, webapp-prod) deployed into three namespaces.

Step 3.3: Verify deployments and configuration data
kubectl get deployments -n development
kubectl get deployments -n staging
kubectl get deployments -n production

kubectl wait --for=condition=available --timeout=120s deployment/webapp-dev-webapp-multi-env -n development
kubectl wait --for=condition=available --timeout=120s deployment/webapp-staging-webapp-multi-env -n staging
kubectl wait --for=condition=available --timeout=120s deployment/webapp-prod-webapp-multi-env -n production

kubectl describe configmap webapp-prod-webapp-multi-env-config -n production
Expected result: all three kubectl wait commands print deployment.apps/... condition met, and the describe configmap output shows app.name=webapp-production, log.level=warn, and monitoring.enabled=true in the Data section.

Step 3.4: Compare rendered resource values across environments
echo "=== Replica Counts ==="
kubectl get deployment webapp-dev-webapp-multi-env -n development -o jsonpath='{.spec.replicas}'; echo " (Development)"
kubectl get deployment webapp-staging-webapp-multi-env -n staging -o jsonpath='{.spec.replicas}'; echo " (Staging)"
kubectl get deployment webapp-prod-webapp-multi-env -n production -o jsonpath='{.spec.replicas}'; echo " (Production)"

echo "=== Resource Limits ==="
kubectl get deployment webapp-dev-webapp-multi-env -n development -o jsonpath='{.spec.template.spec.containers[0].resources.limits}'; echo " (Development)"
kubectl get deployment webapp-staging-webapp-multi-env -n staging -o jsonpath='{.spec.template.spec.containers[0].resources.limits}'; echo " (Staging)"
kubectl get deployment webapp-prod-webapp-multi-env -n production -o jsonpath='{.spec.template.spec.containers[0].resources.limits}'; echo " (Production)"
Deliverable: a side-by-side confirmation that replica counts (1, 2, 3) and CPU/memory limits differ across the three environments, proving values files correctly override the chart defaults.

Expected result: development shows {"cpu":"100m","memory":"128Mi"} (inherited from the base values.yaml, since values-dev.yaml does not override resources), staging shows {"cpu":"250m","memory":"256Mi"}, and production shows {"cpu":"500m","memory":"512Mi"}.

Cleanup
Remove all Helm releases, namespaces, and the local cluster to leave the environment clean.

# Uninstall all Helm releases
helm uninstall webapp-dev -n development
helm uninstall webapp-staging -n staging
helm uninstall webapp-prod -n production

# Delete the namespaces
kubectl delete namespace development staging production

# Confirm no lab namespaces remain
kubectl get namespaces

# Delete the Kind cluster
kind delete cluster --name helm-lab
Expected result: kubectl get namespaces no longer lists development, staging, or production, and kind get clusters no longer lists helm-lab.

Expected Outcomes
A single Helm chart (webapp-multi-env) capable of deploying three distinct environment configurations from one shared template set
Verified, side-by-side proof that layered values files correctly override replica counts, resource limits, and ConfigMap data per environment
Practical experience validating templates with helm lint and helm template before applying changes to a live cluster
Troubleshooting
Issue 1: helm install fails with "execution error" referencing a missing value (e.g. nil pointer evaluating interface {}.enabled). Diagnostic hint: this usually means a values file overrides a nested key without preserving its parent structure (e.g. setting global.monitoring.enabled without global.environment present in the same merge). Run helm template <release> . -f <values-file> first to catch this before installing.

Issue 2: ConfigMap data does not reflect the environment-specific override you expected. Diagnostic hint: check the order of --values flags on the command line; Helm merges values files left-to-right, with later files taking precedence. Confirm with helm get values <release> -n <namespace> to see the effective merged values for a deployed release.

Conclusion
In this lab, students built a single Helm chart capable of deploying to development, staging, and production environments using layered, environment-specific values files rather than duplicating templates. Students practiced rendering and validating templates with helm lint and helm template before deployment, deployed all three environments into isolated namespaces on a local Kind cluster, and confirmed through direct inspection that replica counts, resource limits, and ConfigMap data correctly differed per environment. This reinforces the core Helm best practice of keeping one canonical template set and driving environment differences entirely through values, which reduces configuration drift and simplifies long-term chart maintenance. Students who want to continue building on this lab should explore Helm's values schema validation (values.schema.json), Helm hooks for pre/post-install automation, and integrating chart testing into a CI/CD pipeline.

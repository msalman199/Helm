Lab 5: Deploying Kubernetes Apps with Helm
Lab Objectives
By the end of this lab, you will be able to:

Install and configure Helm on a Kubernetes cluster
Deploy applications using Helm charts from public repositories
Customize application deployments by modifying values.yaml files
Manage Helm releases including upgrades and rollbacks
Understand the structure and components of Helm charts
Troubleshoot common Helm deployment issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes concepts (pods, services, deployments)
Familiarity with YAML file structure
Basic Linux command line knowledge
Understanding of containerized applications
Lab Environment
Al Nafi provides Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment. The provided Linux machine is bare metal with no pre-installed tools, so you will install all required components during the lab exercises.

Task 1: Setting Up the Environment
Subtask 1.1: Install Docker
First, we need to install Docker to support our Kubernetes environment.

# Update the package index
sudo apt update

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update

# Install Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add current user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker
Log out and log back in for the group changes to take effect, or run:

newgrp docker
Verify Docker installation:

docker --version
docker run hello-world
Subtask 1.2: Install kubectl
Install the Kubernetes command-line tool:

# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make kubectl executable
chmod +x kubectl

# Move kubectl to PATH
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
Subtask 1.3: Install and Start Minikube
Install Minikube to create a local Kubernetes cluster:

# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube cluster
minikube start --driver=docker

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
Subtask 1.4: Install Helm
Install Helm package manager for Kubernetes:

# Download Helm installation script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify Helm installation
helm version

# Add stable Helm repository
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repository information
helm repo update

# List available repositories
helm repo list
Task 2: Deploy an Application Using a Helm Chart
Subtask 2.1: Explore Available Helm Charts
Search for available charts in the repositories:

# Search for nginx charts
helm search repo nginx

# Search for wordpress charts
helm search repo wordpress

# Get detailed information about a specific chart
helm show chart bitnami/nginx
helm show readme bitnami/nginx
Subtask 2.2: Deploy NGINX Using Helm
Deploy an NGINX web server using the Bitnami Helm chart:

# Create a namespace for our application
kubectl create namespace helm-demo

# Deploy NGINX using Helm
helm install my-nginx bitnami/nginx --namespace helm-demo

# Check the deployment status
helm status my-nginx --namespace helm-demo

# List all Helm releases
helm list --namespace helm-demo

# Check Kubernetes resources created
kubectl get all --namespace helm-demo
Subtask 2.3: Access the Deployed Application
# Get the service details
kubectl get svc --namespace helm-demo

# Port forward to access the application locally
kubectl port-forward --namespace helm-demo svc/my-nginx 8080:80 &

# Test the application (open another terminal or run in background)
curl http://localhost:8080
You should see the default NGINX welcome page HTML content.

Subtask 2.4: Examine Helm Chart Structure
Download and examine a Helm chart structure:

# Create a directory for chart exploration
mkdir ~/helm-charts && cd ~/helm-charts

# Pull the nginx chart to examine its structure
helm pull bitnami/nginx --untar

# Explore the chart structure
ls -la nginx/
cat nginx/Chart.yaml
cat nginx/values.yaml
ls -la nginx/templates/
Task 3: Customize the values.yaml File for App Deployment
Subtask 3.1: Create a Custom values.yaml File
Create a custom configuration file to override default values:

# Create a custom values file
cat > custom-nginx-values.yaml << 'EOF'
# Custom NGINX configuration
replicaCount: 3

image:
  tag: "1.25.3"

service:
  type: NodePort
  nodePorts:
    http: 30080

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

ingress:
  enabled: false

# Custom index.html content
staticSiteConfigmap: |-
  <!DOCTYPE html>
  <html>
  <head>
      <title>Custom NGINX - Helm Lab</title>
      <style>
          body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
          h1 { color: #2E8B57; }
          p { color: #666; }
      </style>
  </head>
  <body>
      <h1>Welcome to Custom NGINX Deployment</h1>
      <p>This NGINX server was deployed using Helm with custom values!</p>
      <p>Lab 5: Deploying Kubernetes Apps with Helm</p>
  </body>
  </html>

# Pod security context
podSecurityContext:
  fsGroup: 1001

containerSecurityContext:
  runAsUser: 1001
  runAsNonRoot: true
EOF
Subtask 3.2: Deploy with Custom Values
Deploy a new NGINX instance using the custom values:

# Deploy with custom values
helm install custom-nginx bitnami/nginx \
  --namespace helm-demo \
  --values custom-nginx-values.yaml

# Check the deployment
helm list --namespace helm-demo
kubectl get pods --namespace helm-demo
kubectl get svc --namespace helm-demo
Subtask 3.3: Verify Custom Configuration
Verify that the custom configuration has been applied:

# Check the number of replicas
kubectl get deployment custom-nginx --namespace helm-demo

# Check the service type and port
kubectl get svc custom-nginx --namespace helm-demo

# Check resource limits
kubectl describe pod -l app.kubernetes.io/instance=custom-nginx --namespace helm-demo | grep -A 10 "Limits\|Requests"

# Access the custom application using NodePort
minikube service custom-nginx --namespace helm-demo --url
Copy the URL provided and test it:

# Replace <URL> with the actual URL from the previous command
curl <URL>
Subtask 3.4: Upgrade the Helm Release
Modify the custom values and upgrade the deployment:

# Create an updated values file
cat > updated-nginx-values.yaml << 'EOF'
# Updated NGINX configuration
replicaCount: 2

image:
  tag: "1.25.4"

service:
  type: NodePort
  nodePorts:
    http: 30080

resources:
  limits:
    cpu: 300m
    memory: 512Mi
  requests:
    cpu: 150m
    memory: 256Mi

staticSiteConfigmap: |-
  <!DOCTYPE html>
  <html>
  <head>
      <title>Updated NGINX - Helm Lab</title>
      <style>
          body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background-color: #f0f8ff; }
          h1 { color: #4169E1; }
          p { color: #333; }
          .version { background-color: #FFD700; padding: 10px; border-radius: 5px; display: inline-block; }
      </style>
  </head>
  <body>
      <h1>Updated NGINX Deployment</h1>
      <p>This NGINX server has been upgraded using Helm!</p>
      <div class="version">Version: 1.25.4</div>
      <p>Lab 5: Deploying Kubernetes Apps with Helm - Updated</p>
  </body>
  </html>

podSecurityContext:
  fsGroup: 1001

containerSecurityContext:
  runAsUser: 1001
  runAsNonRoot: true
EOF

# Upgrade the release
helm upgrade custom-nginx bitnami/nginx \
  --namespace helm-demo \
  --values updated-nginx-values.yaml

# Check upgrade status
helm status custom-nginx --namespace helm-demo

# View release history
helm history custom-nginx --namespace helm-demo
Subtask 3.5: Rollback and Cleanup
Learn how to rollback and clean up Helm releases:

# Rollback to previous version
helm rollback custom-nginx 1 --namespace helm-demo

# Verify rollback
helm history custom-nginx --namespace helm-demo

# Test the application to confirm rollback
minikube service custom-nginx --namespace helm-demo --url

# List all releases
helm list --namespace helm-demo

# Uninstall releases
helm uninstall my-nginx --namespace helm-demo
helm uninstall custom-nginx --namespace helm-demo

# Verify cleanup
kubectl get all --namespace helm-demo
Task 4: Working with WordPress - A More Complex Application
Subtask 4.1: Deploy WordPress with Custom Configuration
Deploy WordPress with MySQL using Helm:

# Create custom values for WordPress
cat > wordpress-values.yaml << 'EOF'
# WordPress configuration
wordpressUsername: admin
wordpressPassword: SecurePass123!
wordpressEmail: admin@example.com
wordpressBlogName: "My Helm Lab Blog"

# Service configuration
service:
  type: NodePort
  nodePorts:
    http: 30081

# MySQL configuration
mysql:
  auth:
    rootPassword: RootPass123!
    database: wordpress
    username: wordpress
    password: WordPressPass123!

# Persistence (disabled for lab simplicity)
persistence:
  enabled: false

mysql:
  primary:
    persistence:
      enabled: false

# Resource limits
resources:
  limits:
    memory: 512Mi
    cpu: 300m
  requests:
    memory: 256Mi
    cpu: 150m
EOF

# Deploy WordPress
helm install my-wordpress bitnami/wordpress \
  --namespace helm-demo \
  --values wordpress-values.yaml \
  --timeout 10m

# Monitor the deployment
kubectl get pods --namespace helm-demo -w
Press Ctrl+C to stop watching when all pods are running.

Subtask 4.2: Access and Test WordPress
# Check the deployment status
helm status my-wordpress --namespace helm-demo

# Get the WordPress URL
minikube service my-wordpress --namespace helm-demo --url

# Get WordPress admin credentials
echo "Username: admin"
echo "Password: SecurePass123!"
Subtask 4.3: Examine WordPress Helm Chart Components
# Check all resources created by WordPress chart
kubectl get all --namespace helm-demo -l app.kubernetes.io/instance=my-wordpress

# Check secrets created
kubectl get secrets --namespace helm-demo

# Check configmaps
kubectl get configmaps --namespace helm-demo

# Examine the WordPress deployment
kubectl describe deployment my-wordpress --namespace helm-demo
Troubleshooting Common Issues
Issue 1: Pods Stuck in Pending State
# Check pod status and events
kubectl describe pod <pod-name> --namespace helm-demo

# Check node resources
kubectl top nodes

# Check if Minikube needs more resources
minikube config set memory 4096
minikube config set cpus 2
minikube delete
minikube start --driver=docker
Issue 2: Helm Installation Fails
# Check Helm repository status
helm repo list
helm repo update

# Verify Kubernetes connection
kubectl cluster-info

# Check namespace exists
kubectl get namespaces
Issue 3: Service Not Accessible
# Check service status
kubectl get svc --namespace helm-demo

# Verify Minikube tunnel (if needed)
minikube tunnel

# Check firewall rules
sudo ufw status
Lab Cleanup
Clean up all resources created during the lab:

# Uninstall all Helm releases
helm uninstall my-wordpress --namespace helm-demo

# Delete the namespace
kubectl delete namespace helm-demo

# Stop Minikube (optional)
minikube stop

# Remove Minikube cluster (optional)
minikube delete
Key Concepts Summary
Helm Charts: Pre-configured Kubernetes application packages that include all necessary resources and configurations.

values.yaml: Configuration file that allows customization of Helm chart deployments without modifying the chart templates.

Helm Repositories: Collections of Helm charts that can be searched, downloaded, and installed.

Helm Releases: Instances of Helm charts deployed to a Kubernetes cluster with specific configurations.

Chart Templates: Kubernetes manifest files with templating that get populated with values during deployment.

Conclusion
In this lab, you have successfully:

Set up a complete Kubernetes environment with Helm on a single Linux machine
Deployed applications using Helm charts from public repositories
Customized application deployments by modifying values.yaml files
Learned to upgrade and rollback Helm releases
Deployed both simple (NGINX) and complex (WordPress) applications
Understood the structure and components of Helm charts
This knowledge is essential for modern DevOps practices, as Helm simplifies the deployment and management of complex Kubernetes applications. You can now confidently use Helm to deploy, configure, and manage applications in Kubernetes environments, making your deployment processes more efficient and maintainable.

The skills you've learned here apply directly to production environments where Helm is widely used for application lifecycle management, configuration management, and automated deployments in Kubernetes clusters.

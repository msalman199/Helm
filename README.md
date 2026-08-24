# Microservice Helm Chart

This Helm chart deploys a custom microservice application on Kubernetes.

## Features

- Configurable replica count
- Environment-specific configurations
- Health checks and readiness probes
- Resource limits and requests
- Horizontal Pod Autoscaling support
- Ingress configuration
- ConfigMap support

## Installation

```bash
helm install my-microservice ./microservice-chart
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `simple-microservice` |
| `image.tag` | Image tag | `v1.0.0` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |

## Examples

### Development Deployment
```bash
helm install microservice-dev . --values values-dev.yaml
```

### Production Deployment
```bash
helm install microservice-prod . --values values-prod.yaml --namespace production
```

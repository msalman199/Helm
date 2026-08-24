#!/bin/bash

RELEASE_NAME=$1

if [ -z "$RELEASE_NAME" ]; then
    echo "Usage: $0 <release-name>"
    exit 1
fi

echo "=== Helm Troubleshooting Report for $RELEASE_NAME ==="
echo

echo "1. Helm Release Information:"
helm list -f $RELEASE_NAME
echo

echo "2. Release History:"
helm history $RELEASE_NAME
echo

echo "3. Release Status:"
helm status $RELEASE_NAME
echo

echo "4. Kubernetes Resources:"
kubectl get all -l app.kubernetes.io/instance=$RELEASE_NAME
echo

echo "5. Common Issues Check:"
deployment_name="${RELEASE_NAME}-webapp-chart"

if kubectl get deployment $deployment_name >/dev/null 2>&1; then
    echo "Deployment exists: OK"
    ready=$(kubectl get deployment $deployment_name -o jsonpath='{.status.readyReplicas}')
    desired=$(kubectl get deployment $deployment_name -o jsonpath='{.spec.replicas}')
    if [ "$ready" = "$desired" ]; then
        echo "All replicas ready: OK ($ready/$desired)"
    else
        echo "Replicas NOT fully ready: ($ready/$desired)"
    fi
else
    echo "Deployment not found"
fi

failed_pods=$(kubectl get pods -l app.kubernetes.io/instance=$RELEASE_NAME --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
echo "Failed pods: $failed_pods"

echo
echo "=== End of Troubleshooting Report ==="

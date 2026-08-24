#!/bin/bash

RELEASE_NAME="webapp-v1"

echo "Performing health check for release: $RELEASE_NAME"

READY_REPLICAS=$(kubectl get deployment ${RELEASE_NAME}-webapp-chart -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl get deployment ${RELEASE_NAME}-webapp-chart -o jsonpath='{.spec.replicas}')

echo "Ready replicas: $READY_REPLICAS"
echo "Desired replicas: $DESIRED_REPLICAS"

if [ "$READY_REPLICAS" != "$DESIRED_REPLICAS" ]; then
    echo "Health check failed! Initiating rollback..."

    PREVIOUS_REVISION=$(helm history $RELEASE_NAME --max 2 -o json | jq -r '.[0].revision')

    echo "Rolling back to revision: $PREVIOUS_REVISION"
    helm rollback $RELEASE_NAME $PREVIOUS_REVISION

    echo "Rollback completed!"
else
    echo "Health check passed! Deployment is healthy."
fi

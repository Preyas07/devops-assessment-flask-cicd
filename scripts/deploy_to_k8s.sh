#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${KUBECONFIG:-}" ]]; then
  echo "Set KUBECONFIG to your kubeconfig path"
  exit 1
fi

DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-youruser}"
IMAGE_TAG="${1:-latest}"
IMAGE="$DOCKERHUB_USERNAME/hello-flask:$IMAGE_TAG"

sed -i "s#your-dockerhub-username#${DOCKERHUB_USERNAME}#g" k8s/deployment.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl set image deployment/hello-flask hello-flask="$IMAGE"
kubectl rollout status deployment/hello-flask --timeout=120s
kubectl get svc hello-flask -o wide

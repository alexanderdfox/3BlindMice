#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./push.sh [hub-repo]
# Example:
#   ./push.sh alexanderdfox/three-blind-mice-web
# If not provided, defaults to alexanderdfox/three-blind-mice-web

REPO_NAME="${1:-alexdgreatfox/three-blind-mice-web}"
IMAGE_LOCAL="three-blind-mice-web:latest"
GIT_SHA=$(git rev-parse --short HEAD)

# Optional non-interactive login using env vars
# Set DOCKERHUB_USERNAME and DOCKERHUB_TOKEN (or PASSWORD) to use
if [[ -n "${DOCKERHUB_USERNAME:-}" && -n "${DOCKERHUB_TOKEN:-${DOCKERHUB_PASSWORD:-}}" ]]; then
  echo "Logging into Docker Hub as ${DOCKERHUB_USERNAME} (non-interactive)"
  echo "${DOCKERHUB_TOKEN:-${DOCKERHUB_PASSWORD}}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin >/dev/null
else
  echo "Skipping docker login (run 'docker login' first or set DOCKERHUB_USERNAME and DOCKERHUB_TOKEN)"
fi

# Build
pushd "$(dirname "$0")" >/dev/null

echo "Building image ${IMAGE_LOCAL} ..."
docker build -t "${IMAGE_LOCAL}" .

# Tag
echo "Tagging ${IMAGE_LOCAL} as ${REPO_NAME}:latest and ${REPO_NAME}:${GIT_SHA} ..."
docker tag "${IMAGE_LOCAL}" "${REPO_NAME}:latest"
docker tag "${IMAGE_LOCAL}" "${REPO_NAME}:${GIT_SHA}"

# Push
echo "Pushing ${REPO_NAME}:latest ..."
docker push "${REPO_NAME}:latest"

echo "Pushing ${REPO_NAME}:${GIT_SHA} ..."
docker push "${REPO_NAME}:${GIT_SHA}"

popd >/dev/null

echo "Done. Pushed tags: latest, ${GIT_SHA} to ${REPO_NAME}"

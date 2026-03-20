#!/usr/bin/env bash
# Reproducible, cached Docker image build using BuildKit/buildx.
#
# This template repo is typically instantiated many times into the same shared
# STACKIT Harbor registry. Reproducible builds (via SOURCE_DATE_EPOCH) avoid
# pushing duplicate layers, and registry-backed build cache (via
# IMAGE_CACHE_REPOSITORY) speeds up subsequent builds across all instances.
set -euo pipefail

: "${IMAGE_REPOSITORY:?IMAGE_REPOSITORY must be set}"

IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
GIT_SHA="${GIT_SHA:-$(git rev-parse HEAD)}"
BUILD_METADATA_FILE="${BUILD_METADATA_FILE:-build-metadata.json}"
BUILDER_NAME="${BUILDER_NAME:-ci-buildx-${GITHUB_RUN_ID:-local}-$$}"
CONTEXT_NAME=""

source_date_epoch="$(git log -1 --pretty=%ct "${GIT_SHA}")"

context_target=()
if [[ -n "${DOCKER_HOST:-}" || -n "${DOCKER_TLS_VERIFY:-}" || -n "${DOCKER_CERT_PATH:-}" ]]; then
  CONTEXT_NAME="ci-buildx-context-${GITHUB_RUN_ID:-local}-$$"
  docker context create "${CONTEXT_NAME}" >/dev/null
  context_target=("${CONTEXT_NAME}")
fi

cleanup() {
  docker buildx rm "${BUILDER_NAME}" >/dev/null 2>&1 || true
  if [[ -n "${CONTEXT_NAME}" ]]; then
    docker context rm -f "${CONTEXT_NAME}" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

docker buildx create --name "${BUILDER_NAME}" --driver docker-container --use "${context_target[@]}" >/dev/null

build_cmd=(
  docker buildx build
  --file Dockerfile
  --platform linux/amd64
  --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}"
  --metadata-file "${BUILD_METADATA_FILE}"
  --provenance=false
  --sbom=false
  --tag "${IMAGE_REPOSITORY}:${IMAGE_TAG}"
)

if [[ -n "${IMAGE_CACHE_REPOSITORY:-}" ]]; then
  build_cmd+=(--cache-from "type=registry,ref=${IMAGE_CACHE_REPOSITORY}:buildcache")
  build_cmd+=(--cache-to "type=registry,ref=${IMAGE_CACHE_REPOSITORY}:buildcache,mode=max")
fi

build_cmd+=("$@")
build_cmd+=(.)

"${build_cmd[@]}"

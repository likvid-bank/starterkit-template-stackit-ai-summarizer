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

source_date_epoch="$(git log -1 --pretty=%ct "${GIT_SHA}")"

build_cmd=(
  docker buildx build
  --builder "$(docker context show)"
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
  build_cmd+=(--cache-to type=inline)
  build_cmd+=(--tag "${IMAGE_CACHE_REPOSITORY}:buildcache")
fi

if [[ -n "${BASE_IMAGE:-}" ]]; then
  build_cmd+=(--build-arg "BASE_IMAGE=${BASE_IMAGE}")
fi

build_cmd+=("$@")
build_cmd+=(.)

"${build_cmd[@]}"

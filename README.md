# STACKIT AI Summarizer – SKE Starter Kit Template

A ready-to-run demo application for the **STACKIT Kubernetes Engine (SKE) Starter Kit**.
It uses [STACKIT AI Model Serving](https://docs.stackit.cloud/products/data-and-ai/ai-model-serving/)
(OpenAI-compatible chat API) to summarize texts via a simple web UI.

This repository is designed as a **template** that is part of a meshStack landing zone.
When a team provisions the SKE Starter Kit building block, this repo is cloned as their
starting point — complete with a working app, CI/CD pipelines and Helm-based Kubernetes
deployment.

> **Upstream template:** [likvid-bank/starterkit-template-stackit-ai-summarizer](https://github.com/likvid-bank/starterkit-template-stackit-ai-summarizer)

## What's inside

| Path | Purpose |
|---|---|
| [`app/`](app/) | Python FastAPI application ([`main.py`](app/main.py), [`stackit_ai.py`](app/stackit_ai.py)) |
| [`static/index.html`](static/index.html) | Single-page web UI (client-side Markdown rendering) |
| [`Dockerfile`](Dockerfile) | Docker image based on `python:3.12-slim` |
| [`helm-chart/`](helm-chart/) | Helm chart for Kubernetes deployment (Ingress, TLS, health probes) |
| [`.forgejo/workflows/`](.forgejo/workflows/) | CI/CD: image build, Helm deploy, pipeline orchestration |

## Running locally

### Option A – Docker (recommended)

```bash
# 1. Build the image
docker build -t ai-summarizer:local .

# 2. Set your STACKIT AI credentials
export STACKIT_AI_BASE_URL="https://api.openai-compat.model-serving.eu01.onstackit.cloud/v1"
export STACKIT_AI_API_KEY="<your-api-key>"
export STACKIT_AI_MODEL="<your-model-name>"

# 3. Run the container
docker run --rm \
  -e STACKIT_AI_BASE_URL \
  -e STACKIT_AI_API_KEY \
  -e STACKIT_AI_MODEL \
  -e PORT=8080 \
  -p 8080:8080 \
  ai-summarizer:local

# 4. Open http://localhost:8080
```

### Option B – Python directly

```bash
pip install -r app/requirements.txt

export STACKIT_AI_BASE_URL="https://api.openai-compat.model-serving.eu01.onstackit.cloud/v1"
export STACKIT_AI_API_KEY="<your-api-key>"
export STACKIT_AI_MODEL="<your-model-name>"

uvicorn app.main:app --host 0.0.0.0 --port 8080
```

### Environment variables

| Variable | Description |
|---|---|
| `STACKIT_AI_BASE_URL` | OpenAI-compatible endpoint URL for STACKIT Model Serving |
| `STACKIT_AI_API_KEY` | API key / service account token |
| `STACKIT_AI_MODEL` | Name of the deployed model |
| `PORT` | Server listen port (default `8000`) |

### API endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Web UI |
| `GET` | `/health` | Health check (`{"status": "ok"}`) |
| `POST` | `/summarize` | Accepts `{"text": "..."}`, returns `{"summary": "..."}` |

## CI/CD – Forgejo Workflows

The [`.forgejo/workflows/`](.forgejo/workflows/) directory contains a complete build-and-deploy pipeline:

- **[`pipeline.yaml`](.forgejo/workflows/pipeline.yaml)** – Orchestrates the full flow: build image → deploy dev → deploy prod.
  Triggered on push to `main` or via manual `workflow_dispatch`.
- **[`build-image.yaml`](.forgejo/workflows/build-image.yaml)** – Reusable workflow that builds a Docker image with BuildKit/buildx,
  pushes to a Harbor registry, and outputs the image digest.
- **[`deploy.yaml`](.forgejo/workflows/deploy.yaml)** – Reusable workflow that deploys the Helm chart to a Kubernetes cluster
  (dev or prod stage), pinned to the exact image digest from the build step.

### Required repository secrets and variables

| Name | Type | Description |
|---|---|---|
| `HARBOR_REGISTRY` | Variable | Harbor registry hostname |
| `HARBOR_PROJECT` | Variable | Harbor project name |
| `APP_NAME` | Variable | Application name (used for image and Helm release) |
| `HARBOR_USERNAME` | Secret | Harbor push credentials |
| `HARBOR_PASSWORD` | Secret | Harbor push credentials |
| `KUBECONFIG_DEV` | Secret | Kubeconfig for the dev cluster |
| `KUBECONFIG_PROD` | Secret | Kubeconfig for the prod cluster |
| `K8S_NAMESPACE_DEV` | Variable | Target namespace for dev |
| `K8S_NAMESPACE_PROD` | Variable | Target namespace for prod |
| `APP_HOSTNAME_DEV` | Variable | Ingress hostname for dev |
| `APP_HOSTNAME_PROD` | Variable | Ingress hostname for prod |

## Helm Chart

The [`helm-chart/`](helm-chart/) directory contains a minimal Helm chart for the deployment:

- **Deployment** with immutable image digest pinning (`image@sha256:...`)
- **STACKIT AI credentials** injected from a Kubernetes Secret via `envFrom.secretRef`
  (default secret name: `stackit-ai`, must contain `STACKIT_AI_BASE_URL`,
  `STACKIT_AI_API_KEY` and `STACKIT_AI_MODEL`)
- **Ingress** with TLS via cert-manager (`letsencrypt-prod`) and HAProxy ingress controller
- **Health probes** (liveness + readiness) on `/health`
- Stage-specific overrides via [`values-dev.yaml`](helm-chart/values-dev.yaml)

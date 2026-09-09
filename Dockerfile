# Simple Dockerfile for the AI summarizer demo app.
# Build from the repository root.
# See .forgejo/workflows/scripts/docker-image-build.sh for the CI build script.

# Overridable so CI can build from a registry mirror closer to the runner
# instead of a cold pull from GHCR (see build-image.yaml).
ARG BASE_IMAGE=ghcr.io/likvid-bank/starterkit-template-stackit-ai-summarizer/python:3.12.9-slim-bookworm
FROM ${BASE_IMAGE}

# Accept SOURCE_DATE_EPOCH from the build script for reproducible timestamps.
# BuildKit natively clamps COPY/ADD file timestamps when this ARG is set.
ARG SOURCE_DATE_EPOCH

WORKDIR /app

# Install Python dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir --disable-pip-version-check -r requirements.txt

# Copy application code and static assets
COPY app/*.py app/
COPY static/ static/

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PORT=8000

# Start the FastAPI app with uvicorn
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]

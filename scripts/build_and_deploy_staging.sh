#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

GIT_SHA=`git rev-parse --short HEAD`
TAG=${1:-$GIT_SHA}

# Build image
docker build -f Dockerfile --tag=gcr.io/flowlink-project/bitbucket.org/nurelmdevelopers/quickbooks-integration:$TAG .

# Push it to Google Cloud Registry
docker push gcr.io/flowlink-project/bitbucket.org/nurelmdevelopers/quickbooks-integration:$TAG

# Update deployment with new image
gcloud beta run deploy quickbooksintegrationstaging --image gcr.io/flowlink-project/bitbucket.org/nurelmdevelopers/quickbooks-integration:$TAG --region us-central1 --platform managed --allow-unauthenticated

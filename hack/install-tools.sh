#!/usr/bin/env bash

kubectl config use-context docker-desktop

# Install the cert manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update open-telemetry

helm repo add kedacore https://kedacore.github.io/charts
helm repo update kedacore

# Install OpenTelemetry Operator
helm install my-opentelemetry-operator open-telemetry/opentelemetry-operator -nopentelemetry-operator --create-namespace\
  --set "manager.collectorImage.repository=otel/opentelemetry-collector-contrib"

# Install KEDA
helm upgrade -i keda kedacore/keda -nkeda --create-namespace

# Install the otel add on
helm upgrade -i kedify-otel oci://ghcr.io/kedify/charts/otel-add-on -nkeda \
  --version=v0.0.5 \
  --skip-schema-validation \
  --set opentelemetry-collector.enabled=false \
  --set settings.metricStoreRetentionSeconds=60

#!/usr/bin/env bash

kubectl config use-context docker-desktop

# Uninstall OpenTelemetry Operator
helm uninstall my-opentelemetry-operator -nopentelemetry-operator

# Uninstall KEDA
helm uninstall keda -nkeda

# Uninstall the otel add on
helm uninstall kedify-otel -nkeda

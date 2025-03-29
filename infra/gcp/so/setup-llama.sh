#!/bin/sh
# deploy the model
k apply -f ../all-rawdeployment.yaml

# or if pv with the model is prepared
# k apply -f ../all-rawdeployment-pv.yaml

# helm upgrade -i keda kedify/keda --namespace keda --create-namespace --version v2.16.0-1
helm upgrade -i keda kedacore/keda -nkeda --create-namespace
helm upgrade -i kedify-otel oci://ghcr.io/kedify/charts/otel-add-on --version=v0.0.7  --set opentelemetry-collector.enabled=false --set settings.metricStore.retentionSeconds=7 --set validatingAdmissionPolicy.enabled=false
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm upgrade -i otel-operator open-telemetry/opentelemetry-operator -nopentelemetry-operator --create-namespace\
  --set "manager.collectorImage.repository=otel/opentelemetry-collector-contrib"
k apply -f ./collector-sidecar.yaml

k apply -f ./model-so.yaml
k apply -f ./nodes-so.yaml

# # metrics from scaler
# k port-forward -nkeda svc/keda-otel-scaler 8080

# # metrics from one of the model pods
# k port-forward svc/llama 8181:8080
# curl -s localhost:8181/metrics | grep '\(waiting{\|gpu_cache_usage_perc{\)'

# # logs from models
# stern llama -cmain

# # for svc
# PROMPT="What is capital of england?"
# curl -XPOST -H 'Content-Type: application/json' http://localhost:8080/v1/chat/completions -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "'${PROMPT}'"} ], "stream": false, "max_tokens": 500 }' | jq '.choices[].message.content'
# hey -c 200 -z 300s -t 60 -m POST -H 'Accept: */*' -H 'Content-Type: application/json' http://localhost:8080/v1/chat/completions -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "'${PROMPT}'"} ], "stream": false, "max_tokens": 300 }'
# hey -c 200 -z 300s -t 60 -m POST -H 'Accept: */*' -H 'Content-Type: application/json' http://localhost:8080/v1/chat/completions -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "'${PROMPT}'"} ], "stream": false, "max_tokens": 800 }'

# # to prevent possible caching
# for x in {0..50}; do (curl -s -XPOST -H 'Content-Type: application/json' http://localhost:8080/v1/chat/completions -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "Can you convert this to decimal? hex: '$(openssl rand -hex 3)'"} ], "stream": false, "max_tokens": 500 }' | jq '.choices[].message.content')& ; done


# # for ingress

# # streaming
# curl -N -s -XPOST -H 'Host: model' -H 'Content-Type: application/json' http://aicluster/v1/chat/completions -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "What is capital of england and tell me something about its history?"} ], "stream": true, "max_tokens": 50 }' \
#  | grep -E "content\":\"[^\"]+\""

# hey -c 200 -z 300s -t 90 -m POST -host model -H 'Content-Type: application/json' -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "What is the capital of england and tell me something about its history"} ], "stream": false, "max_tokens": 1200 }' http://aicluster/v1/chat/completions

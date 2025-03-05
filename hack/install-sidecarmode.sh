#!/usr/bin/env bash

kubectl config use-context docker-desktop

#kubectl apply -f config/gateway.yaml
ko apply -f config/sidecar
kubectl apply -f config/sidecar-gateway/004-ingress.yaml

#!/usr/bin/env bash

kubectl config use-context docker-desktop

#kubectl apply -f config/gateway.yaml
ko apply -f config/standalone
kubectl apply -f config/standalone-gateway/004-ingress.yaml

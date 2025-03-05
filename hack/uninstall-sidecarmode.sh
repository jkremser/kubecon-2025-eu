#!/usr/bin/env bash

kubectl config use-context docker-desktop

kubectl delete -f config/sidecar-gateway/004-ingress.yaml
kubectl delete -f config/sidecar

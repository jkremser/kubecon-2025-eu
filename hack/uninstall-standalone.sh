#!/usr/bin/env bash

kubectl config use-context docker-desktop

kubectl delete -f config/standalone-gateway/004-ingress.yaml
kubectl delete -f config/standalone

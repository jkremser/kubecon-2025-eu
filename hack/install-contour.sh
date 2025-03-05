#!/usr/bin/env bash

kubectl config use-context docker-desktop

# Install contour: static provisioner
kubectl apply -f config/contour/00-crds.yaml
kubectl apply -f config/contour/contour.yaml
kubectl apply -f config/contour/contour-cm.yaml
kubectl -n projectcontour rollout restart deployment/contour

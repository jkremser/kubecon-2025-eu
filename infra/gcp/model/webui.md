```
helm repo add open-webui https://helm.openwebui.com/
helm repo update open-webui
```

```
helm upgrade -i open-webui open-webui/open-webui --version=v5.25.0 \
   --set openaiBaseApiUrl=http://llama.default.svc:8080/v1 \
   --set ollama.enabled=false \
   --set pipelines.enabled=false \
   --set service.port=8080
k rollout status statefulset/open-webui
(k port-forward svc/open-webui 8080)&
open http://http://localhost:8080/
```

```
kubectl apply -f - <<ING
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: open-webui
spec:
  ingressClassName: nginx
  rules:
  - host: aicluster
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: open-webui
            port:
              number: 80
ING
```

```
# requires also nginx ingress controller (check setup-gcp.md)
open http://aicluster/
```
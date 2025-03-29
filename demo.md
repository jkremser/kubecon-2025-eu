k get deploy
k get ing

curl -N -s -XPOST -H 'Host: model' -H 'Content-Type: application/json' http://aicluster/v1/chat/completions -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "What is capital of england and tell me something about its history?"} ], "stream": true, "max_tokens": 50 }' | grep -E "content\":\"[^\"]+\""
# describe stream true/false, max_tokens

k describe deploy
# show the inject annotation

kp

k describe po -lapp=llama
# show the OTel sidecar

k get so model
k describe so model

k describe so model | grep Query

(k port-forward svc/llama 8080 &> /dev/null)&
curl -s localhost:8080/metrics | grep gpu_cache_usage_perc{


# hit the model 2x

(k port-forward -nkeda svc/keda-otel-scaler 8181:8080 &> /dev/null)&
curl -s localhost:8181/metrics | grep -v "#" | grep value_clamped

k port-forward -nkeda svc/keda-otel-scaler 8080

stern llama -cmain
(hey -c 200 -z 40s -t 90 -m POST -host model -H 'Content-Type: application/json' -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "What is the capital of england and tell me something about its history"} ], "stream": false, "max_tokens": 1200 }' http://aicluster/v1/chat/completions)&
stern llama -cmain

# after 20s
k get deployments.apps



# node scaling
curl -s localhost:8080/metrics | grep '\(waiting{\|gpu_cache_usage_perc{\)'
k annotate so gpu-nodes --overwrite autoscaling.keda.sh/paused=false
(hey -c 300 -z 80s -t 90 -m POST -host model -H 'Content-Type: application/json' -d '{ "model": "llama3", "messages": [ { "role": "user", "content": "What is the capital of england and tell me something about its history"} ], "stream": false, "max_tokens": 2400 }' http://aicluster/v1/chat/completions)&

cat infra/gcp/so/nodes-so.yaml

k get md
k get no

pkill hey

k scale md d1-gpu-nodes --replicas 0

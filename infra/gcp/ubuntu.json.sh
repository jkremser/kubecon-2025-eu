#!/bin/bash
# https://github.com/kubernetes-sigs/image-builder/blob/main/docs/book/src/capi/capi.md#configuration
set -eui pipefail
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# seed:
# k get po,daemonset -A -oyaml | grep 'image:' | sed 's/ //g' | sed 's/@sha.*//' | sed 's/image://' | sort | uniq

# models:
# k exec -ti llama-bbb744957-x75j5 bash
# # tar the model in /root/.cache/huggingface/
# k cp llama-bbb744957-x75j5:/root/.cache/huggingface/m.tar ./m.tar
# untar and store in image-builder repo under images/capi/ansible/roles/setup/files/tmp/models/
# diff --git images/capi/ansible/roles/setup/tasks/debian.yml images/capi/ansible/roles/setup/tasks/debian.yml
# index 41e0fd631..f449ee998 100644
# --- images/capi/ansible/roles/setup/tasks/debian.yml
# +++ images/capi/ansible/roles/setup/tasks/debian.yml
# @@ -12,6 +12,23 @@
#  # See the License for the specific language governing permissions and
#  # limitations under the License.
#  ---
# +
# +- name: foobar
# +  ansible.builtin.copy:
# +    src: tmp/models/hub
# +    dest: /models/
# +    local_follow: true
# +    owner: root
# +    group: root
# +    mode: "0644"

# docker.io/kserve/huggingfaceserver:v0.15.0-rc1-gpu

# container images that will be pre-fetch on the node
IMGS=$(cat <<EOF | tr '\n' ',' | rev | cut -c2- | rev
docker.io/vllm/vllm-openai:v0.6.4
nvcr.io/nvidia/cloud-native/gpu-operator-validator:v24.9.2
nvcr.io/nvidia/cloud-native/k8s-driver-manager:v0.7.0
nvcr.io/nvidia/cloud-native/k8s-mig-manager:v0.10.0-ubuntu20.04
nvcr.io/nvidia/driver:550.144.03-ubuntu24.04
nvcr.io/nvidia/k8s/dcgm-exporter:3.3.9-3.6.1-ubuntu22.04
nvcr.io/nvidia/k8s-device-plugin:v0.17.0
nvcr.io/nvidia/k8s/container-toolkit:v1.17.4-ubuntu20.04
quay.io/brancz/kube-rbac-proxy:v0.18.0
quay.io/cilium/cilium:v1.17.2
quay.io/cilium/cilium-envoy:v1.31.5-1741765102-efed3defcc70ab5b263a0fc44c93d316b846a211
registry.k8s.io/cloud-provider-gcp/gcp-compute-persistent-disk-csi-driver:v1.13.2
registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.9.3
EOF


# IMGS=$(cat <<EOF | tr '\n' ',' | rev | cut -c2- | rev
# docker.io/vllm/vllm-openai:v0.6.4
# nvcr.io/nvidia/cloud-native/gpu-operator-validator:v24.9.2
# nvcr.io/nvidia/cloud-native/k8s-driver-manager:v0.7.0
# nvcr.io/nvidia/cloud-native/k8s-mig-manager:v0.10.0-ubuntu20.04
# nvcr.io/nvidia/driver:550.144.03-6.8.0-1026-gcp-ubuntu22.04
# nvcr.io/nvidia/k8s/dcgm-exporter:3.3.9-3.6.1-ubuntu22.04
# nvcr.io/nvidia/k8s-device-plugin:v0.17.0
# nvcr.io/nvidia/k8s/container-toolkit:v1.17.4-ubuntu20.04
# quay.io/brancz/kube-rbac-proxy:v0.18.0
# quay.io/cilium/cilium:v1.17.2
# quay.io/cilium/cilium-envoy:v1.31.5-1741765102-efed3defcc70ab5b263a0fc44c93d316b846a211
# registry.k8s.io/cloud-provider-gcp/gcp-compute-persistent-disk-csi-driver:v1.13.2
# registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.9.3
# EOF
)
# jq '.additional_s3_endpoint="'${GCS_BUCKET}'"' "${DIR}/ubuntu.json" | sponge "${DIR}/ubuntu.json"

for rel_f in ubuntu.json ubuntu-drivers.json; do
  abs_f="${DIR}/${rel_f}"
  # uncomment if sponge isn't installed (formatting is lost though)
  #cat <<< $(jq '.additional_registry_images_list="'${IMGS}'"' "${abs_f}") > "${abs_f}"
  jq '.additional_registry_images_list="'${IMGS}'"' "${abs_f}" | sponge "${abs_f}"
  jq '.project_id="'${GCP_PROJECT}'"' "${abs_f}" | sponge "${abs_f}"
  jq '.zone="'${GCP_ZONE}'"' "${abs_f}" | sponge "${abs_f}"
  jq '.additional_s3_access="'${GCP_S3_KEY}'"' "${abs_f}" | sponge "${abs_f}"
  jq '.additional_s3_secret="'${GCP_S3_SECRET}'"' "${abs_f}" | sponge "${abs_f}"
  # jq '.machine_type="'${GCP_GPU_NODE_MACHINE_TYPE}'"' "${abs_f}" | sponge "${abs_f}"
done

# cp u${DIR}/buntu-drivers.json ${DIR}/image-builder/images/capi/packer/gce/ubuntu-2404.json
cp ${DIR}/ubuntu.json ${DIR}/image-builder/images/capi/packer/gce/ubuntu-2404.json

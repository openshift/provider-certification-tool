#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

registry="quay.io/mrbraga"


# build openshift-tests image (@openshift/origin)
test "$(podman image exists openshift-tests:latest; echo $?)" -eq 0 || \
    "$(dirname "$0")"/build-openshift-tests-image.sh

# generate tests
"$(dirname "$0")"/generate-tests-tiers.sh
"$(dirname "$0")"/generate-tests-exception.sh

# Download Sonobuoy
sb_version="0.56.6"
sb_filename="sonobuoy_${sb_version}_linux_amd64.tar.gz"
sb_url="https://github.com/vmware-tanzu/sonobuoy/releases/download/v${sb_version}/${sb_filename}"

mkdir -p ./tmp
rm -rvf ./tmp/* ./sonobuoy

wget ${sb_url} -P ./tmp
tar xfz ./tmp/${sb_filename} sonobuoy
./sonobuoy version

# create plugin image
podman build -t ${registry}/openshift-tests-provider-cert:latest .
podman push ${registry}/openshift-tests-provider-cert:latest

VERSION=$(date +%Y%m%d%H%M%S)
podman tag \
    ${registry}/openshift-tests-provider-cert:latest \
    ${registry}/openshift-tests-provider-cert:"${VERSION}"
podman push ${registry}/openshift-tests-provider-cert:"${VERSION}"

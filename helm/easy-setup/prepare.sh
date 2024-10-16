#!/bin/bash

# Copyright 2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


set -e

kind_cluster_name="easy-setup"
kind_context_name="kind-$kind_cluster_name"

docker stop "${kind_cluster_name}-registry" || true
docker rm "${kind_cluster_name}-registry" || true

if kind get clusters | grep "$kind_cluster_name"; then
  echo "Cluster '$kind_cluster_name' is already provisioned by Kind"
else
  echo "Creating new Kind cluster '$kind_cluster_name'"
  cat tests/kind.yml  | kind create cluster --name "$kind_cluster_name" --config -
fi

network=`docker inspect $kind_cluster_name-control-plane | jq '.[0].NetworkSettings.Networks | keys | .[0]' -r`
docker run \
    -d --restart=always -p "127.0.0.1:5000:5000" --network $network --name "${kind_cluster_name}-registry" \
    registry:2

echo "now on kind context, going to apply whats next in 15seconds"
sleep 5
kubectl --context $kind_context_name apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl patch configmap/ingress-nginx-controller -n ingress-nginx --type merge --patch-file tests/nginx-cm.yml
helm --kube-context $kind_context_name install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version "v1.13.3" \
  --set installCRDs=true
kubectl --context $kind_context_name apply -f tests/self-signed-ca.yml

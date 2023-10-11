# Copyright 2023 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


#!/bin/bash

set -e

rm -rf templates
mkdir templates
cd templates

# We generate all resources and name the files according to their kind and names
yq -s '[.kind, .metadata.name] | join("-") | downcase + ".yaml"' <(kustomize build ../../../config/updater/default)

for entry in ./*; do
  # For each file, we template their values using helm to add a prefix in front of their resources
  yq -i "$(cat ../yq/prefixes.yq)" $entry
  # For each file, we also make sure that ClusterRole can be deployed as Role if we dont use clusterDeployment
  yq -i "$(cat ../../operator/yq/clusterdeployment.yq)" $entry
done

# These files should be fully disabled if not a cluster deployment
for entry in ./*proxy.yaml ./*metrics*.yaml; do
  sed -i '1 i\{{- if $.Values.clusterDeployment }}' $entry
  echo "{{ end }}" >>$entry
done


yq -s '[.kind, .spec.names.kind] | join("-") | downcase  + ".yaml"' \
  <(kustomize build ../../../${ELEMENT_DEPLOYMENT_KUSTOMIZE_TARGET})

# Generate users-facing roles
yq "$(cat ../../operator/yq/resource-editor-role.yq)" ../../../watches.updater.yaml -s '["ClusterRole", .metadata.name] | join("-") | downcase + ".yaml"'
yq "$(cat ../../operator/yq/resource-viewer-role.yq)" ../../../watches.updater.yaml -s '["ClusterRole", .metadata.name] | join("-") | downcase + ".yaml"'

# We deploy CRDs and their related roles optionaly
for entry in ./customresourcedefinition-* ./*-editor.yaml ./*-viewer.yaml; do
  sed -i '1 i\{{- if $.Values.deployCrds }}' $entry
  echo "{{ end }}" >>$entry
done

# Generate the updater main role, which is based on watches.updater.yaml + standard watches.yaml
yq ". *+ load(\"../../../watches.updater.yaml\") | $(cat ../../operator/yq/main-role.yq)" ../../../watches.yaml >clusterrole-manager.yaml

# For each clusterrole & clusterrolebinding, we add a conditional namespace field under name:
for entry in ./clusterrole*.yaml; do
  sed -i '0,/^  name: .*/{/^  name: .*/ {
    r ../../operator/fragments/ClusterRole-Namespace.yaml
  }}' $entry
done

cat ../fragments/Updater-Permissions.yaml >>clusterrole-manager.yaml

cp ../fragments/Deployment-element-updater-controller-manager.yaml ./deployment-element-updater-controller-manager.yaml

# These files should be fully disabled if not deploying roles
exclude_files=".\/clusterrole(-element-.+-(metrics-reader|proxy))|(-element-.*-)|(-manager)|(binding-element-.*-(manager|proxy)).yaml"
for entry in ./clusterrole*.yaml
do
  if [[ $entry =~ $exclude_files ]]; then
    echo "ignoring $entry"
  else
    sed -i '1 i\{{- if $.Values.deployCrdRoles }}' $entry
    echo "{{ end }}" >> $entry
  fi
done

# These files should be fully disabled if not deploying manager
for entry in ./deployment*.yaml ./service*.yaml  ./role*.yaml
do
  sed -i '1 i\{{- if $.Values.deployManager }}' $entry
  echo "{{ end }}" >> $entry
done
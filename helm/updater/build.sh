# Copyright 2023-2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


#!/bin/bash

set -e

rm -rf templates
mkdir templates
cd templates

chart_functions_namespace="elementUpdater"
values_manager_parent_key="updater"

# We generate all resources and name the files according to their kind and names
yq -s '[.kind, .metadata.name] | join("-") | downcase + ".yaml"' <(kustomize build ../../../config/updater/default)

for entry in ./*; do
  # For each file, we template their values using helm to add a prefix in front of their resources
  yq -i "$(cat ../yq/prefixes.yq)" $entry
  sed -i "s/__CHART_FUNCTIONS_NAMESPACE__/$chart_functions_namespace/g" $entry
  # For each file, we also make sure that ClusterRole can be deployed as Role if we dont use clusterDeployment
  yq -i "$(cat ../../operator/yq/clusterdeployment.yq)" $entry
done

# These files should be fully disabled if not a cluster deployment
for entry in ./*proxy.yaml ./*metrics*.yaml; do
  sed -i '1 i\{{- if $.Values.clusterDeployment }}' $entry
  echo "{{ end }}" >> $entry
done


yq -s '[.kind, .spec.names.kind] | join("-") | downcase  + ".yaml"' \
  <(kustomize build ../../../${ELEMENT_DEPLOYMENT_KUSTOMIZE_TARGET})

# Generate users-facing roles
yq "$(cat ../../operator/yq/resource-editor-role.yq)" ../../../watches.updater.yaml -s '["ClusterRole", .metadata.name] | join("-") | downcase + ".yaml"'
yq "$(cat ../../operator/yq/resource-viewer-role.yq)" ../../../watches.updater.yaml -s '["ClusterRole", .metadata.name] | join("-") | downcase + ".yaml"'

# We deploy CRDs and their related roles optionaly
for entry in ./customresourcedefinition-*; do
  yq "$(cat ../../operator/yq/crds-conversion.yq)" $entry | diff -Bw "$entry" - | patch "$entry" -
  sed -i "s/__CHART_FUNCTIONS_NAMESPACE__/$chart_functions_namespace/g" $entry
  sed -i -e '1 i\{{- if $.Values.deployCrds }}'  -e '/caBundleReplacedByHelmBuild/{r ../fragments/ConversionWebhook-CaBundle.yaml' -e ' d}' $entry
# for each CRD, we had a conditional annotations field under name
  sed -i '0,/^  name: .*/{/^  name: .*/ {
  r ../../operator/fragments/CustomResourceDefinition-Annotations.yaml
}}' $entry
  echo "{{ end }}" >> $entry
done

yq ". *+ load(\"../../../watches.updater.yaml\") | $(cat ../../operator/yq/main-role.yq)" ../../../watches.yaml  | sed "s/__CHART_FUNCTIONS_NAMESPACE__/$chart_functions_namespace/g" >clusterrole-manager.yaml

# For each clusterrole & clusterrolebinding, we add a conditional namespace field under name:
for entry in ./clusterrole*.yaml; do
  sed -i '0,/^  name: .*/{/^  name: .*/ {
    r ../../operator/fragments/ClusterRole-Namespace.yaml
  }}' $entry
done
cat ../fragments/Updater-Permissions.yaml >>clusterrole-manager.yaml

cp ../fragments/Deployment-element-updater-controller-manager.yaml ./deployment-element-updater-controller-manager.yaml
cp ../../operator/fragments/ServiceAccount-conversion-webhook.yaml ./serviceaccount-conversion-webhook.yaml
cp  ../../operator/fragments/ConversionWebhook-Service.yaml ./service-element-conversion-webhook.yaml
cp  ../../operator/fragments/Deployment-conversion-webhook.yaml ./deployment-conversion-webhook.yaml
cp  ../../operator/fragments/Operator-ConfigMap.yaml ./configmap-ansible-cfg.yaml
cp ../../operator/fragments/_helpers.tpl ./_helpers.tpl
cp ../fragments/Updater-Service.yaml ./service-manager-metrics.yaml
cp ../fragments/Updater-ServiceMonitor.yaml ./service-monitor-manager.yaml
cp ../fragments/_variables.tpl ./_variables.tpl
sed -i "s/__CHART_FUNCTIONS_NAMESPACE__/$chart_functions_namespace/g;s/__VALUES_MANAGER_PARENT_KEY__/$values_manager_parent_key/g" ./*.yaml
sed -i "s/__CHART_FUNCTIONS_NAMESPACE__/$chart_functions_namespace/g;s/__VALUES_MANAGER_PARENT_KEY__/$values_manager_parent_key/g" ./*.tpl

# These files should be fully disabled if not deploying roles
exclude_files=".\/clusterrole(-element-.+-(metrics-reader|proxy))|(-element-.*-)|(-manager)|(binding-element-.*-(manager|proxy)).yaml"
for entry in ./clusterrole*.yaml
do
  if [[ $entry =~ $exclude_files ]]; then
    echo "ignoring $entry"
  else
    sed -i '1 i\{{- if $.Values.deployCrdRoles }}' $entry
    echo "{{ end }}" >> $entry

    if [[ $entry =~ editor\.yaml$ ]]; then
      sed -i '/namespace:.*/r ../../operator/fragments/ClusterRole-Editor.yaml' $entry
    elif [[ $entry =~ viewer\.yaml$ ]]; then
      sed -i '/namespace:.*/r ../../operator/fragments/ClusterRole-Viewer.yaml' $entry
    fi
  fi
done

# These files should be fully disabled if not deploying manager
for entry in ./deployment*manager.yaml ./service-manager-metrics.yaml ./role*.yaml
do
  sed -i '1 i\{{- if $.Values.deployManager }}' $entry
  echo "{{ end }}" >> $entry
done

cd ..
cp ./source-values.yaml ./values.yaml

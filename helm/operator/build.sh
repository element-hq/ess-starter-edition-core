# Copyright 2023 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


#!/bin/bash

set -e

rm -rf templates
mkdir templates
cd templates


# We generate all resources and name the files according to their kind and names
yq -s '[.kind, .metadata.name] | join("-") | downcase + ".yaml"' <(kustomize build ../../../config/default)

# We generate all resources and name the files according to their kind and names
yq -s '[.kind, .metadata.name] | join("-") | downcase + ".yaml"' <(kustomize build ../../../${BASE_CRD_KUSTOMIZE_TARGET})

# Escape any {{ }} in the underlying templates to Helm
sed -i 's/{{\(.*\)}}/{{ "{{" }}\1{{ "}}" }}/' *

for entry in ./*; do
  # For each file, we template their values using helm to add a prefix in front of their resources
  yq -i "$(cat ../yq/prefixes.yq)" $entry
  # For each file, we also make sure that ClusterRole can be deployed as Role if we dont use clusterDeployment
  yq -i "$(cat ../yq/clusterdeployment.yq)" $entry
done

# These files should be fully disabled if not a cluster deployment
for entry in ./*proxy.yaml ./*metrics*.yaml; do
  sed -i '1 i\{{- if $.Values.clusterDeployment }}' $entry
  echo "{{ end }}" >> $entry
done

# Generate users-facing roles
yq "$(cat ../yq/resource-editor-role.yq)" ../../../watches.yaml -s '["ClusterRole", .metadata.name] | join("-") | downcase + ".yaml"'
yq "$(cat ../yq/resource-viewer-role.yq)" ../../../watches.yaml -s '["ClusterRole", .metadata.name] | join("-") | downcase + ".yaml"'

# We deploy CRDs and their related roles optionaly
for entry in ./customresourcedefinition-*; do
  if grep -q caBundleReplacedByHelmBuild "$entry"; then
    yq "$(cat ../yq/crds-conversion.yq)" $entry | diff -Bw "$entry" - | patch "$entry" -
    # for each CRD with a conversion webhook, we had a conditional annotations field under name
    sed -i -e '/caBundleReplacedByHelmBuild/{r ../fragments/ConversionWebhook-CaBundle.yaml' -e ' d}' $entry
    sed -i '0,/^  name: .*/{/^  name: .*/ {
    r ../../operator/fragments/CustomResourceDefinition-Annotations.yaml
  }}' $entry
  fi

  sed -i -e '1 i\{{- if $.Values.deployCrds }}' $entry

  echo "{{ end }}" >> $entry
done

# Generate the operator main role
yq "$(cat ../yq/main-role.yq)" ../../../watches.yaml > clusterrole-manager.yaml

# For each clusterrole & clusterrolebinding, we add a conditional namespace field under name:
for entry in ./clusterrole*.yaml; do
  sed -i '0,/^  name: .*/{/^  name: .*/ {
    r ../../operator/fragments/ClusterRole-Namespace.yaml
  }}' $entry
done


cat ../fragments/Operator-Permissions.yaml >> clusterrole-manager.yaml

cp ../fragments/Deployment-element-operator-controller-manager.yaml ./deployment-element-operator-controller-manager.yaml
cp ../fragments/ConversionWebhook-Service.yaml ./service-element-conversion-webhook.yaml
cp ../fragments/certificate-conversion-webhook.yaml ./certificate-conversion-webhook.yaml
cp ../fragments/issuer-selfsigned.yaml ./issuer-selfsigned.yaml

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
for entry in ./deployment*.yaml ./service*.yaml ./role*.yaml
do
  sed -i '1 i\{{- if $.Values.deployManager }}' $entry
  echo "{{ end }}" >> $entry
done

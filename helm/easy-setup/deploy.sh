#!/bin/bash

# Copyright 2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


set -e

values_files_args=""
for arg in "$@"
do
  values_files_args+=" -f values/values.${arg}.yaml"
done

if [[ -z "$ESS_SYSTEM_CHART" ]]; then
  ESS_SYSTEM_CHART="ess-starter-edition-core/ess-system"
fi


helm --kube-context kind-easy-setup upgrade ess-system $ESS_SYSTEM_CHART --install --create-namespace --namespace ess-system --wait -f values.ess-crds.yaml --version 2.21.1
helm --kube-context kind-easy-setup upgrade ess ./ess-meta --install --create-namespace --namespace ess --wait -f values.ess-stack.yaml $values_files_args


kubectl --context kind-easy-setup wait -n ess --timeout=10m --for=condition=Successful ElementDeployment ess

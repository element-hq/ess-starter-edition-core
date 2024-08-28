#!/bin/bash

# Copyright 2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


values_files_args=""
for arg in "$@"
do
  values_files_args+=" -f values/values.${arg}.yaml"
done

helm --kube-context kind-easy-setup template --namespace ess -f values.ess-stack.yaml $values_files_args ess ./ess-meta --debug

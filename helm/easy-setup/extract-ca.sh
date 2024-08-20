#!/bin/bash

# Copyright 2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


kubectl get secrets/ess-stack-ca -n cert-manager --template='{{index .data "tls.crt"}}' | base64 -d  > ca.crt

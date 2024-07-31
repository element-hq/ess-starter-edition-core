# Copyright 2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


{{/*
Template the configuration of an ems image store from Helm values/secrets
*/}}
{{- define "ess.secrets.credentials.ems-image-store" }}
{{- with .Values.emsImageStore }}
{{- printf "{\"auths\":{\"registry.element.io\":{\"auth\":\"%s\"}, \"gitlab-registry.matrix.org/ems-image-store\":{\"auth\":\"%s\"}}}" (printf "%s:%s" .username .password | b64enc) (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}


# Copyright 2023-2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later



{{/*
Create a default fully qualified app name.
*/}}
{{- define "ess-system.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- tpl .Values.fullnameOverride . | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

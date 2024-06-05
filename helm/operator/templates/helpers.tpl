{{- define "elementOperator.prefix" }}
{{- if .Values.nameOverride -}}
{{ .Values.nameOverride }}
{{- else -}}
{{- if .Values.namePrefix -}}
{{ .Release.Name }}-{{ .Values.namePrefix }}
{{- else -}}
{{ .Release.Name }}
{{- end -}}
{{- end -}}
{{ end -}}

{{- define "elementOperator.controllerManagerFullname" }}
{{- include "elementOperator.prefix" . }}-controller-manager
{{- end -}}

{{- define "elementOperator.conversionWebhookFullname" }}
{{- include "elementOperator.prefix" . }}-conversion-webhook
{{- end -}}

{{- define "elementOperator.managerEnv" }}
{{- $defaultEnv :=  (include "elementOperator.baseEnv" .) | fromJson -}}
{{- $extraEnvs := dict -}}
{{- range .Values.operator.manager.extraEnvs }}
  {{- $extraEnvs = merge $extraEnvs (dict .name .value) -}}
{{- end }}
{{- $env := merge $defaultEnv $extraEnvs -}}
{{- range $key, $value := $env -}}
- name: {{ $key }}
  value: {{ $value | quote }}
{{ end -}}
{{- end -}}



{{- define "elementOperator.managerMaxReconciliationProcesses" }}
{{- $memoryLimit := .Values.operator.manager.resources.limits.memory -}}
{{- $value := regexFind "\\d+" $memoryLimit -}}
{{- $reconciliationProcesses := "" -}}
{{- if hasSuffix "Mi" $memoryLimit -}}
  {{- $reconciliationProcesses = max 1 (div (sub (int $value) 2048) 512 | int) -}}
{{- else if hasSuffix "Gi" $memoryLimit -}}
  {{- $reconciliationProcesses = max 1 (div (mul 1024 (sub (int $value) 2)) 512 | int) -}}
{{- end -}}
{{ $reconciliationProcesses }}
{{- end -}}


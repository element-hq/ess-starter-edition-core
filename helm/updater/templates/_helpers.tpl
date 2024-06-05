{{- define "elementUpdater.prefix" }}
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

{{- define "elementUpdater.controllerManagerFullname" }}
{{- include "elementUpdater.prefix" . }}-controller-manager
{{- end -}}

{{- define "elementUpdater.conversionWebhookFullname" }}
{{- include "elementUpdater.prefix" . }}-conversion-webhook
{{- end -}}

{{- define "elementUpdater.managerEnv" }}
{{- $defaultEnv :=  (include "elementUpdater.baseEnv" .) | fromJson -}}
{{- $extraEnvs := dict -}}
{{- range .Values.updater.manager.extraEnvs }}
  {{- $extraEnvs = merge $extraEnvs (dict .name .value) -}}
{{- end }}
{{- $env := merge $defaultEnv $extraEnvs -}}
{{- range $key, $value := $env -}}
- name: {{ $key }}
  value: {{ $value | quote }}
{{ end -}}
{{- end -}}



{{- define "elementUpdater.managerMaxReconciliationProcesses" }}
{{- $memoryLimit := .Values.updater.manager.resources.limits.memory -}}
{{- $value := regexFind "\\d+" $memoryLimit -}}
{{- $reconciliationProcesses := "" -}}
{{- if hasSuffix "Mi" $memoryLimit -}}
  {{- $reconciliationProcesses = max 1 (div (sub (int $value) 2048) 512 | int) -}}
{{- else if hasSuffix "Gi" $memoryLimit -}}
  {{- $reconciliationProcesses = max 1 (div (mul 1024 (sub (int $value) 2)) 512 | int) -}}
{{- end -}}
{{ $reconciliationProcesses }}
{{- end -}}


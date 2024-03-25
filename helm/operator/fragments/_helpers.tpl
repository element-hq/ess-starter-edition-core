{{- define "__CHART_FUNCTIONS_NAMESPACE__.prefix" }}
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

{{- define "__CHART_FUNCTIONS_NAMESPACE__.controllerManagerFullname" }}
{{- include "__CHART_FUNCTIONS_NAMESPACE__.prefix" . }}-controller-manager
{{- end -}}

{{- define "__CHART_FUNCTIONS_NAMESPACE__.conversionWebhookFullname" }}
{{- include "__CHART_FUNCTIONS_NAMESPACE__.prefix" . }}-conversion-webhook
{{- end -}}

{{- define "__CHART_FUNCTIONS_NAMESPACE__.managerEnv" }}
{{- $defaultEnv :=  (include "__CHART_FUNCTIONS_NAMESPACE__.baseEnv" .) | fromJson -}}
{{- $extraEnvs := dict -}}
{{- range .Values.__VALUES_MANAGER_PARENT_KEY__.manager.extraEnvs }}
  {{- $extraEnvs = merge $extraEnvs (dict .name .value) -}}
{{- end }}
{{- $env := merge $defaultEnv $extraEnvs -}}
{{- range $key, $value := $env -}}
- name: {{ $key }}
  value: {{ $value | quote }}
{{ end -}}
{{- end -}}

{{- define "__CHART_FUNCTIONS_NAMESPACE__.managerMaxReconciliationProcesses" }}
{{- $memoryLimit := .Values.__VALUES_MANAGER_PARENT_KEY__.manager.resources.limits.memory -}}
{{- $value := regexFind "\\d+" $memoryLimit -}}
{{- $reconciliationProcesses := "" -}}
{{- if hasSuffix "Mi" $memoryLimit -}}
  {{- $reconciliationProcesses = max 1 (div (sub (int $value) 2048) 512 | int) -}}
{{- else if hasSuffix "Gi" $memoryLimit -}}
  {{- $reconciliationProcesses = max 1 (div (mul 1024 (sub (int $value) 2)) 512 | int) -}}
{{- end -}}
{{ $reconciliationProcesses }}
{{- end -}}

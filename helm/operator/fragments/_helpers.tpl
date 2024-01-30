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

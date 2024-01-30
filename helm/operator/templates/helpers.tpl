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

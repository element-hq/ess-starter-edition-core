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

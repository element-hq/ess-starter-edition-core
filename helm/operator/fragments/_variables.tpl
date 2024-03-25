
{{- define "elementOperator.baseEnv" }}
{{- $default_env := dict "ANSIBLE_GATHERING" "explicit" -}}
{{- if not $.Values.clusterDeployment -}}
{{- $default_env := merge $default_env (dict "WATCH_NAMESPACE" .Release.Namespace) -}}
{{- end -}}
{{- $default_env | toJson -}}
{{- end -}}

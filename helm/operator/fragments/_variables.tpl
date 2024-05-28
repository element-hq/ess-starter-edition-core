
{{- define "elementOperator.baseEnv" }}
{{- $default_env := dict "ANSIBLE_GATHERING" "explicit" "ANSIBLE_REMOTE_TMP" "/.ansible/tmp" -}}
{{- if not $.Values.clusterDeployment -}}
{{- $default_env := merge $default_env (dict "WATCH_NAMESPACE" .Release.Namespace) -}}
{{- end -}}
{{- $default_env | toJson -}}
{{- end -}}

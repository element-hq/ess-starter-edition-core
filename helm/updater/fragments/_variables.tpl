
{{- define "elementUpdater.baseEnv" }}
{{- $defaultEnv := dict "ANSIBLE_GATHERING" "explicit" "ANSIBLE_REMOTE_TMP" "/.ansible/tmp" -}}
{{- if not $.Values.clusterDeployment -}}
{{- $defaultEnv := merge $defaultEnv (dict "WATCH_NAMESPACE" .Release.Namespace) -}}
{{- end -}}
{{- $defaultEnv | toJson -}}
{{- end -}}

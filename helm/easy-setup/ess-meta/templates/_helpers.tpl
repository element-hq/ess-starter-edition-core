# Copyright 2024 New Vector Ltd
#
# SPDX-License-Identifier: AGPL-3.0-or-later


{{/*
Template the configuration of the self signed ca
*/}}
{{- define "ess.secrets.self-signed-ca" }}
{{- $essStackCA := lookup "v1" "Secret" "cert-manager" "ess-stack-ca" }}
{{- if $essStackCA -}}
{{ index (lookup "v1" "Secret" "cert-manager" "ess-stack-ca").data "tls.crt" | b64dec }}
{{ index (lookup "v1" "Secret" "cert-manager" "ess-stack-ca").data "ca.crt" | b64dec }}
{{- end }}
{{- end }}


{{/*
Template the configuration of a synapse pg password shared between 2 charts
*/}}
{{- define "ess.secrets.password.shared-password" -}}

{{- $context := .context }}
{{- $sharedPasswordId := .sharedPasswordId }}

{{- /* Create "tmp_vars" dict inside ".Release" to store various stuff. */ -}}
{{- if not (index .context.Release "tmp_vars") -}}
{{-   $_ := set .context.Release "tmp_vars" dict -}}
{{- end -}}
{{- $key := printf "%s-%s" .context.Release.Name .sharedPasswordId -}}
{{- /* If $key does not yet exist in .Release.tmp_vars, then... */ -}}
{{- if not (index .context.Release.tmp_vars $key) -}}
{{- /* ... store random password under the $key */ -}}
{{-   $_ := set .context.Release.tmp_vars $key (randAlphaNum 20) -}}
{{- end -}}
{{- /* Retrieve previously generated value. */ -}}
{{- index .context.Release.tmp_vars $key -}}
{{- end -}}

{{/*
licenses: Apache-2.0
copyright: VMware, Inc., New-Vector

Generate secret password or retrieve one if already created.

Usage:
{{ include "common.secrets.passwords.manage" (dict "secret" "secret-name" "key" "keyName" "providedValues" (list "path.to.password1" "path.to.password2") "length" 10 "strong" false "chartName" "chartName" "context" $) }}

Params:
  - secret - String - Required - Name of the 'Secret' resource where the password is stored.
  - key - String - Required - Name of the key in the secret.
  - chartName - String - Optional - Name of the chart used when said chart is deployed as a subchart.
  - context - Context - Required - Parent context.
  - failOnNew - Boolean - Optional - Default to true. If set to false, skip errors adding new keys to existing secrets.
The order in which this function returns a secret password:
  1. Already existing 'Secret' resource
     (If a 'Secret' resource is found under the name provided to the 'secret' parameter to this function and that 'Secret' resource contains a key with the name passed as the 'key' parameter to this function then the value of this existing secret password will be returned)
  2. Password provided via the values.yaml
     (If one of the keys passed to the 'providedValues' parameter to this function is a valid path to a key in the values.yaml and has a value, the value of the first key with a value will be returned)
  3. Default password value
*/}}
{{- define "ess.secrets.passwords.manage-with-default" -}}

{{- $password := "" }}
{{- $subchart := "" }}
{{- $failOnNew := default true .failOnNew }}
{{- $chartName := default "" .chartName }}
{{- $defaultPasswordValue := .defaultPasswordValue }}
{{- $secretData := (lookup "v1" "Secret" .context.Release.Namespace .secret).data }}
{{- if $secretData }}
  {{- if hasKey $secretData .key }}
    {{- $password = index $secretData .key | b64dec  }}
  {{- else if $failOnNew }}
    {{- printf "\nPASSWORDS ERROR: The secret \"%s\" does not contain the key \"%s\"\n" .secret .key | fail -}}
  {{- end -}}
{{- else }}
  {{- $password = $defaultPasswordValue | toString }}
{{- end -}}
{{- printf "%s" $password -}}
{{- end -}}


{{/*
Generate secret password or retrieve one if already created.

Usage:
{{ include "common.secrets.passwords.manage" (dict "secret" "secret-name" "key" "keyName" "providedValues" (list "path.to.password1" "path.to.password2") "length" 10 "strong" false "chartName" "chartName" "context" $) }}

Params:
  - secret - String - Required - Name of the 'Secret' resource where the password is stored.
  - key - String - Required - Name of the key in the secret.
  - length - int - Optional - Length of the generated random password.
  - strong - Boolean - Optional - Whether to add symbols to the generated random password.
  - chartName - String - Optional - Name of the chart used when said chart is deployed as a subchart.
  - context - Context - Required - Parent context.
  - failOnNew - Boolean - Optional - Default to true. If set to false, skip errors adding new keys to existing secrets.
  - skipB64enc - Boolean - Optional - Default to false. If set to true, no the secret will not be base64 encrypted.
  - skipQuote - Boolean - Optional - Default to false. If set to true, no quotes will be added around the secret.
The order in which this function returns a secret password:
  1. Already existing 'Secret' resource
     (If a 'Secret' resource is found under the name provided to the 'secret' parameter to this function and that 'Secret' resource contains a key with the name passed as the 'key' parameter to this function then the value of this existing secret password will be returned)
  2. Password provided via the values.yaml
     (If one of the keys passed to the 'providedValues' parameter to this function is a valid path to a key in the values.yaml and has a value, the value of the first key with a value will be returned)
  3. Randomly generated secret password
     (A new random secret password with the length specified in the 'length' parameter will be generated and returned)

*/}}
{{- define "ess.secrets.passwords.manage" -}}

{{- $password := "" }}
{{- $subchart := "" }}
{{- $chartName := default "" .chartName }}
{{- $passwordLength := default 10 .length }}
{{- $secretData := (lookup "v1" "Secret" .context.Release.Namespace .secret).data }}
{{- if $secretData }}
  {{- if hasKey $secretData .key }}
    {{- $password = index $secretData .key | b64dec }}
  {{- else if not (eq .failOnNew false) }}
    {{- printf "\nPASSWORDS ERROR: The secret \"%s\" does not contain the key \"%s\"\n" .secret .key | fail -}}
  {{- end -}}
{{- else }}
  {{- if .context.Values.enabled }}
    {{- $subchart = $chartName }}
  {{- end -}}

  {{- if .strong }}
    {{- $subStr := list (lower (randAlpha 1)) (randNumeric 1) (upper (randAlpha 1)) | join "_" }}
    {{- $password = randAscii $passwordLength }}
    {{- $password = regexReplaceAllLiteral "\\W" $password "@" | substr 5 $passwordLength }}
    {{- $password = printf "%s%s" $subStr $password | toString | shuffle }}
  {{- else }}
    {{- $password = randAlphaNum $passwordLength }}
  {{- end }}
{{- end -}}
{{- if not .skipB64enc }}
{{- $password = $password | b64enc }}
{{- end -}}
{{- if .skipQuote -}}
{{- printf "%s" $password -}}
{{- else -}}
{{- printf "%s" $password | quote -}}
{{- end -}}
{{- end -}}

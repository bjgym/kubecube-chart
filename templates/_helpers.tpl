{{/*
Expand the name of the chart.
*/}}
{{- define "kubecube.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubecube.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubecube.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubecube.labels" -}}
helm.sh/chart: {{ include "kubecube.chart" . }}
{{ include "kubecube.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubecube.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubecube.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kubecube.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kubecube.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts.
The value is declared under `global`; a root-level `namespaceOverride` is still honoured so
overrides written against the older path keep working.
*/}}
{{- define "kubecube.namespace" -}}
  {{- if .Values.global.namespaceOverride -}}
    {{- .Values.global.namespaceOverride -}}
  {{- else if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{- define "kubecube.webhook.caBundle" -}}
{{- if eq .Values.global.certs.mode "auto" }}
caBundle: {{ print "{{ ca_crt }}" }}
{{- end }}
{{- if eq .Values.global.certs.mode "custom" }}
caBundle: {{ b64enc .Values.global.certs.custom.caCrt }}
{{- end }}
{{- end -}}
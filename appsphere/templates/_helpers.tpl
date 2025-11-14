{{/*
Expand the name of the chart.
*/}}
{{- define "appshpere.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "appshpere.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for all resources.
*/}}
{{- define "appshpere.labels" -}}
helm.sh/chart: {{ include "appshpere.chart" . }}
app.kubernetes.io/name: {{ include "appshpere.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Return the active color for service routing. Can be overridden per-app via `.activeColor`.
*/}}
{{- define "appshpere.activeColor" -}}
{{- default "blue" .Values.global.activeColor -}}



{{- end }}
{{/*
Expand the name of the chart.
*/}}
{{- define "app-template.name" -}}
{{- default .Chart.Name .Values.app.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "app-template.fullname" -}}
{{- if .Values.app.name }}
{{- .Values.app.name | trunc 63 | trimSuffix "-" }}
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
{{- define "app-template.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app-template.labels" -}}
helm.sh/chart: {{ include "app-template.chart" . }}
{{ include "app-template.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app-template.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app-template.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "app-template.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app-template.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create image URL
*/}}
{{- define "app-template.imageUrl" -}}
{{- if .Values.image.name }}
{{- printf "%s/%s/%s:%s" .Values.image.registry .Values.image.repository .Values.image.name .Values.image.tag }}
{{- else }}
{{- printf "%s/%s/%s:%s" .Values.image.registry .Values.image.repository (include "app-template.name" .) .Values.image.tag }}
{{- end }}
{{- end }}

{{/*
Create Harbor secret name
*/}}
{{- define "app-template.harborSecretName" -}}
{{- printf "%s-harbor-secret" (include "app-template.fullname" .) }}
{{- end }}
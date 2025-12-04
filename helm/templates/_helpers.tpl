{{/*
Helper functions for our Helm chart
*/}}

{{/*
Chart name
*/}}
{{- define "doda-sms-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Unique name for all resources
This combines the release name with chart name
e.g.: "helm install my-release ./helm" ==> "my-release-doda-sms-app"
*/}}
{{- define "doda-sms-app.fullname" -}}
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
Chart version label
*/}}
{{- define "doda-sms-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Labels to all resources
*/}}
{{- define "doda-sms-app.labels" -}}
helm.sh/chart: {{ include "doda-sms-app.chart" . }}
{{ include "doda-sms-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Labels used to connect Services to Deployments
*/}}
{{- define "doda-sms-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "doda-sms-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name not used yet
*/}}
{{- define "doda-sms-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "doda-sms-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

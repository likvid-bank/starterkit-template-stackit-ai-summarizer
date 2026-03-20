{{- define "app.name" -}}
{{ .Release.Name }}
{{- end -}}

{{- define "app.fullname" -}}
{{ include "app.name" . }}
{{- end -}}

{{- define "app.imageRepository" -}}
{{ default (printf "registry.onstackit.cloud/registry/%s" (include "app.name" .)) .Values.image.repository }}
{{- end -}}

{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
{{- end -}}

{{- define "app.chart" -}}
{{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "app.labels" -}}
{{ include "app.selectorLabels" . }}
helm.sh/chart: {{ include "app.chart" . }}
{{- if .Values.appVersion }}
app.kubernetes.io/version: {{ .Values.appVersion | quote }}
{{- end }}
{{- end -}}

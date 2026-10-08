{{/* _helpers.tpl: دوال صغيرة بنعيد استخدامها في كل الـ templates */}}

{{/* اسم موحّد: <release>-<chart> */}}
{{- define "dj.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}

{{/* labels موحّدة على كل المصادر */}}
{{- define "dj.labels" -}}
app: {{ include "dj.fullname" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}

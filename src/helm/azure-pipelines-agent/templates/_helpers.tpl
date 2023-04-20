{{/*
Expand the name of the chart.
*/}}
{{- define "this.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.

We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec). If release name contains chart name it will be used as a full name.
*/}}
{{- define "this.fullname" -}}
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
{{- define "this.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "this.labels" -}}
helm.sh/chart: {{ include "this.chart" . }}
{{ include "this.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "this.selectorLabels" -}}
app.kubernetes.io/name: {{ include "this.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use.
*/}}
{{- define "this.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "this.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Default SecurytyContext object to apply to containers.

Can be overriden by setting ".Values.securityContext".
*/}}
{{- define "this.defaultSecurityContext" -}}
allowPrivilegeEscalation: false
runAsNonRoot: false
runAsUser: 0
capabilities:
  drop: ["ALL"]
{{- end }}

{{/*
Common definition for Pod object.

Usage example:

{{- $data := dict
  "restartPolicy" "Always"
  "azpAgentName" (dict "value" (printf "%s-%s" (include "this.fullname" .) "template"))
}}
{{- include "this.podSharedTemplate" (merge (dict "Args" $data) . ) | nindent 6 }}
*/}}
{{- define "this.podSharedTemplate" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "this.serviceAccountName" . }}
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.initContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
terminationGracePeriodSeconds: {{ .Values.pipelines.timeout | int | required "A value for .Values.pipelines.timeout is required" }}
restartPolicy: {{ .Args.restartPolicy }}
containers:
  - name: azp-agent
    securityContext:
      {{- toYaml (mustMergeOverwrite (include "this.defaultSecurityContext" . | fromYaml) .Values.securityContext) | nindent 6 }}
    image: "{{ .Values.image.repository | required "A value for .Values.image.repository is required" }}:{{ .Values.image.flavor | required "A value for .Values.image.flavor is required" }}-{{ default .Chart.Version .Values.image.version }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    lifecycle:
      preStop:
        exec:
          command: [bash, -c, "bash ${AZP_HOME}/config.sh remove --auth PAT --token ${AZP_TOKEN}"]
    env:
      - name: VSO_AGENT_IGNORE
        value: AZP_TOKEN
      - name: AZP_AGENT_NAME
        {{- toYaml .Args.azpAgentName | nindent 8 }}
      - name: AZP_URL
        valueFrom:
          secretKeyRef:
            name: {{ include "this.fullname" . }}
            key: url
      - name: AZP_POOL
        value: {{ .Values.pipelines.pool | quote | required "A value for .Values.pipelines.pool is required" }}
      - name: AZP_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ include "this.fullname" . }}
            key: pat
      # Agent capabilities
      - name: flavor_{{ .Values.image.flavor | required "A value for .Values.image.flavor is required" }}
      {{- range .Values.pipelines.capabilities }}
      - name: {{ . }}
      {{- end }}
      {{- with .Values.additionalEnv }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 6 | required "A value for .Values.resources is required" }}
    volumeMounts:
      - name: azp-work
        mountPath: /home/root/azp-work
      - name: local-tmp
        mountPath: /home/root/.local/tmp
      {{- with .Values.extraVolumeMounts }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
volumes:
  - name: azp-work
    ephemeral:
      volumeClaimTemplate:
        spec:
          accessModes: [ "ReadWriteOnce" ]
          storageClassName: {{ .Values.pipelines.cacheType | required "A value for .Values.pipelines.cacheType is required" }}
          resources:
            requests:
              storage: {{ .Values.pipelines.cacheSize | required "A value for .Values.pipelines.cacheSize is required" }}
  - name: local-tmp
    ephemeral:
      volumeClaimTemplate:
        spec:
          accessModes: [ "ReadWriteOnce" ]
          storageClassName: {{ .Values.pipelines.tmpdirType | required "A value for .Values.pipelines.tmpdirType is required" }}
          resources:
            requests:
              storage: {{ .Values.pipelines.tmpdirSize | required "A value for .Values.pipelines.tmpdirSize is required" }}
  {{- with .Values.extraVolumes }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "kubecube.webhook.configuration" -}}
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  creationTimestamp: null
  name: kubecube-validating-webhook-configuration
webhooks:
  - admissionReviewVersions:
      - v1
      - v1beta1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-quota-kubecube-io-v1-cube-resource-quota
    failurePolicy: Fail
    name: vcuberesourcequota.kb.io
    rules:
      - apiGroups:
          - quota.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
          - DELETE
        resources:
          - cuberesourcequota
    sideEffects: None
  - admissionReviewVersions:
      - v1
      - v1beta1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-hotplug-kubecube-io-v1-hotplug
    failurePolicy: Fail
    name: vhotplug.kb.io
    rules:
      - apiGroups:
          - hotplug.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
          - DELETE
        resources:
          - hotplugs
    sideEffects: None
  - admissionReviewVersions:
      - v1
      - v1beta1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-cluster-kubecube-io-v1-cluster
    failurePolicy: Ignore
    name: vcluster.kb.io
    rules:
      - apiGroups:
          - cluster.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - clusters
    sideEffects: None
    timeoutSeconds: 1
  - admissionReviewVersions:
      - v1
      - v1beta1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-tenant-kubecube-io-v1-project
    failurePolicy: Fail
    name: vproject.kb.io
    rules:
      - apiGroups:
          - tenant.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
          - DELETE
        resources:
          - projects
    sideEffects: None
  - admissionReviewVersions:
      - v1
      - v1beta1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-tenant-kubecube-io-v1-tenant
    failurePolicy: Fail
    name: vtenant.kb.io
    rules:
      - apiGroups:
          - tenant.kubecube.io
        apiVersions:
          - v1
        operations:
          - DELETE
        resources:
          - tenants
    sideEffects: None
  - admissionReviewVersions:
      - v1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-app-kubecube-io-v1-resourcegroup
    failurePolicy: Fail
    name: vresourcegroup.app.kubecube.io
    rules:
      - apiGroups:
          - app.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - resourcegroups
    sideEffects: None
  - admissionReviewVersions:
      - v1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-app-kubecube-io-v1-agentsession
    failurePolicy: Fail
    name: vagentsession.app.kubecube.io
    rules:
      - apiGroups:
          - app.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - agentsessions
    sideEffects: None
  - admissionReviewVersions:
      - v1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-app-kubecube-io-v1-agentpermission
    failurePolicy: Fail
    name: vagentpermission.app.kubecube.io
    rules:
      - apiGroups:
          - app.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - agentpermissions
    sideEffects: None
  - admissionReviewVersions:
      - v1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-app-kubecube-io-v1-permissionrequest
    failurePolicy: Fail
    name: vpermissionrequest.app.kubecube.io
    rules:
      - apiGroups:
          - app.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - permissionrequests
    sideEffects: None
  - admissionReviewVersions:
      - v1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: kubecube
        namespace: {{ template "kubecube.namespace" . }}
        port: {{ .Values.kubecube.args.webhookServerPort }}
        path: /validate-app-kubecube-io-v1-changerequest
    failurePolicy: Fail
    name: vchangerequest.app.kubecube.io
    rules:
      - apiGroups:
          - app.kubecube.io
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - changerequests
    sideEffects: None
---
{{- end -}}

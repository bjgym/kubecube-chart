{{- define "warden.webhook.configuration" -}}
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  creationTimestamp: null
  name: warden-validating-webhook-configuration
webhooks:
  - admissionReviewVersions:
      - v1
      - v1beta1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: warden
        namespace: {{ template "kubecube.namespace" . }}
        port: 8443
        path: /validate-core-kubernetes-v1-resource-quota
    # Ignore rather than Fail: warden being unavailable must not block
    # ResourceQuota changes. The check is an early rejection for the console
    # path, not the only line of defence.
    failurePolicy: Ignore
    name: vresourcequota.kb.io
    # Only namespaces the platform manages carry this label; tenant, project and
    # space namespaces all get it when they are created. A ResourceQuota created
    # by anyone else in the cluster is therefore never intercepted.
    namespaceSelector:
      matchExpressions:
        - key: hnc.x-k8s.io/included-namespace
          operator: Exists
    rules:
      - apiGroups:
          - ""
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
          - DELETE
        resources:
          - resourcequotas
    sideEffects: None
    # The check reads the parent CubeResourceQuota from the pivot cluster, so
    # bound the latency it can add to an admission request.
    timeoutSeconds: 3
  - admissionReviewVersions:
      - v1
      - v1beta1
    clientConfig:
      {{- include "kubecube.webhook.caBundle" . | nindent 6 }}
      service:
        name: warden
        namespace: {{ template "kubecube.namespace" . }}
        port: 8443
        path: /warden-validate-hotplug-kubecube-io-v1-hotplug
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
        name: warden
        namespace: {{ template "kubecube.namespace" . }}
        port: 8443
        path: /warden-validate-tenant-kubecube-io-v1-project
    failurePolicy: Fail
    name: vproject.kb.io
    rules:
      - apiGroups:
          - tenant.kubecube.io
        apiVersions:
          - v1
        operations:
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
        name: warden
        namespace: {{ template "kubecube.namespace" . }}
        port: 8443
        path: /warden-validate-tenant-kubecube-io-v1-tenant
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
---
{{- end -}}
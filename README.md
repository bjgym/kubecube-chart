# KubeCube-Chart

KubeCube-Chart is a helm chart for KubeCube. This version is totally matching KubeCube version. The `appVersion` of Chart.yaml will pin to specifield KubeCube version.

## Prerequisites

- Kubernetes 1.16+
- helm v3+

## Get the Chart

To install the chart with the release name `kubecube` or `warden` in namespace `kubecube-system`:

- download to local

```console
git clone https://github.com/kubecube-io/kubecube-chart.git
```

## Install pivot cluster

Create `pivot-value.yaml` and set values as you wish.

```yaml
# pivot-value.yaml

global:
  # control-plane node IP which is used for exporting NodePort svc.
  nodeIP: x.x.x.x
  
  # set "true" to deploy if there were not already in cluster.
  dependencesEnable:  
    ingressController: "false"
    localPathStorage: "false"
    metricServer: "false"

  # set "enabled" if wanna open log application.
  hotPlugEnable:
    pivot:
      logseer: "disabled" 
      logagent: "disabled"
      elasticsearch: "disabled"

  localKubeConfig: xx # local cluster kubeconfig base64
  pivotKubeConfig: xx # pivot cluster kubeconfig base64

warden:
  containers:
    warden:
      args:
        cluster: "pivot-cluster"  # set current cluster name
```

```console
helm install kubecube -n kubecube-system --create-namespace ./kubecube-chart -f ./pivot-value.yaml
```

## Install member cluster

Create `member-value.yaml` and set values as you wish.

```yaml
# member-value.yaml

global:
  # control-plane node IP which is used for exporting NodePort svc.
  nodeIP: x.x.x.x
  
  # set "true" to deploy if there were not already in cluster.
  dependencesEnable: 
    ingressController: "false"
    localPathStorage: "false"
    metricServer: "false"
    
  # do not modify values as bellow.
  componentsEnable:
    kubecube: "false"
    warden: "true"
    audit: "false"
    webconsole: "false"
    cloudshell: "false"
    frontend: "false"
    
  # set "enabled" if wanna open log application.
  hotPlugEnable:
    common:
      logagent: "disabled"

  localKubeConfig: xx # local cluster kubeconfig base64
  pivotKubeConfig: xx # pivot cluster kubeconfig base64

warden:
  containers:
    warden:
      args:
        inMemberCluster: true
        cluster: "member-cluster"  # set current cluster name
```

```console
helm install warden -n kubecube-system --create-namespace ./kubecube-chart -f ./member-value.yaml
```

## Uninstalling the Chart
> **Note**: not found error can be ignored. 

### Before helm uninstall

```console
kubectl delete validatingwebhookconfigurations kubecube-validating-webhook-configuration warden-validating-webhook-configuration kubecube-monitoring-admission
```

To uninstall/delete the `kubecube` helm release in namespace `kubecube-system`:


### Uninstall KubeCube in control plane
```console
helm uninstall kubecube -n kubecube-system
```

### Uninstall Warden in member cluster
```console
helm uninstall warden -n kubecube-system
```

### After helm uninstall

The command removes all the Kubernetes components associated with the chart and deletes the release.

> **Note**: There are some RBAC resources that are used by the `preJob` that can not be deleted by the `uninstall` command above. You might have to clean them manually with tools like `kubectl`.  You can clean them by commands:

```console
kubectl delete sa/kubecube-pre-job -n kubecube-system
kubectl delete clusterRole/kubecube-pre-job 
kubectl delete clusterRoleBinding/kubecube-pre-job
kubectl delete ns kubecube-system kubecube-monitoring
```

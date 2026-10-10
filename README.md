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
    cloudshell: "true"
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

A member cluster that enables `componentsEnable.cloudshell` runs its own cloud shell, and that shell fetches the user's kubeconfig from the pivot at `https://<global.nodeIP>:30443`. Set `nodeIP` to the pivot's control-plane node IP and make that NodePort reachable from the member cluster. The pivot's own cloud shell reaches cube through its Service and needs neither.

## Upgrading from a release that installed HNC

This chart no longer installs HNC. Helm deletes only what it still renders, so an
upgrade leaves the HNC an earlier release installed **running** — its manager, its
webhooks and its CRDs — and they keep intercepting writes to every namespace the
platform owns. Remove them by hand, before or right after the upgrade:

```console
kubectl delete ns hnc-system
kubectl delete mutatingwebhookconfiguration hnc-mutating-webhook-configuration
kubectl delete validatingwebhookconfiguration hnc-validating-webhook-configuration
kubectl delete crd hierarchyconfigurations.hnc.x-k8s.io hncconfigurations.hnc.x-k8s.io subnamespaceanchors.hnc.x-k8s.io
kubectl delete clusterrole hnc-admin-role hnc-manager-role hnc-proxy-role
```

Deleting the namespace is not enough on its own: the webhook configurations and
the CRDs are cluster-scoped, so they outlive it, and a webhook whose service has
gone blocks every write to a managed namespace when its `failurePolicy` is `Fail`.

Nothing else is asked of you. The platform carries the tenancy itself now:

- warden labels every namespace it can place with `kubecube.io/namespace-owner`
  and its two derived keys, and strips the HNC labels and annotations from those
  same namespaces as it goes;
- a project's AlertmanagerConfigs, and exactly the Secrets they reference, are
  materialised into that project's spaces by warden rather than propagated by HNC;
- deleting a tenant deletes its projects, and deleting a project removes its
  namespace, so the tree is deleted from the top instead of the bottom.

To check that the cleanup has finished:

```console
kubectl get ns -l kubecube.hnc.x-k8s.io/tenant
kubectl get ns -l hnc.x-k8s.io/included-namespace
```

Both should return nothing. A namespace the platform cannot place is left exactly
as it is rather than guessed at, so a namespace with no owner label is not
necessarily a failure — it is one the platform declined to claim.

## Image tags

`values.yaml` is the only place a platform image tag is declared, under
`global.images`. `images.list` is what the installer pre-pulls
(`kubecube-installer/install_k8s.sh`), so the two must agree: a tag bumped in one
file and not the other pre-pulls an image the cluster never runs, and an
air-gapped install cannot recover from that. Check them before changing either:

```console
hack/verify-images.sh
```

The check is one-directional on purpose. `images.list` also carries subchart and
hotplug images, and older ingress controller tags kept for clusters on older
releases, that no `global.images` key describes, so requiring every line to be
derivable would fail on a correct file.

### Images deployed into member clusters

Three of these images are not used by the chart's own workloads. The control
plane deploys them into each member cluster when that cluster is registered:

| values key | environment variable | what it runs |
|---|---|---|
| `global.images.warden` | `WARDEN_IMAGE` | the warden Deployment in the member cluster |
| `global.images.wardenInit` | `WARDEN_INIT_IMAGE` | warden's init container, which unpacks the third-party chart cache into the `helm-pkg` volume |
| `global.images.dependenceJob` | `DEPENDENCE_JOB_IMAGE` | a Job named `install-dependence` |

`warden-dependence` is the one bootstrap image whose source is not in this
workspace — it is built elsewhere, and nothing here records what it does. What
the control plane does with it is visible in `KubeCube`: the Job mounts the
node's `/etc/kubernetes/pki` **writable** on a node carrying
`node-role.kubernetes.io/master`, runs before warden is deployed, and the
controller waits up to five minutes for it to complete. Treat it as a mutation of
the member cluster's control plane rather than as a container start, and read the
decision record before changing anything about it:
`.agents/notes/proposed/architecture/2026-10-10-remove-warden-dependence-bootstrap.md`
in the workspace root — it separates what is established from what is still
unknown, and says why the difference matters.

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

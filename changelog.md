# v1.8.3

## Feature
- grant the platform the Cilium CRDs — network policies, cluster-wide network
  policies, endpoints, identities and nodes — beside the calico ones it already
  held. Cilium is the CNI the installer now installs by default, and a member
  cluster is still free to run calico
- tolerate both `node-role.kubernetes.io/master` and
  `node-role.kubernetes.io/control-plane` taints on every platform deployment
  and the metrics-server subchart, so the chart schedules on kubeadm ≥1.25 and
  k0s ≥1.33 control-plane nodes without extra flags
- replace image pin to docker hub
- configurable sso identity providers, with the private half kept in a Secret
- enable api version conversion by default
- declare the vendored subcharts, so helm lint verifies them
- remove HNC. Tenancy is carried by kubecube.io/namespace-owner and its two
  derived labels instead of the HNC protocol, a project's AlertmanagerConfigs
  and the Secrets they reference are materialised by warden instead of being
  propagated, and a tenant's deletion cascades to its projects instead of being
  refused.
- member clusters can run the cloud shell: a shell that does not run in the pivot
  fetches the user's kubeconfig from the pivot's NodePort, and the member install
  example enables the component

## BugFix
- address the project and tenant webhooks from the release namespace
- scope the resource quota webhook to platform namespaces
- honour global.namespaceOverride
- remove the unused frontend image values
- run the webconsole and audit deployments under the platform service account,
  so webconsole leader election and the audit service's Hotplug watch are
  authorized instead of running as `default`
- grant the platform `bind` and `escalate` on roles and clusterroles: without
  them the API server refuses every binding the platform writes — starting with
  the built-in admin's own, which left the platform with no administrator and no
  way to appoint one
- sync the User CRD in `crds/crds.yaml` with its source in `KubeCube/config/crd/bases`:
  it was missing `spec.scopeBindings` and `status.belongProjectInfos`, so the API
  server pruned every scope binding on write and no user could ever be recorded
  as a platform administrator

## Upgrade
- this release does not remove the HNC deployment an earlier release installed:
  helm only deletes what it still renders, so the old manager, its webhooks and
  its CRDs survive an upgrade and keep intercepting writes. Delete the
  `hnc-system` namespace and the `hnc.x-k8s.io` webhook configurations by hand
  before upgrading, then clean the tenancy labels HNC wrote off the existing
  namespaces.

# v1.8.2

## Feature
- pin kubecube to v1.8.2
# v1.8.3

## Feature
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
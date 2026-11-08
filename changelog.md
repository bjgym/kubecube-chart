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
- serve the console through the chart's nginx configuration with a `/healthz`
  endpoint and a `/` redirect to `/public/`, and split its cache policy: the
  entry `index.html` is never cached while the content-hashed files under
  `public/assets/` are cached as immutable. The deployment probes `/healthz`
  instead of the SPA entry
- allow `frontend.image` to override the console image with a full reference,
  so the console can be published to a different registry than the platform
  images without moving the other components. This fork publishes it to
  `ghcr.io/bjgym/kubecube-front` because the Docker Hub `kubecube/frontend`
  repository is not writable from this workspace; the default is pinned to a
  `sha-<commit>` tag, not `latest`. The pinned tag tracks the console release that
  contains the density, responsive table, single-source policy, lazy-loading and
  root-layout changes
- allow `cloudshell.image` to override the CloudShell image with a full
  reference. The multi-arch image is built and published from
  `kubecube-webconsole` by the `publish-cloudshell-image` workflow, pinned to a
  `sha-<commit>` tag, so CloudShell no longer depends on an image built only on
  the verification host
- run the single-replica `webconsole` Deployment with the `Recreate` strategy.
  Its readiness probe reports ready only while the pod holds the leader-election
  lease, so a default rolling update deadlocks with the new pod waiting for a
  lease the old pod still holds
- grant the webconsole ServiceAccount `pods/exec` in the platform namespace
  through a namespaced Role and RoleBinding. The pivot CloudShell is a pod in
  that namespace and the webconsole reaches it with its own identity; without
  this rule the session opens and immediately closes with a 403

## BugFix
- name the metrics-server image after the upstream it is: `metrics-server:v0.7.2`.
  `rancher-metrics-server:v0.4.1-m` publishes only amd64, so on an arm64 node the
  kubelet cannot resolve the manifest list, takes the image for absent, tries to
  pull it, and the pod stays in ImagePullBackOff for the life of the cluster —
  with every usage figure in the console reading zero. The subchart's arguments
  and probes are upstream's own flags, so the upstream image is a drop-in. It has
  to be published as `docker.io/kubecube/metrics-server:v0.7.2` for the online
  path; the offline bundle retags it under its own tag
- grant `nodes/metrics` to the metrics-server ClusterRole. v0.7.x scrapes
  `/metrics/resource`, which the kubelet authorizes as `nodes/metrics`; 0.4.1 read
  `/stats/summary`, so `nodes/stats` was enough. Without it every scrape returns
  403, the pod stays `0/1`, and an install that waits for the release times out —
  the image move above is only complete with this rule
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
- read the custom certificate from the values `values.yaml` documents.
  `tls-secret.yaml` read `global.certs.tls.*` and `global.certs.ca.*`, which
  nothing sets, so `certs.mode: custom` rendered a Secret with no data in it and
  the failure surfaced later as a TLS error somewhere else. The values are PEM
  and a Secret's data is base64, so they are encoded the way the pre-install
  job's "auto" path encodes them, and an unset value now fails at render time
  and names itself instead of rendering an empty Secret

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
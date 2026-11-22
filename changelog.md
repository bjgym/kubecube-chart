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
- add the network management component behind
  `global.componentsEnable.netmgmt`, off by default. Its ServiceAccount,
  Deployment and Service render only when both `netmgmt` and `kubecube` are
  enabled, so a member cluster never gets them even if its values turn the
  component on. The pod gets no Kubernetes identity: the ServiceAccount and the
  pod disable token automounting, no Role/RoleBinding/ClusterRole/ClusterRoleBinding
  or Secret is created, and the only mount is cube's `ca.crt` at
  `/etc/cube-tls/ca.crt` (never `tls.key`, never a kubeconfig). It talks to cube
  over verified HTTPS (`CUBE_URL`, `CUBE_CA_FILE`, `CUBE_TLS_SERVER_NAME`) and
  its Service is cluster-internal only
- add the console nginx route `^~ /api/v1/netmgmt/` with the full
  `netmgmt.<namespace>.svc.cluster.local:8080` upstream, a per-request
  `kube-dns` resolver, `proxy_pass $upstream$request_uri` and
  `Host`/`X-Forwarded-Host`/`X-Forwarded-Proto` from the browser request. The
  upstream is a variable, so nginx starts, passes `nginx -t` and serves every
  other route while the component's Service does not exist
- terminate browser TLS in the console nginx: `frontend.tls.enabled`,
  `frontend.tls.secretName` and `frontend.tls.httpsNodePort` (30444; 30443 is
  already `kubecube-nodeport`'s HTTPS port) render an HTTPS server and an HTTP
  80 redirect that keeps `location = /healthz` served directly, so the HTTP
  liveness/readiness probes keep working. On the HTTPS server both
  `/api/v1/cube/` and `/api/v1/netmgmt/` force `Secure` on the `Authorization`
  `Set-Cookie` while leaving its `HttpOnly`/`SameSite` attributes as sent, so
  alternating between the console and the component cannot downgrade the
  session cookie
- publish `data.netmgmt` in `kubecube-feature-config`, so the console hides the
  component's tab and page when it is off, and add a `checksum/nginx-config`
  annotation to the frontend Deployment because the nginx ConfigMap is mounted
  with `subPath` and would otherwise never reach a running pod

## BugFix
- grant the platform admin and the reviewer read-only (`get`/`list`/`watch`)
  access to `ciliumnodeconfigs.cilium.io`. The netmgmt component can only
  verify the live Cilium write profile - and therefore only enable writes -
  when the caller can read `CiliumNodeConfig` and rule out a per-node override
  of `enable-policy`/`enable-k8s-networkpolicy`. With the narrower Cilium grant
  the profile reads `unknown` and every write stays disabled, which is the
  plan's conservative rule but not what the built-in administrator is supposed
  to hit. The rule is read-only because the platform verifies this cluster
  configuration instead of changing it; netmgmt itself still creates no RBAC
- make `hack/verify-images.sh` resolve a component's full-reference image
  override before comparing against `images.list`. `frontend.image` and
  `cloudshell.image` name a ghcr reference, so the check compared the unused
  `global.images` fallbacks against the list and reported both images missing on
  a correct chart; it now checks the reference the chart actually deploys
- serialize consecutive workspace scope changes. A cluster switch commits its
  URL before the new namespace list is available; a following namespace change
  now waits for that scope to finish applying and the selectors stay disabled
  during the transition, instead of computing the next target from stale state
- make workspace scope changes transactional. The console now navigates to the
  target scope first and commits URL and store only after the router guard
  accepts, so cancelling a dirty-editor prompt leaves both the edit target and
  the current scope unchanged; details return to the same resource list.
  CloudShell labels are pinned to the scope captured when the session opened,
  and `/namespace` is labelled 空间总览 while the selector is 当前工作空间
- remove the duplicate area-switch action from the header. 空间总览, 资源控制台
  and 运维管理 are owned by the sidebar; the header now carries only the current
  area title and account actions
- make the three console areas explicit in the sidebar: 空间总览, 资源控制台 and,
  for manager roles, 运维管理. The space overview and resource pages now have
  distinct titles, returning from platform administration lands on 空间总览, and
  the resource-console landing follows the monitoring feature flag
- keep the resource-console sidebar on the space overview. Switching
  from 运维管理 to 资源控制台 starts at `/namespace`, which used to be the one
  console route without navigation; the page now renders the same sidebar as the
  rest of the console
- fix the CloudShell session end to end. The pivot fallback now uses the
  in-cluster REST config, the webconsole accepts the current account from the
  frontend, the chart grants the webconsole `pods/exec` on the platform
  namespace, and the chroot script resolves the jail user to numeric ids before
  entering it. The frontend and CloudShell image pins move to the commits that
  carry these fixes
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
- the network management component is opt-in. Enabling it is one step -
  `global.componentsEnable.netmgmt: "true"` and an image in
  `global.images.netmgmt`/`images.list` - but turning it off is only the
  component rollback: NetworkPolicies it created, updated or deleted stay in
  effect, because v1 does not version policies on the server and offers no
  automatic undo. Treat "disable the component" and "restore the policies" as
  two separate steps, using `writeResultUID`/`writeResultResourceVersion` from
  the write responses.
- install scope in v1: an online install pre-pulls every line of `images.list`,
  so the netmgmt image is pulled even while the component is off and an image
  that cannot be pulled fails the installation. An offline bundle does not pick
  the chart's `images.list` up automatically, so enabling the component offline
  is out of scope until the image is added to the offline packaging flow.
- the console's HTTP NodePort 30080 is development/experimental only. For a
  production install set `frontend.tls.enabled: true` and
  `frontend.tls.secretName` to a Secret in the release namespace carrying a
  browser-trusted `tls.crt`/`tls.key`; the browser then uses
  `https://<nodeIP>:30444`. The HTTP port still answers `/healthz` for the
  probes and redirects every other path.
- this release does not remove the HNC deployment an earlier release installed:
  helm only deletes what it still renders, so the old manager, its webhooks and
  its CRDs survive an upgrade and keep intercepting writes. Delete the
  `hnc-system` namespace and the `hnc.x-k8s.io` webhook configurations by hand
  before upgrading, then clean the tenancy labels HNC wrote off the existing
  namespaces.

# v1.8.2

## Feature
- pin kubecube to v1.8.2
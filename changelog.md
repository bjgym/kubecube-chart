# v1.8.3

## Feature
- replace image pin to docker hub
- configurable sso identity providers, with the private half kept in a Secret
- enable api version conversion by default
- declare the vendored subcharts, so helm lint verifies them

## BugFix
- address the project and tenant webhooks from the release namespace
- scope the resource quota webhook to platform namespaces
- honour global.namespaceOverride
- remove the unused frontend image values

# v1.8.2

## Feature
- pin kubecube to v1.8.2
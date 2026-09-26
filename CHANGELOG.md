# Changelog

## [2.0.0](https://github.com/this-oliver/homelab/compare/v1.0.0...v2.0.0) (2026-09-26)


### ⚠ BREAKING CHANGES

* sets up homelab with ansible ([#16](https://github.com/this-oliver/homelab/issues/16))

### Features

* add worker nodes ([#18](https://github.com/this-oliver/homelab/issues/18)) ([8925a67](https://github.com/this-oliver/homelab/commit/8925a67cd6813382dc21d7c9b102df14a5294f4d))
* adds homelab summary to inventory hosts ([#28](https://github.com/this-oliver/homelab/issues/28)) ([dea7fb7](https://github.com/this-oliver/homelab/commit/dea7fb74e502f45b293d120c66f0389c4ec41db4))
* ensure that preflight checks pass before critical roles ([#30](https://github.com/this-oliver/homelab/issues/30)) ([f9540dc](https://github.com/this-oliver/homelab/commit/f9540dc05bc5a63ad01c024e93cc6fa139aa3729))
* sets up homelab with ansible ([#16](https://github.com/this-oliver/homelab/issues/16)) ([5821869](https://github.com/this-oliver/homelab/commit/5821869f2256a71a14f4b069c081f915f8a76ca3))


### Bug Fixes

* assert that only ONE controller node exists ([#29](https://github.com/this-oliver/homelab/issues/29)) ([2443a5b](https://github.com/this-oliver/homelab/commit/2443a5bf9a8ad8cc7223ea2647c933da815c0f79))
* **k8s:** merges kubectl and helm roles into k8s_core role ([#26](https://github.com/this-oliver/homelab/issues/26)) ([050bef2](https://github.com/this-oliver/homelab/commit/050bef273ff5dcf84b73777bc933c84becf6094b))
* reduces playbook noise ([#24](https://github.com/this-oliver/homelab/issues/24)) ([88a9d9d](https://github.com/this-oliver/homelab/commit/88a9d9dee6aab091ddf75ad7d3b203c849d93d14))
* **reverse-proxy:** skip podman related tasks in teardown when podman is not installed ([#25](https://github.com/this-oliver/homelab/issues/25)) ([08cf191](https://github.com/this-oliver/homelab/commit/08cf1910ffb512e745b1a4e19198091ef31a0743))

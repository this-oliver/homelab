# Changelog

## [2.1.0](https://github.com/this-oliver/homelab/compare/v2.0.0...v2.1.0) (2026-09-30)


### Features

* adds observer and fixer cluster roles and service accounts ([#44](https://github.com/this-oliver/homelab/issues/44)) ([e0d68db](https://github.com/this-oliver/homelab/commit/e0d68db18654bae27b07911a9eff96e29e452d00))
* **kubernetes:** moves default persistant volume dir to homelab ([#42](https://github.com/this-oliver/homelab/issues/42)) ([d217aa1](https://github.com/this-oliver/homelab/commit/d217aa13a15d50ed37817b9ec136fc6b7a62f9e9))
* **reverse-proxy:** configure http/https ports for reverse-proxy ([#38](https://github.com/this-oliver/homelab/issues/38)) ([2c84afe](https://github.com/this-oliver/homelab/commit/2c84afed98a09b391f94ae3e043df59992131282))


### Bug Fixes

* homelab uninstall play skips worker hosts ([#33](https://github.com/this-oliver/homelab/issues/33)) ([1d40e02](https://github.com/this-oliver/homelab/commit/1d40e02939a707c1e2e8dd008f6dc60b9932011a))
* **reverse-proxy:** merge podman role into reverse_proxy role ([#39](https://github.com/this-oliver/homelab/issues/39)) ([163c85a](https://github.com/this-oliver/homelab/commit/163c85a40fe87224da5c32d19833127520f2eb4c))
* **reverse-proxy:** proxy service account lacked access to haproxy file ([#37](https://github.com/this-oliver/homelab/issues/37)) ([99f3bcb](https://github.com/this-oliver/homelab/commit/99f3bcbb1e3847887ddb43a5d19b674a65014372))
* skip pretasks in homelab when uninstalling ([#35](https://github.com/this-oliver/homelab/issues/35)) ([53be4ea](https://github.com/this-oliver/homelab/commit/53be4eaeacd612536c17bcec8f410aeb1ba26b3e))

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

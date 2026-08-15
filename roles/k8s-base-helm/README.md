# Helm

This role sets up, [helm](https://helm.sh/docs/), a package manager for Kubernetes. The role also provides a reusable task for installing helm charts.

## Usage

### main.yaml

To get started with `helm`, run the following command in your target host:

```bash
helm --help
```

### install.yaml

Extension roles call this task via `include_tasks`, passing a single `helm_release` dict:

```yaml
- name: Install {{ helm_release.name }}
  ansible.builtin.include_tasks: ../../k8s-base-helm/tasks/install.yaml
```

#### Contract

##### `helm_release` dict (passed by calling role)

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `name` | string | yes | Helm release name (e.g. `cert-manager`) |
| `namespace` | string | yes | Kubernetes namespace (e.g. `cert-manager`) |
| `chart.ref` | string | yes | Helm chart reference, `repo/name` (e.g. `jetstack/cert-manager`) |
| `chart.version` | string | yes | Helm chart version (e.g. `v1.21.0`) |
| `repo.name` | string | yes | Helm repo alias (e.g. `jetstack`) |
| `repo.url` | string | yes | Helm repo URL (e.g. `https://charts.jetstack.io`) |
| `config` | dict | no | Helm values as a dict. If omitted, defaults to `{}` and no values are used. |

The contract is enforced at runtime by an `assert` task in `install.yaml`; a missing
required key fails the run with a clear message.

Example of a calling role's `vars/main.yaml` (chart versions are pinned here, not
user-configurable):

```yaml
helm_release:
  name: cert-manager
  namespace: cert-manager
  chart:
    ref: jetstack/cert-manager
    version: "v1.21.0"
  repo:
    name: jetstack
    url: https://charts.jetstack.io
  config: "{{ lookup('ansible.builtin.file', 'values.yaml') | from_yaml }}"
```

`values` is passed straight to the `kubernetes.core.helm` module, so no values file
is ever copied to the target host. The module needs a dict, so load the content on
the controller and parse it with `from_yaml`:

- static file in the calling role's `files/`: `lookup('ansible.builtin.file', 'values.yaml') | from_yaml`
- rendered template in the calling role's `templates/`: `lookup('ansible.builtin.template', 'values.yaml.j2') | from_yaml`

##### Global vars (from `vars/defaults.yaml`)

| Var | Description |
|-----|-------------|
| `uninstall` | When `true`, uninstalls the release instead of installing |

#### Behavior

**Install** (`uninstall: false`):
1. Checks if the Helm repo already exists
2. Checks if the release already exists and matches the desired version
3. Adds the repo (if not already present)
4. Installs or upgrades the release (if not installed or version mismatch), passing `helm_release.config` inline if defined

**Uninstall** (`uninstall: true`):
1. Checks if the release exists
2. Uninstalls the release via Helm

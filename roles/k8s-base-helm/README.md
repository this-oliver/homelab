# Helm

This role sets up, [helm](https://helm.sh/docs/), a package manager for Kubernetes. The role also provides a reusable task for installing helm charts.

## Usage

### main.yaml

To get started with `helm`, run the following command in your target host:

```bash
helm --help
```

### install.yaml

Extension roles call this task via `include_tasks`:

```yaml
- name: Install {{ release_name }}
  ansible.builtin.include_tasks: ../../k8s-base-helm-chart/tasks/main.yaml
  vars:
    chart_ref: "{{ chart_ref }}"
    chart_version: "{{ chart_version }}"
    release_name: "{{ release_name }}"
    release_namespace: "{{ release_namespace }}"
    repo_name: "{{ repo_name }}"
    repo_url: "{{ repo_url }}"
    values_file: values.yaml  # optional, relative to calling role's files/ directory
```

#### Contract

##### Required vars (passed by calling role)

| Var | Type | Description |
|-----|------|-------------|
| `chart_ref` | string | Helm chart reference (e.g. `jetstack/cert-manager`) |
| `chart_version` | string | Helm chart version (e.g. `v1.21.0`) |
| `release_name` | string | Helm release name (e.g. `cert-manager`) |
| `release_namespace` | string | Kubernetes namespace (e.g. `cert-manager`) |
| `repo_name` | string | Helm repo alias (e.g. `cert-manager`) |
| `repo_url` | string | Helm repo URL (e.g. `https://charts.jetstack.io`) |

##### Optional vars

| Var | Type | Description |
|-----|------|-------------|
| `values_file` | string | Path to Helm values file, relative to the calling role's `files/` directory. If omitted, no values file is used. |

##### Global vars (from `vars/main.yaml`)

| Var | Description |
|-----|-------------|
| `uninstall` | When `true`, uninstalls the release instead of installing |

#### Behavior

**Install** (`uninstall: false`):
1. Checks if the Helm repo already exists
2. Checks if the release already exists and matches the desired version
3. Copies the values file to `/tmp/{{ release_name }}-values.yaml` (if `values_file` is defined)
4. Adds the repo (if not already present)
5. Installs or upgrades the release (if not installed or version mismatch)
6. Cleans up the values file from `/tmp/`

**Uninstall** (`uninstall: true`):
1. Checks if the release exists
2. Uninstalls the release via Helm

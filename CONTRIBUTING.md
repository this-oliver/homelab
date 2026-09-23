# Contributing

Thanks for contributing! This guide covers the conventions to keep the project consistent. Reading time ~5 minutes.

## Environment setup

Install the dev dependencies and verify the playbook parses:

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

# validate the playbook syntax without touching a host
ansible-playbook -i inventory/main.yaml playbooks/homelab.yaml --syntax-check
ansible-playbook -i inventory/main.yaml playbooks/homelab.yaml --list-tasks
```

There is no test suite that mutates real infrastructure — check your changes against `--syntax-check` and `--list-tasks`, and review the rendered task graph when you touch ordering.

## Project layout

```
playbooks/homelab.yaml   # the single entry point: five plays, in dependency order
roles/<name>/            # each component is an Ansible role
  tasks/main.yaml        #   dispatch: setup vs teardown based on `uninstall`
  tasks/setup.yaml       #   install logic
  tasks/teardown.yaml    #   uninstall logic
  vars/main.yaml         #   role defaults
  templates/             #   rendered configs (values.yaml, haproxy.cfg, ...)
tasks/                   # shared, reusable task libraries
config.yaml              # user-facing, non-secret configuration
inventory/               # which hosts get which services
docs/                    # documentation (see below)
```

## Role conventions

Every role must follow the same structure:

1. **Dispatch in `main.yaml`.** Gate on the global `uninstall` flag:

   ```yaml
   - name: Install Foo
     ansible.builtin.include_tasks:
       file: setup.yaml
     when: not (uninstall | bool)

   - name: Uninstall Foo
     ansible.builtin.include_tasks:
       file: teardown.yaml
     when: uninstall | bool
   ```

2. **Keep logic in `setup.yaml` / `teardown.yaml`.** `main.yaml` stays a thin dispatcher.
3. **Run preflight checks first.** Roles that are not strictly install-once should `include_tasks: ../../../tasks/preflight.yaml` at the top of setup so credential/OS mistakes fail fast (see `k8s-extension-*` roles for examples).
4. **Share Helm work.** Anything installed via Helm must use `tasks/helm.yaml` and pass a `helm_release` variable matching the contract validated there. Do not hand-roll `kubernetes.core.helm` calls.
5. **Put user-tweakable values in `config.yaml`.** Role defaults in `vars/main.yaml` should be internal wiring (port numbers, addon lists, chart versions), not knobs the user cares about.
6. **Never hard-code secrets.** Credentials must come from `homelab.admin.*` / `homelab.domain.*`, which `config.yaml` reads from the environment.

## Naming and style

- Variables are `snake_case`; role vars use the role as a prefix (`reverse_proxy.*`, `*_helm_release`).
- Task names are imperative and capitalized ("Install Helm"), matching existing tasks.
- Keep each task file focused; extract reusable steps into `tasks/` when something is used from more than one role.
- Preserve the existing commenting style in templates (`{# ... #}`) when adding conditional rendering.

## Tags

- Every play and role in the playbook is tagged with its layer: `base`, `kubernetes`, `networking`, `monitor`, `reverse-proxy`, plus component tags (`kubectl`, `helm`, `traefik`, `headlamp`, `dashboard`, `trivy`).
- Tag your additions so `make kubernetes`, `make monitor`, etc. keep working. Confirm with:

  ```bash
  ansible-playbook -i inventory/main.yaml playbooks/homelab.yaml --list-tags
  ```

## Commits and PRs

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) as enforced by commitlint in CI. Allowed types are `feat`, `fix`, `chore`, `docs` (see `.github/config/commitlint.yaml`):

```bash
feat: adds X
fix: corrects Y
docs: updates Z
chore(dep): bumps W
```

- PRs must target `main`.
- CI checks the PR title and all commits with commitlint, and Dependabot keeps dependencies current.
- Keep PRs focused on one change so the release-please flow can ship them independently.

## Documentation conventions

Documentation follows a **what / why / how** structure and prefers diagrams over prose for relationships:

- **`README.md`** — high-level: what the project is, how it works (architecture diagram), and a quickstart. No deep reference material.
- **`docs/intro.md`** — getting started and usage in depth, with full configuration and environment variable references.
- **`docs/architecture.md`** — how the layers interoperate, traffic flow, install/uninstall lifecycle, security model.
- **Every role has a `README.md`** using the standard template (see below).

Use **Mermaid** diagrams for anything with more than two relationships (role ordering, request flow). Keep diagrams small and readable; don't diagram trivial linear task lists.

When you add a new role, create its README from this template and add a matching row to the [docs index](docs/README.md) and the [architecture role index](docs/architecture.md#role-index):

```markdown
# Role: <name>

## What

One or two sentences: what this role installs or configures.

## Why

The problem this role solves and where it sits in the stack
(which roles depend on it, which it depends on).

## How

A short walkthrough of the main tasks, with a small Mermaid diagram
if the flow has branches (Raspberry Pi handling, firewall lockdown, ...).

## Variables

| Variable | Default | Description |
| --- | --- | --- |

## Dependencies

- Roles/tasks this role runs (e.g. included roles, shared task libraries).

## Tags

The `--tags` value(s) that invoke this role.

## Uninstall

What uninstalling this role tears down (and whether it has a teardown at all).
```
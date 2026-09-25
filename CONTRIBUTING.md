# Contributing

Thanks for contributing! This guide covers the conventions to keep the project consistent. Reading time ~5 minutes.

## Environment setup

Install the dev dependencies and verify the playbooks parse. All Ansible code lives under `ansible/`, so inventory and playbook paths are always relative to the repo root:

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

# validate the playbook syntax without touching a host
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --syntax-check
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml --syntax-check

# review the rendered task graph per layer before running anything
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --list-tasks
ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml --tags uninstall --list-tasks
```

There is no test suite that mutates real infrastructure — check your changes against `--syntax-check` and `--list-tasks`, and review the rendered task graph when you touch ordering.

## Project layout

```
ansible/                            # all Ansible code lives here
  homelab.yaml                 #     the install playbook, and the entry point: five plays,
                                #       in dependency order
  homelab_uninstall.yaml       #     the uninstall playbook: one play, reverse dependency order
  config.yaml                  #     user-facing, non-secret configuration (secrets from env)
  inventory/                   #     which hosts get which services
  roles/<name>/                #     each component is an Ansible role
    tasks/main.yaml            #       dispatch: setup vs teardown based on `uninstall`
    tasks/setup.yaml           #       install logic
    tasks/teardown.yaml        #       uninstall logic
    vars/main.yaml             #       role defaults
    templates/                 #       rendered configs (values.yaml, haproxy.cfg, ...)
    README.md                  #       what / why / how documentation
  tasks/                       #   shared, reusable task libraries
docs/                          # documentation (see below)
```

The playbooks reference roles by name (`include_role: name: base`), resolved from `ansible/roles/` because that is the playbook's own `roles/` directory.

Two rules keep the runs quiet:

1. **No playbook dispatches on the `uninstall` flag.** Which playbook you want is the whole point of having two of them: `homelab.yaml` installs, `homelab_uninstall.yaml` tears down. `homelab_uninstall.yaml` sets `uninstall: true` as a play var, and neither playbook gates its own tasks on the flag, so a run only executes the work you asked for. Opt a teardown out of the default run by leaving the `uninstall` tag off the task, not by adding a `when`. `homelab.yaml` fails fast on `-e uninstall=true` (the first task of the first play, tagged `always` so a tag filter cannot skip it) — keep that guard, and keep the playbooks independent, so neither one can be made to run the other's direction.
2. **Layer selection is tags, not flags.** `--tags base`, `--tags networking`, `--tags uninstall` etc. This is why a tag filter is safe at all: an untagged task would be *skipped* by any filter, so tag every play, `pre_tasks` entry, `include_role` and `apply` block.

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

   The flag comes from a play var, so a role can rely on it being defined. Do not add task-level `when: uninstall` conditions to the playbooks — the play var already decides which playbook runs.

2. **Keep logic in `setup.yaml` / `teardown.yaml`.** `main.yaml` stays a thin dispatcher.
3. **Run preflight checks first.** Roles that are not strictly install-once should `include_tasks: ../../../tasks/preflight.yaml` at the top of setup so credential/OS mistakes fail fast (see `k8s_extension_*` roles for examples).
4. **Share Helm work.** Anything installed via Helm must use `tasks/helm.yaml` and pass a `helm_release` variable matching the contract validated there. Do not hand-roll `kubernetes.core.helm` calls.
5. **Put user-tweakable values in `config.yaml`.** Role defaults in `vars/main.yaml` should be internal wiring (port numbers, addon lists, chart versions), not knobs the user cares about.
6. **Never hard-code secrets.** Credentials must come from `homelab.admin.*` / `homelab.domain.*`, which `config.yaml` reads from the environment.

## Naming and style

- Variables are `snake_case`; role vars use the role as a prefix (`reverse_proxy.*`, `*_helm_release`).
- Task names are imperative and capitalized ("Install Helm"), matching existing tasks.
- Keep each task file focused; extract reusable steps into `tasks/` when something is used from more than one role.
- Preserve the existing commenting style in templates (`{# ... #}`) when adding conditional rendering.

## Tags

- Every play and role is tagged with its layer: `base`, `kubernetes`, `networking`, `monitor`, `reverse_proxy`, plus component tags (`kubectl`, `helm`, `traefik`, `headlamp`, `dashboard`, `trivy`). `ansible/homelab.yaml` and `ansible/homelab_uninstall.yaml` share that vocabulary, so `make kubernetes` and `make uninstall-kubernetes` mean the same layer.
- In the uninstall playbook the `uninstall` tag marks the default teardown. A role without that tag is opt-in, reached only by passing its own layer tag.
- Tag your additions so `make kubernetes`, `make monitor`, etc. keep working. Every `include_role` needs the same tag list on `tags:` and on `apply.tags:` — the first gates whether the role is included, the second stamps the tag onto the role's own tasks.
- **`apply` goes inside the include's arguments**, at the same indent as `name:`/`file:`, not as a sibling of the module key. It is an argument of `include_role`/`include_tasks` (ansible reads it from `task.args`), and as a sibling it is a hard parse error: `conflicting action statements: ansible.builtin.include_role, apply`.
- Forget `apply` and nothing warns you: the role is still included, but a tagged run silently drops every task inside it, so `make kubernetes` appears to succeed and changes nothing. `--list-tasks` will not catch this — it does not expand roles. Check the tag vocabulary with:

  ```bash
  ansible-playbook -i ansible/inventory/main.yaml ansible/homelab.yaml --list-tags
  ansible-playbook -i ansible/inventory/main.yaml ansible/homelab_uninstall.yaml --list-tags
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

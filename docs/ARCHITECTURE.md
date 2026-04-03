# Architecture

This document explains how the LAF is structured and how the different pieces fit together.

<br>

# Overview

```
laf/
├── collections/        # Ansible Galaxy collection requirements
├── docs/               # Documentation
├── import/             # Import files (e.g. decommission.ini)
├── playbooks/          # All playbooks, organized by category
│   ├── _automation/    # Scheduled / pipeline playbooks
│   ├── agents/         # Agent install/remove (Datadog, Elastic, Splunk, etc.)
│   ├── managed_services/ # Service management (IdM, Vault, DNS, Podman, etc.)
│   └── tools/          # Day-to-day admin tools (audits, maintenance, lifecycle, security)
└── roles/              # All roles
    ├── common/         # Shared vars (loaded by every playbook)
    ├── automation/     # Client repo management logic
    ├── tools/          # Admin tools logic
    └── <service>/      # One role per agent or service
```

<br>

# How a playbook works

Every playbook in the LAF follows the same pattern:

1. A **playbook** sets a boolean variable (`INSTALL_X: true`, `EXTEND_VOLUME: true`, etc.)
2. It calls the **`common`** role first (loads shared credentials and service URLs)
3. Then it calls the **target role**
4. The role's **`tasks/main.yaml`** acts as the entrypoint — it reads the variable and includes the right sub-task

```yaml
# playbook
vars:
  INSTALL_DATADOG_AGENT: true
roles:
  - common
  - datadog_agent
```

```yaml
# roles/datadog_agent/tasks/main.yaml
- name: Include installation tasks
  ansible.builtin.include_tasks: installation/main.yaml
  when: INSTALL_DATADOG_AGENT | default(false)
```

This approach avoids tags and makes playbooks simpler to run from both CLI and Tower/AAP.

<br>

# Role structure

Each role follows the same layout:

```
roles/<role_name>/
├── defaults/
│   └── main.yaml       # Default variables (overridable)
├── tasks/
│   ├── main.yaml       # Entrypoint — routes to the right sub-task
│   ├── <action>/       # One folder per action (installation, remove, etc.)
│   └── utils/          # Reusable utility tasks (clone repo, create/clean workdir, etc.)
├── templates/          # Jinja2 templates
├── files/              # Static files
└── README.md
```

<br>

# Variable conventions

| Prefix | Usage |
|---|---|
| `__var_name` | Immutable — defined in external files (`defaults/`, `vars/`, `common/`) |
| `var_name` | Playbook-level variable |
| `var_name_prompted` | Comes from a `vars_prompt` in the playbook |

<br>

# Common role

The `common` role is a shared dependency. It loads credentials and connection details for all internal services (Centreon, Tower, GitLab, Satellite, IPA, vCenter, PMP, etc.).

Every playbook that interacts with those services must list `common` before the target role:

```yaml
roles:
  - common
  - your_role
```

<br>

# Client repositories

Client-specific configuration (inventories, group_vars, agent configs) lives in dedicated Git repos under:
`https://gitlab.rh.ebrc.local/ict-las/clients/<client_id>`

The `_automation/` playbooks are responsible for keeping those repos in sync with Satellite and AAP automatically.
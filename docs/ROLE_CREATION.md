# Creating a New Role

This document explains how to add a new role to the LAF, following the project conventions.

<br>

# Init the role

From the LAF root:

```bash
ansible-galaxy role init roles/<role_name>
```

Then clean up what you don't need (tests, meta, etc.). Keep only what's relevant.

<br>

# Recommended structure

```
roles/<role_name>/
├── defaults/
│   └── main.yaml           # Default variables
├── tasks/
│   ├── main.yaml           # Entrypoint
│   ├── <action>/
│   │   └── main.yaml       # Sub-tasks for a specific action
│   └── utils/
│       ├── create_working_dir.yaml
│       └── clean_working_dir.yaml
├── templates/              # Jinja2 templates (.j2)
├── files/                  # Static files
└── README.md
```

<br>

# Entrypoint pattern

The `tasks/main.yaml` must use boolean variables to route to the right sub-task. No tags.

```yaml
# roles/<role_name>/tasks/main.yaml

---
- name: Include installation tasks
  ansible.builtin.include_tasks: installation/main.yaml
  when: INSTALL_MY_THING | default(false)

- name: Include remove tasks
  ansible.builtin.include_tasks: remove/main.yaml
  when: REMOVE_MY_THING | default(false)
```

<br>

# Playbook

Create a matching playbook in the right folder under `playbooks/`. Set the variable and call the role:

```yaml
---
- name: Playbook to install <thing>
  hosts: all
  become: true

  # Usage
  # ansible-playbook playbooks/<category>/<role_name>/installation.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

  vars:
    INSTALL_MY_THING: true

  roles:
    - common
    - <role_name>
```

<br>

# Variable naming

| Prefix | Usage |
|---|---|
| `__var_name` | Immutable — defined in `defaults/` or `vars/` |
| `var_name` | Playbook-level variable |
| `var_name_prompted` | From `vars_prompt` |

<br>

# Task conventions

- Always use FQCN (`ansible.builtin.template`, not `template`)
- Always put `become: true` at the **task level**, never at the play level
- Task names must be explicit and describe what's actually happening

```yaml
- name: Deploy the repo configuration file
  ansible.builtin.template:
    src: myservice.repo.j2
    dest: /etc/yum.repos.d/myservice.repo
    owner: root
    group: root
    mode: '0644'
  become: true
```

<br>

# Handler naming

Use underscores only, all lowercase:

```yaml
# Good
- name: systemd_reload_daemon
- name: restart_myservice

# Bad
- name: Restart My Service
- name: restart-myservice
```

<br>

# README

Every role must have a `README.md`. Keep it short:
- What the role does (2-3 lines)
- How it works
- Key variables (table)
- Usage examples

<br>

# Checklist before merging

- [ ] Role initialized with `ansible-galaxy role init`
- [ ] Unused folders removed
- [ ] `tasks/main.yaml` uses the entrypoint pattern
- [ ] All tasks use FQCN
- [ ] `become` is at task level only
- [ ] Variables follow the naming convention
- [ ] A playbook exists in the right folder
- [ ] `README.md` is filled in
- [ ] Secrets are encrypted with Ansible Vault (see `docs/VAULT.md`)
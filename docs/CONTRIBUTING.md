# Contributing

This document explains how to contribute to the LAF. Read it before making any changes.

<br>

# Founding principles

The LAF is a centralized tool to manage our Linux infrastructure from a single structured point. It has to be versatile and cover different use cases:

- Playbooks for team use (CLI or Tower/AAP)
- Playbooks delegated to another team (e.g. Move2Left)
- Playbooks for automation (e.g. self-refreshing inventories)
- Playbooks for workflow automation (e.g. Hashicorp + SPM)

Keep this in mind when you add something. If it doesn't fit any of these categories, question whether it belongs here.

<br>

# Before you start

- Read `docs/ARCHITECTURE.md` to understand how the project is structured
- Read `docs/ROLE_CREATION.md` if you're adding a new role
- Read `docs/VAULT.md` if you need to handle secrets
- Read `docs/GIT_CHEATSHEET.md` if you're not comfortable with Git

<br>

# Project structure

We use Ansible roles for everything — modularity, reusability, versioning. No tasks directly in playbooks except for very simple standalone cases (like audit playbooks that don't fit a role).

We also have custom Python collections for things Ansible can't do natively:
[LAF Collections](https://gitlab.rh.ebrc.local/ict-las/laf-collections)

<br>

# Nomenclature

## Files

Use **underscores** between words. No dashes, no CamelCase.

```
✅ add_user_to_groups.yaml
✅ generate_keys_list.yaml

❌ my-super-tasks-file.yaml
❌ MySuperTasksFiles.yaml
❌ task1.yaml
```

`main.yaml` is always the entrypoint filename — that's mandatory.

## Variables

```yaml
__my_var_name        # Immutable — defined in defaults/ or vars/ (never overwrite at runtime)
my_var_name          # Playbook-level variable
my_var_name_prompted # Comes from vars_prompt
```

> **Note:** If you use a `vars_prompt` variable, it gets re-evaluated at each task — don't try to modify it mid-play.

## Tags

Lowercase, dashes only:

```
✅ install
✅ push-config

❌ tag1
❌ MyTag
❌ My_Tag
```

## Handlers

Underscores only, all lowercase. Never use dashes in handler names (can trigger Python errors):

```
✅ systemd_reload_daemon
✅ yum_clean_all

❌ My Super Handler
❌ my-handler
```

<br>

# Task conventions

Always use the FQCN (Fully Qualified Collection Name), put `become` at the task level, and write explicit names:

```yaml
- name: Deploy the repo configuration file
  ansible.builtin.template:
    src: myservice.repo.j2
    dest: /etc/yum.repos.d/myservice.repo
    owner: root
    group: root
    mode: '0644'
  become: true
  notify:
    - systemd_reload_daemon
```

## Handler example

```yaml
- name: systemd_reload_daemon
  ansible.builtin.systemd:
    daemon_reload: true
  become: true
```

<br>

# Playbook conventions

- Never put `become: true` at the play level — always at the task level
- Always use roles (no bare tasks in playbooks, except for simple standalone audits)
- Always add a `# Usage` comment block at the top

```yaml
---
- name: Playbook to install <thing>
  hosts: all
  become: true

  # Usage
  # ansible-playbook playbooks/<category>/<role>/installation.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

  vars:
    INSTALL_MY_THING: true

  roles:
    - common
    - my_role
```

<br>

# Init a new role

```bash
ansible-galaxy role init roles/<role_name>
```

Then clean up unused folders and follow the structure in `docs/ROLE_CREATION.md`.

<br>

# Checklist before pushing

- [ ] File names use underscores
- [ ] Variables follow the naming convention
- [ ] Tasks use FQCN
- [ ] `become` is at task level only
- [ ] Secrets are vault-encrypted
- [ ] A `README.md` exists for any new role
- [ ] A `# Usage` comment is in every new playbook
- [ ] You've tested the playbook at least once
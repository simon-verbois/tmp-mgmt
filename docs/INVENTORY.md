# Inventories

This document explains how inventories are structured and used in the LAF.

<br>

# Two ways to pass a target

**Ad-hoc (single server or small list)**

```bash
ansible-playbook playbooks/... -i sv-xxxxlvuxx.rh.xxxx.local,
# Note the trailing comma — it tells Ansible this is an inline inventory
```

**Inventory file (client-based)**

```bash
ansible-playbook playbooks/... -i clients/XXXX/hosts.ini
ansible-playbook playbooks/... -i clients/XXXX/hosts.ini -l sv-xxxxlvuxx.rh.xxxx.local
```

<br>

# Client repositories

Each client has its own Git repository at:
`https://gitlab.rh.ebrc.local/ict-las/clients/<client_id>`

The repo contains:
- Inventory files (`.ini`)
- `group_vars/` — client-specific variables and encrypted secrets

```
clients/<client_id>/
├── hosts.ini               # General inventory
├── elastic-agent.ini       # Agent-specific inventory (if applicable)
├── dns.ini                 # DNS-specific inventory (if applicable)
└── group_vars/
    ├── all/
    │   └── main.yaml       # Vars applied to all hosts
    └── <group>/
        └── main.yaml       # Vars applied to a specific group
```

<br>

# Inventory file format

```ini
[group_name]
sv-xxxxlvuxx.rh.xxxx.local
sv-xxxxlvuxx.rh.xxxx.local

[another_group]
sv-xxxxlvuxx.rh.xxxx.local

[another_group:children]
group_name
```

<br>

# Example — Elastic Agent inventory

Servers move from `elastic_agent_dynamic` (pending install) to `elastic_agent` (installed) once done:

```ini
[elastic_agent_dynamic]
sv-1365lvu50.rh.jao.local

[elastic_agent]
sv-1365lvu74.rh.jao.local
sv-1365lvu75.rh.jao.local

[elastic_agent:children]
elastic_agent_dynamic
```

<br>

# Example — DNS inventory

The group name sets the `dns_scope` variable used by the `named` role:

```ini
[internal]
dns-int-01.rh.xxxx.local
dns-int-02.rh.xxxx.local

[public]
dns-pub-01.rh.xxxx.local
```

```bash
# Target only internal servers
ansible-playbook playbooks/managed_services/named/push_config.yaml -i clients/2000/dns.ini -l internal
```

<br>

# Decommission inventory

For server decommissioning, use the import file:

```bash
cp import/decommission.ini.sample import/decommission.ini
vim import/decommission.ini
ansible-playbook playbooks/tools/lifecycle/server_decommission.yaml -i import/decommission.ini
```

<br>

# Automation

The `_automation/` playbooks keep client inventories up to date automatically. They compare GitLab repos with Satellite locations and sync everything to AAP. You don't need to manage this manually.
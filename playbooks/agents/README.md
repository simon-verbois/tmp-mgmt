# Agents

Playbooks to install, upgrade, or remove monitoring and security agents on Linux servers.

Each agent has its own subdirectory with an `installation.yaml` and a `remove.yaml` (and sometimes an `upgrade.yaml`).

## Available agents

- **azure_arc** — Connects servers to Azure Arc for hybrid cloud management
- **datadog_agent** — Installs the Datadog monitoring agent
- **elastic_agent** — Installs the Elastic Agent for log and metric collection
- **nnt_changetracker** — Installs the NNT Change Tracker agent for integrity monitoring
- **splunk_forwarder** — Installs the Splunk Universal Forwarder

## Usage

Most agents follow the same pattern:

```bash
# Install
ansible-playbook playbooks/agents/<agent>/installation.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Remove
ansible-playbook playbooks/agents/<agent>/remove.yaml -i sv-xxxxlvuxx.rh.xxxx.local,
```

For agents that require client-specific configuration (Datadog, Elastic, Splunk), you need to use the client inventory and have the `group_vars` file set up beforehand.

```bash
ansible-playbook playbooks/agents/<agent>/installation.yaml -i clients/XXXX/hosts.ini -l sv-xxxxlvuxx.rh.xxxx.local
```

## Role docs

See `roles/<agent_name>/README.md` for variables and requirements.
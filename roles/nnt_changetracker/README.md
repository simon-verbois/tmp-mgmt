# nnt_changetracker

Installs, removes, and upgrades the NNT Change Tracker Gen7 agent on RHEL-based servers.

## How it works

Sets up the internal Yum repo, installs the agent package, configures it using the NNT configuration script, and registers it against the NNT Hub. The agent runs as a systemd service.

On removal, it stops the service and uninstalls the package. On upgrade, it reinstalls to the latest available version.

## Requirements

- Access to the internal Yum repo (`yumrepos.csv.local`)
- The NNT Hub must be reachable from the target server

## Variables

Set in `defaults/main.yaml`. The important ones:

| Variable | Description |
|---|---|
| `__nnt_hub_host` | NNT Hub API URL |
| `__nnt_agent_thumbprint` | Hub certificate thumbprint |
| `__nnt_agent_user` | Agent authentication user |
| `__nnt_agent_pwd` | Agent password (vault encrypted) |

## Usage

```bash
# Install
ansible-playbook playbooks/agents/nnt_changetracker/installation.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Remove
ansible-playbook playbooks/agents/nnt_changetracker/remove.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Upgrade
ansible-playbook playbooks/agents/nnt_changetracker/upgrade.yaml -i sv-xxxxlvuxx.rh.xxxx.local,
```
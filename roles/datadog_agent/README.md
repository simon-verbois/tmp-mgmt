# datadog_agent

Installs and removes the Datadog Agent on RHEL-based servers.

## How it works

Sets up the Datadog Yum repository, installs the agent package, and ensures the service is running. Each step is tracked and a summary is printed at the end of the run — even if something fails.

On removal, it stops the service and uninstalls the package.

## Requirements

- The target needs access to `yum.datadoghq.com` (directly or via proxy)
- Client `group_vars` must define the variables below

## Variables

Set in the client `group_vars` file:

| Variable | Description |
|---|---|
| `__datadog_repo_baseurl` | Base URL of the Datadog Yum repo |
| `__datadog_repo_gpgkey` | List of GPG key URLs |
| `__datadog_repo_proxy` | Proxy URL (optional) |
| `__datadog_package` | Package name (default: `datadog-agent`) |
| `__datadog_service` | Service name (default: `datadog-agent`) |

## Usage

```bash
# Install
ansible-playbook playbooks/agents/datadog_agent/installation.yaml -i clients/XXXX/hosts.ini -l sv-xxxxlvuxx.rh.xxxx.local

# Remove
ansible-playbook playbooks/agents/datadog_agent/remove.yaml -i clients/XXXX/hosts.ini -l sv-xxxxlvuxx.rh.xxxx.local
```
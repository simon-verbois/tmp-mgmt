# elastic_agent

Installs and removes the Elastic Agent on RHEL-based servers.

## How it works

The agent is deployed via a tarball (not a package manager). The role downloads the tarball to the controller, syncs it to the target server using rsync, then installs and registers the agent against the Fleet server using the enrollment token.

Before installing, it runs a series of checks: is the agent already installed? does the service exist? is the proxy reachable? is there enough storage?

On removal, it stops and uninstalls the agent.

## Requirements

- A `elastic-agent.ini` inventory file in the client directory
- A `group_vars/elastic_agent/main.yaml` file with the variables below

## Variables

Set in the client `group_vars` file:

| Variable | Description |
|---|---|
| `__elastic_console_url` | Fleet server URL |
| `__elastic_proxy_url` | Proxy URL |
| `__elastic_enrollment_token` | Enrollment token (vault encrypted) |

## Usage

```bash
# Install
ansible-playbook playbooks/agents/elastic_agent/installation.yaml -i clients/XXXX/elastic-agent.ini -l elastic_agent_dynamic

# Remove
ansible-playbook playbooks/agents/elastic_agent/remove.yaml -i clients/XXXX/elastic-agent.ini -l elastic_agent
```

## Encrypt the token

```bash
echo -n 'my_token' | ansible-vault encrypt_string --encrypt-vault-id client_data
```
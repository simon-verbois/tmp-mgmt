# splunk_forwarder

Installs and removes the Splunk Forwarder on RHEL-based servers.

## How it works

Sets up the internal Yum repo, installs the `splunkforwarder` package, configures the deployment server and user credentials using templates, and starts the service. The forwarder runs under the `splunk` user created by the RPM.

On removal, it stops the service and removes the package.

## Requirements

- Access to the internal Yum repo (`yumrepos.csv.local`)
- The client inventory and `group_vars` must be set up (needed for `client_id`)

## Variables

| Variable | Description |
|---|---|
| `__splunkfw_repo_url` | Internal repo URL |
| `__splunkfw_default_server_ip` | Deployment server IP and port |

## Usage

```bash
# Install
ansible-playbook playbooks/agents/splunk_forwarder/installation.yaml -i clients/XXXX/hosts.ini -l sv-xxxxlvuxx.rh.xxxx.local

# Remove
ansible-playbook playbooks/agents/splunk_forwarder/remove.yaml -i clients/XXXX/hosts.ini -l sv-xxxxlvuxx.rh.xxxx.local
```
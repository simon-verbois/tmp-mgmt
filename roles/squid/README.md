# squid

Installs Squid and pushes its configuration from a Git repository.

## How it works

Two operations, driven by the variable set in the playbook:

- **`SQUID_INSTALLATION`** — Installs the Squid package and enables the service
- **`SQUID_PUSH_CONFIG`** — Clones the client Git repo onto the controller, syncs the config files to the server, and reloads Squid

Runs with `serial: 1` so servers are updated one at a time.

## Usage

```bash
# Install
ansible-playbook playbooks/managed_services/squid/installation.yml -i sv-xxxxlvuxx.rh.xxxx.local,

# Push config
ansible-playbook playbooks/managed_services/squid/push_config.yml -i clients/XXXX/squid.ini
```
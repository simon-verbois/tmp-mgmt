# elastic_agent

Installs and removes the Elastic Agent on RHEL-based servers.

## How it works

The agent is deployed via a tarball (not a package manager). The role downloads the tarball from the internal depot to the Ansible controller, syncs it to the target server using rsync, then installs and registers the agent against the Fleet server using the enrollment token.

### Installation flow

1. **Pre-checks** — skips the host if the agent is already installed or the service already exists; verifies proxy connectivity to the Fleet URL if a proxy is defined
2. **Storage provisioning** — ensures a dedicated LVM volume is mounted on `__elastic_mount_path` (three cases handled automatically):
   - `vg_data` exists with enough free space → creates LV directly
   - `vg_data` exists but lacks space → extends the backing vCenter disk, resizes the PV, then creates LV
   - `vg_data` absent → adds a new vCenter disk, creates PV/VG, then creates LV
3. **Space validation** — asserts sufficient space on the mount point and temp directory based on the tarball size
4. **Installation** — unpacks the tarball and runs `elastic-agent install` with Fleet enrollment
5. **Cleanup** — removes the working directory on the controller and the temp directory on the target

### Removal flow

Stops and uninstalls the agent, removes the package, unmounts the LV and removes it, and deletes remaining files.

## Requirements

- A `elastic-agent.ini` inventory file in the client directory
- A `group_vars/elastic_agent/main.yaml` file with the client-specific variables below
- vCenter credentials available (for storage provisioning via the `tools/tasks/server_extend_lvm_volume` role)

## Variables

### Set in client `group_vars`

| Variable | Description |
|---|---|
| `__elastic_console_url` | Fleet server URL |
| `__elastic_enrollment_token` | Enrollment token (vault encrypted) |
| `__elastic_proxy_url` | Proxy URL (optional) |

### Defaults (overridable)

| Variable | Default | Description |
|---|---|---|
| `__elastic_agent_tarball` | `elastic-agent-9.3.0-linux-x86_64.tar.gz` | Tarball filename on the depot |
| `__internal_depot_url` | `http://yumrepos.csv.local/depot` | Internal depot base URL |
| `__tmp_elastic_directory` | `/opt/elastic_agent_tmp` | Temp directory on the target |
| `__elastic_mount_path` | `/opt/Elastic` | Mount point for the dedicated LV |
| `__elastic_vg_name` | `vg_data` | Target VG name |
| `__elastic_lv_name` | `lv_opt_elastic` | LV name to create |
| `__elastic_lv_size_gb` | `5` | LV size (GB) |
| `__elastic_new_disk_size_gb` | `10` | New vCenter disk size (GB) if VG is absent |
| `__elastic_install_space_multiplier` | `2.3` | Free space multiplier required on mount point |
| `__elastic_tmp_space_multiplier` | `1.5` | Free space multiplier required in temp directory |

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

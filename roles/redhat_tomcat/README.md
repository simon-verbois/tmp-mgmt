# redhat_tomcat

Installs, configures, and removes Apache Tomcat on RHEL-based servers.

## How it works

The role uses the standard LAF entrypoint pattern — `tasks/main.yaml` includes the right task file based on which variable is set in the playbook (`INSTALL_TOMCAT`, `CONFIGURE_TOMCAT`, or `REMOVE_TOMCAT`).

The role manages Java installation, the Tomcat package, and the systemd service. It supports custom service names, users, and directories for multi-instance setups.

## Variables

Set in `defaults/main.yaml` or override in `group_vars`:

| Variable | Default | Description |
|---|---|---|
| `__java_version` | `1.8.0` | Java version to install |
| `__tomcat_version` | `9.0.87` | Tomcat version |
| `__tomcat_service` | `tomcat_pfin.service` | Systemd service name |
| `__tomcat_user` | `quarted_pfin` | Service account user |
| `__tomcat_group` | `quarted_pfin` | Service account group |
| `__tomcat_root_dir` | `/opt/tomcat_pfin` | Installation directory |

## Usage

```bash
# Install
ansible-playbook playbooks/managed_services/redhat_tomcat/install.yml -i sv-xxxxlvuxx.rh.xxxx.local,

# Configure
ansible-playbook playbooks/managed_services/redhat_tomcat/configure.yml -i sv-xxxxlvuxx.rh.xxxx.local,

# Remove
ansible-playbook playbooks/managed_services/redhat_tomcat/remove.yml -i sv-xxxxlvuxx.rh.xxxx.local,
```
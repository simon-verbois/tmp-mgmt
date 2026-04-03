# redhat_idm

Manages users, groups, and policies on Red Hat IdM (FreeIPA) clusters. Generates a full XLSX report per IPA instance.

## How it works

The role is driven by variables passed at runtime. The `tasks/main.yaml` entrypoint routes to one of three modules based on what's enabled:

| Variable | Module | Description |
|---|---|---|
| `REDHAT_IDM_INIT: true` | `tasks/setup/` | Initial cluster provisioning (groups, policies, rules, users) |
| `REDHAT_IDM_MANAGING: true` | `tasks/manage/` | User lifecycle operations |
| `REDHAT_IDM_REPORTING: true` | `tasks/reporting/` | XLSX report generation |

All manage and reporting operations run against `localhost` (API calls to IdM via Kerberos), not directly against the servers. Multiple IdM instances can be targeted at once via `__clients_id_prompted`.

---

## User management

```bash
# Create user
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_creation=true __clients_id_prompted='XXXX' \
      __username='jdoe' __user_firstname='John' __user_lastname='Doe' \
      __user_mail='jdoe@example.com' __user_groups='group1 group2'"

# Create service account
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_creation=true __clients_id_prompted='XXXX' \
      __username='svc-myapp' __user_firstname='Service' __user_lastname='MyApp' \
      __user_mail='linux@example.com' __user_groups='monitoring' \
      __user_service_account=true"

# Delete (multiple users separated by ;)
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_deletion=true __clients_id_prompted='XXXX' __username='jdoe;jsmith'"

# Reset password
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_password_reset=true __clients_id_prompted='XXXX' __username='jdoe'"

# Disable / Enable
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_disabling=true __clients_id_prompted='XXXX' __username='jdoe'"
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_enabling=true __clients_id_prompted='XXXX' __username='jdoe'"

# Add / Remove from group
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_add_group=true __clients_id_prompted='XXXX' __username='jdoe' __user_groups='ict-linux'"
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_remove_group=true __clients_id_prompted='XXXX' __username='jdoe' __user_groups='ict-linux'"

# Add SSH public key (uses deep_data from common role)
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_add_pubkey=true __clients_id_prompted='XXXX'"
```

### Multi-line input (Tower/AAP)

For bulk user creation via `__data_prompted`, use one user per line with `;` as separator:

```
username;firstname;lastname;mail;group1,group2
jdoe;John;Doe;jdoe@example.com;linux,monitoring
jsmith;Jane;Smith;jsmith@example.com;linux
```

---

## Reporting

Generates a single **XLSX file per IPA instance**, sent by email. The report contains up to 15 sheets depending on which flags are enabled.

```bash
# Full report (all sheets)
ansible-playbook playbooks/managed_services/redhat_idm/reporting.yaml \
  -e "enable_all_reporting=true __clients_id_prompted='XXXX' __target_environment=prd"

# Specific sheets only
ansible-playbook playbooks/managed_services/redhat_idm/reporting.yaml \
  -e "enable_users_reporting=true enable_hosts_reporting=true __clients_id_prompted='XXXX'"

# Multiple clients
ansible-playbook playbooks/managed_services/redhat_idm/reporting.yaml \
  -e "enable_all_reporting=true __clients_id_prompted='XXXX;YYYY;ZZZZ'"
```

### Available reporting flags

| Flag | XLSX Sheet |
|---|---|
| `enable_users_reporting` | Users |
| `enable_user_groups_reporting` | User Groups |
| `enable_hosts_reporting` | Hosts |
| `enable_host_groups_reporting` | Host Groups |
| `enable_sudo_rules_reporting` | Sudo Rules |
| `enable_hbac_rules_reporting` | HBAC Rules |
| `enable_password_policies_reporting` | Password Policies |
| `enable_roles_reporting` | Roles |
| `enable_services_reporting` | Services |
| `enable_dns_zones_reporting` | DNS Zones |
| `enable_hbac_services_reporting` | HBAC Services |
| `enable_hbac_svc_groups_reporting` | HBAC Service Groups |
| `enable_sudo_commands_reporting` | Sudo Commands |
| `enable_sudo_cmd_groups_reporting` | Sudo Command Groups |
| `enable_automember_reporting` | Automember Rules |
| `enable_all_reporting` | All of the above + Summary |

### Report format

Each XLSX includes:
- **Summary sheet** — IPA metadata, object counts, alerts (disabled users, expiring passwords, empty rules)
- **Data sheets** — filterable Excel tables, frozen header row, conditional formatting:
  - Disabled users/rules → red background
  - Expired passwords → orange background
  - Passwords expiring within 30 days → yellow background

Requires `openpyxl` on the controller (`pip install openpyxl` — included in `setup.sh`).

---

## Initial cluster setup

```bash
# 1. Install FreeIPA server and replicas
ansible-playbook playbooks/managed_services/redhat_idm/setup/01_install_cluster.yaml \
  -i clients/XXXX/hosts.ini

# 2. Provision initial groups, policies, rules and users
ansible-playbook playbooks/managed_services/redhat_idm/setup/02_add_initial_data.yaml \
  -e "__clients_id_prompted='XXXX'" --vault-id ipa
```

---

## Notes

- `__clients_id_prompted` accepts multiple IDs separated by `;` — each IPA is processed independently and generates its own XLSX/ZIP
- `__target_environment` filters IPA instances by environment (`prd`, `managed`, `ebrc`, etc.)
- `__use_internal_communication_password=true` forces use of the `2000` CommCli password for ZIP encryption regardless of the client count
- When PMP is unreachable, the ZIP fallback password `Tigrou007@` is used — the email will contain an explicit warning and instructions for the L1 to re-encrypt before forwarding
- Credentials sent after user creation use the `templates/credential_mail.html.j2` HTML template

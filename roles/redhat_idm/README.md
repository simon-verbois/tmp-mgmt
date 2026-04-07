# redhat_idm

Manages users, groups, and policies on Red Hat IdM (FreeIPA) clusters. Generates formatted XLSX reports per IPA instance or per user.

## How it works

The role is driven by variables passed at runtime. The `tasks/main.yaml` entrypoint routes to one of three modules based on what's enabled:

| Variable | Module | Description |
|---|---|---|
| `REDHAT_IDM_INIT: true` | `tasks/setup/` | Initial cluster provisioning (groups, policies, rules, users) |
| `REDHAT_IDM_MANAGING: true` | `tasks/manage/` | User lifecycle operations |
| `REDHAT_IDM_REPORTING: true` | `tasks/reporting/` | Full XLSX report generation |

All manage and reporting operations delegate to `localhost` (API calls to IdM via Kerberos), not directly to the servers. Multiple IdM instances can be targeted at once via `__clients_id_prompted`.

---

## User management

Each operation produces an **XLSX report** sent by email:
- **Credential operations** (creation, password reset, enabling) → one XLSX per user, regrouped in a **password-protected ZIP** (encrypted via PMP)
- **Non-credential operations** (deletion, disabling, group management, SSH keys) → one XLSX per IPA instance, attached directly

### Status values in XLSX

| Status | Color | Meaning |
|---|---|---|
| Created, Reset, Enabled, Deleted, Disabled, Added, Removed, Injected | Green | Operation succeeded |
| Already exists, Already enabled, Already disabled, Already in group, Already removed, No key, Not found | Yellow | No change needed |
| Error: ... | Red | Operation failed |

### Create user

```bash
# Single user
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_creation=true __clients_id_prompted='XXXX' \
      usernames='jdoe' user_firstname='John' user_lastname='Doe' \
      user_mail='jdoe@example.com' user_groups='group1,group2'"

# Service account (password never expires, added to maxlife group)
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_creation=true __clients_id_prompted='XXXX' \
      usernames='svc-myapp' user_firstname='Service' user_lastname='MyApp' \
      user_mail='linux@example.com' user_groups='monitoring' \
      user_service_account=true"
```

**Bulk creation via Tower/AAP** — use `data_prompted` with one user per line, fields separated by `;`:

```
username;firstname;lastname;mail;groups
jdoe;John;Doe;jdoe@example.com;linux,monitoring
jsmith;Jane;Smith;jsmith@example.com;linux
```

### Delete user

```bash
# Single or multiple users (separated by ;)
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_deletion=true __clients_id_prompted='XXXX' usernames='jdoe;jsmith'"
```

### Reset password

```bash
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_password_reset=true __clients_id_prompted='XXXX' usernames='jdoe;jsmith'"
```

### Enable / Disable user

Enabling also resets the password and includes it in the XLSX.

```bash
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_enabling=true __clients_id_prompted='XXXX' usernames='jdoe'"

ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_disabling=true __clients_id_prompted='XXXX' usernames='jdoe'"
```

### Add / Remove from group

`user_groups` accepts comma-separated or space-separated group names.

```bash
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_add_group=true __clients_id_prompted='XXXX' \
      usernames='jdoe' user_groups='ict-linux,monitoring'"

ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_user_remove_group=true __clients_id_prompted='XXXX' \
      usernames='jdoe' user_groups='ict-linux'"
```

### Add SSH public key

Uses `deep_data` from the common role. Sends an XLSX report by email.

```bash
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml \
  -e "enable_add_pubkey=true __clients_id_prompted='XXXX'"
```

---

## Reporting

Generates one **XLSX file per IPA instance** containing all 15 data sheets, sent by email. The report is always complete — no granular flags needed.

```bash
# Single client
ansible-playbook playbooks/managed_services/redhat_idm/reporting.yaml \
  -e "__clients_id_prompted='XXXX' __target_environment=prd"

# Multiple clients
ansible-playbook playbooks/managed_services/redhat_idm/reporting.yaml \
  -e "__clients_id_prompted='XXXX;YYYY;ZZZZ'"
```

### Report content

| Sheet | Content |
|---|---|
| **Summary** | IPA metadata, object counts, alerts (disabled users, expiring passwords, empty rules) |
| Users | All users with status, groups, shell, password expiration |
| User Groups | Member users, member groups, HBAC/Sudo membership |
| Hosts | Hostgroups, Sudo/HBAC rules |
| Host Groups | Member hosts and rules |
| Sudo Rules | Commands, run-as, member users/hosts |
| HBAC Rules | Services, member users/hosts |
| Password Policies | Lifetime, history, lockout settings |
| Roles | Member users/groups/services, privileges |
| Services | Kerberos principals, certificates |
| DNS Zones | SOA, active status, transfer rules |
| HBAC Services | Service groups |
| HBAC Service Groups | Member services |
| Sudo Commands | Command groups |
| Sudo Command Groups | Member commands |
| Automember Rules | Inclusive/exclusive conditions for groups and host groups |

### Conditional formatting

| Color | Meaning |
|---|---|
| Red | Disabled users or inactive rules/zones |
| Orange | Expired passwords |
| Yellow | Passwords expiring within 30 days |

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

## Variables reference

| Variable | Default | Description |
|---|---|---|
| `__clients_id_prompted` | `""` | Client IDs to target, separated by `;` |
| `__clients_id_excluded_prompted` | `""` | Client IDs to exclude, separated by `;` |
| `__target_environment` | `""` | Filter by environment (`prd`, `managed`, `ebrc`, …) |
| `__use_internal_communication_password` | `false` | Force use of the `2000` CommCli password for ZIP encryption |
| `usernames` | *(required)* | Username(s) to act on, separated by `;` |
| `user_firstname` | *(required for creation)* | First name (single-user creation) |
| `user_lastname` | *(required for creation)* | Last name (single-user creation) |
| `user_mail` | `""` | Email address (single-user creation) |
| `user_groups` | `""` | Groups (comma or space separated) |
| `user_service_account` | `false` | If true: password never expires, adds to `maxlife` group |
| `user_uidnumber` | `""` | POSIX UID number to assign on creation (optional — IPA auto-assigns if empty) |
| `data_prompted` | `""` | Bulk creation input (Tower/AAP) — one user per line, `;` separated |

---

## Account Recreation After Accidental Deletion

When a user account is deleted via `enable_user_deletion`, the deletion email automatically includes a ready-to-use recreation command string for each deleted account.

Before deleting, the role fetches the account's full data from IPA (firstname, lastname, email, groups, POSIX UID, service account flag) using session cookie authentication. The recreation command is then embedded directly in the deletion email.

**Example value included in the email (paste directly into `data_prompted`) :**

```
jdoe;John;Doe;jdoe@example.com;linux,monitoring;158432
```

Format: `username;firstname;lastname;mail;groups;uidnumber` (uidnumber optional — omitted if not found)

Trigger the recreation by launching `enable_user_creation` with `__clients_id_prompted` set and this line in `data_prompted`. The account will be recreated with the same POSIX UID, groups, and email. If the user was a service account (member of `maxlife`), it is auto-detected from the groups field.

**Behaviour in edge cases:**

| Situation | Behaviour |
|---|---|
| Account not found before deletion | No recreation command in the email |
| Email absent in IPA | `__user_mail` omitted from the command |
| No group membership | groups field left empty in the `data_prompted` line |
| Service account (member of `maxlife`) | `maxlife` is included in the groups field — auto-detected on recreation |
| IPA unreachable during fetch | Recreation command silently omitted — deletion continues normally |

**Preserving the POSIX UID (`__user_uidnumber`):**

Passing `__user_uidnumber` to the creation workflow ensures the recreated account gets the same numeric UID as the original. This prevents filesystem permission issues when the user had files on shared storage. If `__user_uidnumber` is left empty, IPA auto-assigns a new UID (default behaviour, unchanged).

---

## Notes

- `__clients_id_prompted` accepts multiple IDs separated by `;` — each IPA is processed independently and generates its own XLSX or ZIP
- `__target_environment` filters IPA instances by environment before processing
- `__use_internal_communication_password=true` forces the `2000` CommCli password for ZIP encryption regardless of client count
- When PMP is unreachable, the ZIP fallback password `Tigrou007@` is used — the email will contain an explicit warning and instructions to re-encrypt before forwarding to the client
- Reporting and manage XLSX files are generated by `files/generate_xlsx_report.py` and `files/generate_xlsx_manage.py` — both require `openpyxl`, installed via `setup.sh`

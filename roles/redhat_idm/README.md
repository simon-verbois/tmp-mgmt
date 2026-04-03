# redhat_idm

Manages users, groups, and policies on Red Hat IdM (FreeIPA) clusters. Also generates detailed reports.

## How it works

The role is driven by variables passed at runtime. The `tasks/main.yaml` entrypoint includes the right task file based on what's enabled. It supports multiple IdM instances at once — you specify which clients to target with `__clients_id_prompted`.

Manage operations run against `localhost` (API calls to IdM), not against the servers directly.

## Usage

### User management

```bash
# Create
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml -e "enable_user_creation=true __clients_id_prompted='XXXX' __username='jdoe' __user_firstname='John' __user_lastname='Doe' __user_mail='jdoe@example.com' __user_groups='group1 group2'"

# Delete
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml -e "enable_user_deletion=true __clients_id_prompted='XXXX' __username='jdoe'"

# Reset password
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml -e "enable_password_reset=true __clients_id_prompted='XXXX' __username='jdoe'"

# Disable / Enable
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml -e "enable_user_disabling=true __clients_id_prompted='XXXX' __username='jdoe'"
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml -e "enable_user_enabling=true __clients_id_prompted='XXXX' __username='jdoe'"

# Add / Remove from group
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml -e "enable_user_add_group=true __clients_id_prompted='XXXX' __username='jdoe' __user_groups='ict-linux'"
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml -e "enable_user_remove_group=true __clients_id_prompted='XXXX' __username='jdoe' __user_groups='ict-linux'"
```

### Reporting

```bash
# Users
ansible-playbook playbooks/managed_services/redhat_idm/reporting.yaml -e "enable_users_reporting=true __users=jdoe __clients_id_prompted='XXXX;YYYY'"

# Full report
ansible-playbook playbooks/managed_services/redhat_idm/reporting.yaml -e "enable_all_reporting=true __clients_id_prompted='XXXX' __target_environment=managed"
```

### Setup (initial cluster setup)

```bash
ansible-playbook playbooks/managed_services/redhat_idm/setup/01_install_cluster.yaml -i clients/XXXX/hosts.ini
ansible-playbook playbooks/managed_services/redhat_idm/setup/02_add_initial_data.yaml -e "__clients_id_prompted='XXXX'"
```

## Notes

- You can use this variable "__use_internal_communication_password=true" to use 2000 comm cli password for the final zip
- Multiple clients can be targeted at once by separating IDs with `;` in `__clients_id_prompted`
- Multiple usernames can be passed the same way for bulk deletion or password reset
- After user creation, credentials are sent by mail using the `credential_mail.html.j2` template
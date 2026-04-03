# Managed Services

Playbooks to deploy and manage services that are actively operated as part of the infrastructure.

Unlike the `tools/` or `agents/` playbooks, these interact with running services or multi-server setups that require coordination (e.g., serial execution, inventory targeting).

## Available services

- **hashicorp_vault** — Unseal Vault instances after a restart
- **named** — Push BIND (DNS) configuration and reload the service safely
- **redhat_idm** — Manage users, groups, and policies on Red Hat IdM / FreeIPA clusters
- **redhat_podman** — Deploy rootless Podman containers with Quadlet services
- **redhat_tomcat** — Install, configure, or remove Tomcat on RHEL servers
- **squid** — Install Squid and push configuration from a Git repo

## Usage

Each service has its own subdirectory. Refer to the comments inside each playbook or the role README for the specific syntax.

```bash
# Named — push DNS config to internal servers
ansible-playbook playbooks/managed_services/named/push_config.yaml -i clients/2000/dns.ini -l internal

# Red Hat IdM — create a user
ansible-playbook playbooks/managed_services/redhat_idm/manage.yaml -e "enable_user_creation=true __clients_id_prompted='XXXX' __username='jdoe' ..."

# Hashicorp Vault — unseal
ansible-playbook playbooks/managed_services/hashicorp_vault/unseal.yaml -i clients/XXXX/hosts.ini
```

## Role docs

See `roles/<service_name>/README.md` for variables and requirements.
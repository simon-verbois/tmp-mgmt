# Automation

Playbooks designed to run automatically (e.g., via AAP/Tower scheduled jobs) to keep the infrastructure state consistent without manual intervention.

These are not meant to be run ad-hoc. They are triggered by schedules or pipelines.

## Playbooks

### automatic_clients_repositories_management.yml
Compares client Git repositories in GitLab against locations registered in Satellite. Creates missing repos and removes orphaned ones.

```bash
ansible-playbook playbooks/_automation/automatic_clients_repositories_management.yml
```

### automatic_clients_repositories_inventory_update.yml
Loops over all client Git repositories and updates their Ansible inventory files based on the current state.

```bash
ansible-playbook playbooks/_automation/automatic_clients_repositories_inventory_update.yml
```

### automatic_clients_repositories_sync.yml
Syncs client Git repositories to AAP/Tower — creates or updates inventory sources, projects, and cleans up ghost entries.

```bash
ansible-playbook playbooks/_automation/automatic_clients_repositories_sync.yml
```

## Role docs

See `roles/automation/README.md`.
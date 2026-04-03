# automation

This role handles everything related to keeping client Git repositories in sync with the rest of the infrastructure (Satellite locations, AAP inventories, etc.).

## How it works

Like other roles in the LAF, `tasks/main.yaml` acts as an entrypoint. The task to run is selected by setting a variable in the playbook:

| Variable | What it does |
|---|---|
| `CREATE_CLIENT_REPO_ON_GIT` | Creates missing client repos in GitLab, sent mail about orphaned ones based on Satellite |
| `UPDATE_HOSTS_ON_GIT_REPOS` | Updates hosts files inside each client repo |
| `SYNC_CLIENT_REPO_TO_AAP` | Syncs repos to AAP — configures projects, inventories, cleans up ghosts |

## Usage

```bash
# Manage repos (create/delete)
ansible-playbook playbooks/_automation/create_client_repo_on_git.yaml

# Update inventories
ansible-playbook playbooks/_automation/update_client_hosts_on_git.yaml

# Sync to AAP
ansible-playbook playbooks/_automation/sync_git_client_repo_to_aap.yaml
```
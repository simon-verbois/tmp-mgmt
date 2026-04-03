# hashicorp_vault

Automates the unsealing of HashiCorp Vault instances.

## How it works

The role checks the seal status of each Vault node. If sealed, it fetches the unseal keys from PMP (Password Manager Pro) and applies them one by one until the node is unsealed.

## Requirements

- The `common` role must be loaded before this one (provides `__pmp_api_url` and `__pmp_api_token`)
- The unseal key names must exist in PMP

## Variables

| Variable | Description |
|---|---|
| `__vault_recovery_key_names` | List of PMP resource names containing the unseal keys |

## Usage

```bash
# Unseal all vault nodes
ansible-playbook playbooks/managed_services/hashicorp_vault/unseal.yaml -i clients/XXXX/hosts.ini

# Unseal a specific node
ansible-playbook playbooks/managed_services/hashicorp_vault/unseal.yaml -i clients/XXXX/hosts.ini -e "limiter=sv-xxxxlvuxx.rh.xxxx.local"
```
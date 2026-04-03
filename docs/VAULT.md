# Vault & Secret Management

This document explains how secrets are managed in the LAF.

<br>

# How it works

We use **Ansible Vault** to encrypt sensitive variables directly inside YAML files. No plaintext passwords anywhere in the repo.

Each vault is identified by a **vault_id** — a label that tells Ansible which password file to use when decrypting.

<br>

# Vault IDs

All vault IDs and their passwords are stored in [PMP](https://pmp.corp.org.ebrc.local) with the following naming format:

```
ICT-LAS - LAF - Ansible Vault - <vault_id>
```

Common vault IDs:

| Vault ID | Used for |
|---|---|
| `centreon` | Centreon API credentials |
| `tower` | Tower / AAP credentials |
| `nnt` | NNT Change Tracker agent password |
| `client_data` | Client-specific secrets (tokens, keys, etc.) |
| `ipa` | Red Hat IdM credentials |

<br>

# Encrypt a variable

```bash
echo -n 'my_strong_password' | ansible-vault encrypt_string --encrypt-vault-id <vault_id>
```

This will output something like:

```yaml
myvar: !vault |
          $ANSIBLE_VAULT;1.2;AES256;ipa
          38363232303362396661333130376530616438643638393935376262643338656261306464356132
          3737346433663536333837666331343537633038656266360a336238623130323634343566346136
          ...
```

Just paste that block into your vars file.

<br>

# Setup vault passwords locally

Use the `setup.sh` script to fetch all vault passwords from PMP automatically. It will also overwrite your `~/.ansible.cfg` with the right vault identity list.

```bash
./setup.sh
```

The resulting config looks like:

```ini
vault_identity_list = centreon@~/vaults/centreon, tower@~/vaults/tower, nnt@~/vaults/nnt, ...
```

<br>

# Where to store encrypted vars

- **Shared secrets** (internal services, infra credentials) → `roles/common/vars/`
- **Role-specific secrets** (agent passwords, tokens) → `roles/<role_name>/defaults/main.yaml`
- **Client-specific secrets** (enrollment tokens, client keys) → client repo `group_vars/`

<br>

# Never store in plaintext

- No passwords in playbooks
- No tokens in inventory files
- No secrets in commit history

If you accidentally commit a secret, rotate it immediately and re-encrypt.
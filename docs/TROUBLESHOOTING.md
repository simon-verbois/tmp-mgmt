# Troubleshooting

Common issues and how to fix them.

<br>

## Ansible / Environment

### Wrong Ansible version

```
ERROR! Ansible requires a minimum version of X
```

Activate the right venv:

```bash
source /opt/ebrc/linux/venvs/ansible_core_py38/bin/activate
ansible --version  # should show 2.13.x
```

To make it permanent, add it to your `~/.bashrc`.

---

### Missing collection

```
ERROR! couldn't resolve module/action 'community.vmware.vmware_guest_disk'
```

Reinstall collections:

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

---

### Vault password not found

```
ERROR! Decryption failed (no vault secrets would decrypt)
```

Your vault passwords are missing or your `~/.ansible.cfg` is not configured.

Run the setup script again, or manually fetch from PMP:

```bash
bash setup.sh
```

Check that `~/.ansible.cfg` has the `vault_identity_list` line uncommented and pointing to your `./vaults/` folder.

---

### ANSIBLE_CONFIG not set

If your playbook doesn't pick up `collections_path` or `roles_path`:

```bash
export ANSIBLE_CONFIG="$HOME/.ansible.cfg"
source ~/.bashrc
```

<br>

## SSH / Connectivity

### Permission denied (publickey)

Check that your SSH agent is running and your key is loaded:

```bash
ssh-add -l               # list loaded keys
ssh-add ~/.ssh/my_key    # add your key
```

Check your `~/.ssh/config` has the right `ForwardAgent yes` and `IdentityFile` settings.

---

### Host unreachable

```
fatal: [sv-xxxxlvuxx.rh.xxxx.local]: UNREACHABLE!
```

Check connectivity through the proxy jump:

```bash
ssh sv-xxxxlvuxx.rh.xxxx.local id
```

If it fails, check that `infratool.bes` is reachable and your foreman key is in place.

---

### Host key checking failure

Already handled in `ansible.cfg` (`host_key_checking = False`). If you're running with a custom config, add:

```bash
export ANSIBLE_HOST_KEY_CHECKING=False
```

<br>

## Vault / Secrets

### Vault ID not in identity list

```
ERROR! Attempting to decrypt but no vault secrets found
```

The vault ID used in the encrypted variable doesn't have a matching entry in your `vault_identity_list`. Check `~/.ansible.cfg` and make sure the vault ID file exists in `./vaults/`.

---

### Re-encrypting a variable with the wrong vault ID

If you accidentally encrypted with the wrong vault ID, just re-encrypt:

```bash
echo -n 'my_value' | ansible-vault encrypt_string --encrypt-vault-id correct_vault_id
```

<br>

## Playbook Execution

### Token-based approval (disk extension)

If you're running `extend_lvm_volume` or `extend_swap` and the playbook stops asking for a token — that's expected. Run it first with `run_human_analysis=true` to get the token, then run again with the token.

```bash
# Step 1
ansible-playbook playbooks/tools/maintenance/extend_lvm_volume.yaml -i sv-xxxxlvuxx.rh.xxxx.local, -e "run_human_analysis=true"

# Step 2 (use the token from step 1)
ansible-playbook playbooks/tools/maintenance/extend_lvm_volume.yaml -i sv-xxxxlvuxx.rh.xxxx.local, -e "target_path=/opt/myapp requested_add_size_gb=20 auth_token=XXXXXX"
```

---

### Playbook fails on a specific host but you want to continue

Add `-e "ignore_errors=true"` or check if the playbook already has `ignore_unreachable: true` set.

---

### vars_prompt variable seems to reset mid-play

This is a known Ansible behavior — `vars_prompt` variables are refreshed at each task. Don't try to modify them during execution. If you need a computed version, use `set_fact` to create a new variable at the start of the play.

<br>

## PMP

### PMP token rejected

```
Error: Failed to access PMP API. Check Token.
```

Get a fresh token from PMP under `api-ansible-ro-linux` and re-run the setup:

```bash
bash setup.sh
```
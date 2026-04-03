# Tools

Standalone playbooks for day-to-day administration, troubleshooting, and server lifecycle management.

Playbooks are split into 4 categories:

- **`audits/`** — Read-only. Diagnostics, status checks, information gathering. Nothing gets modified.
- **`lifecycle/`** — Server transitions. Decommissioning, pre-shutdown, and power-on operations.
- **`maintenance/`** — Fixes and upkeep. Patching, cache cleaning, disk extension, performance tuning.
- **`security/`** — Permissions and access. SSH configuration, folder ownership.

## Usage

### Audits

```bash
# Run a full server diagnostic
ansible-playbook playbooks/tools/audits/server_diagnostic.yaml -e "target_server=sv-xxxxlvuxx.rh.xxxx.local"

# Check mounted NFS versions — output: ./nfs_audit_report.csv
ansible-playbook playbooks/tools/audits/nfs_version.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Check SELinux status — output: ./selinux_audit_report.csv
ansible-playbook playbooks/tools/audits/selinux_status.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Check SPM (automatic patching) status — output: ./yum_audit_report.csv
ansible-playbook playbooks/tools/audits/spm_status.yaml -i sv-xxxxlvuxx.rh.xxxx.local,
```

### Lifecycle

```bash
# Shutdown a server cleanly before decomm (Centreon downtime + shutdown)
ansible-playbook playbooks/tools/lifecycle/pre_decom_shutdown.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Power it back on and remove the Centreon downtime
ansible-playbook playbooks/tools/lifecycle/pre_decom_start.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Full decommission (GitLab, IPA, Satellite, vCenter)
cp import/decommission.ini.sample import/decommission.ini
vim import/decommission.ini
ansible-playbook playbooks/tools/lifecycle/server_decommission.yaml -i import/decommission.ini
```

### Maintenance

```bash
# Manual patching (with Centreon downtime + vCenter snapshot)
ansible-playbook playbooks/tools/maintenance/manual_patching.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Extend an LVM volume — step 1: review, step 2: apply
ansible-playbook playbooks/tools/maintenance/extend_lvm_volume.yaml -i sv-xxxxlvuxx.rh.xxxx.local, -e "run_human_analysis=true"
ansible-playbook playbooks/tools/maintenance/extend_lvm_volume.yaml -i sv-xxxxlvuxx.rh.xxxx.local, -e "target_path=/opt/myapp requested_add_size_gb=20 auth_token=XXXXXX"

# Extend swap — step 1: review, step 2: apply
ansible-playbook playbooks/tools/maintenance/extend_swap.yaml -i sv-xxxxlvuxx.rh.xxxx.local, -e "run_human_analysis=true"
ansible-playbook playbooks/tools/maintenance/extend_swap.yaml -i sv-xxxxlvuxx.rh.xxxx.local, -e "requested_add_size_gb=1 auth_token=XXXXXX"

# Clean SSSD cache
ansible-playbook playbooks/tools/maintenance/clean_sssd_cache.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Fix broken RPM/DNF database
ansible-playbook playbooks/tools/maintenance/rpm_db_fix.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Apply misc server tweaks (MOTD, PS1)
ansible-playbook playbooks/tools/maintenance/server_tweaks.yaml -i sv-xxxxlvuxx.rh.xxxx.local,
```

### Security

```bash
# Fix folder ownership (you will be prompted for path, owner, and group)
ansible-playbook playbooks/tools/security/folder_ownership.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# Configure SSHD to allow IPA pubkey authentication
ansible-playbook playbooks/tools/security/set_sshd_pubkey.yaml -i sv-xxxxlvuxx.rh.xxxx.local,
```

## Notes

- For disk extension operations, a **token-based approval** system is in place. Always run with `run_human_analysis=true` first to get the token before applying any change.
- Audit playbooks generate a local CSV file in your current directory.
- For the server decommission, fill in `import/decommission.ini` from the sample file before running.

## Role docs

See `roles/tools/README.md`.
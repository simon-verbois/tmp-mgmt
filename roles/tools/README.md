# tools

A collection of small sub-tasks designed to help with daily Linux administration. Some of these can also be delegated to the M2L team (ict-ops).

## How it works

Like other roles in the LAF, `tasks/main.yaml` is the entrypoint. Each playbook sets a variable that activates the right sub-task:

| Variable | What it does | Token |
|---|---|:---:|
| `MANUAL_PATCHING` | Runs `yum update` with pre/post Centreon downtime and vCenter snapshot | |
| `EXTEND_VOLUME` | Extends an LVM volume | ✓ |
| `EXTEND_SWAP` | Extends swap space | ✓ |
| `ADD_CPU` | Hot-adds vCPUs to a server | ✓ |
| `ADD_MEMORY` | Hot-adds memory (GB) to a server | ✓ |
| `CLEAN_SSSD_CACHE` | Clears the SSSD cache and restarts the service | |
| `RPM_DB_FIX` | Repairs a broken RPM/DNF database | |
| `SERVER_TWEAKS` | Applies misc tweaks (MOTD, PS1 prompt) | |
| `SERVER_DIAGNOSTIC` | Runs connectivity, CPU, memory, storage, and sysinfo checks | |
| `SERVER_DECOMMISSION` | Removes the server from GitLab, IPA, Satellite, and vCenter | |
| `PRE_DECOM_SHUTDOWN` | Puts server in Centreon downtime and shuts it down | |
| `PRE_DECOM_START` | Powers the server back on and removes the Centreon downtime | |
| `UPDATE_CRYPTO_POLICIES` | Updates the system-wide crypto policies | |

## Token-based approval

Operations marked with ✓ in the table above use a two-step workflow with automatic mode detection:

1. **Dry-run** (no `auth_token`) — analyzes the current state, runs all feasibility checks, displays a structured report, and generates a one-time authorization token stored on the target server.
2. **Execute** (with `auth_token`) — validates the token against the stored payload, then applies the change.

The token payload locks the input parameters provided during the dry-run. If any parameter is modified between the two runs, execution is rejected.

The mode is determined automatically: if `auth_token` is absent or empty, the playbook runs in dry-run mode. If `auth_token` is provided, it runs in execution mode.

### Extend LVM volume

```bash
# Dry-run
ansible-playbook playbooks/tools/maintenance/extend_lvm_volume.yaml \
  -i sv-xxxxlvuxx.rh.xxxx.local, \
  -e "target_path=/opt/myapp requested_add_size_gb=20"

# Execute
ansible-playbook playbooks/tools/maintenance/extend_lvm_volume.yaml \
  -i sv-xxxxlvuxx.rh.xxxx.local, \
  -e "target_path=/opt/myapp requested_add_size_gb=20 auth_token=XXXXXX"
```

Token locks: `target_path`, `requested_add_size_gb`.

The dry-run report includes: filesystem type/size/usage, LVM topology (LV, VG, PV, base disk), VG free space vs requested extension, vCenter disk details if physical extension is needed (matched disk, datastore, thin provisioning), datastore capacity and remaining free space after extension.

### Extend swap space

```bash
# Dry-run
ansible-playbook playbooks/tools/maintenance/extend_swap_space.yaml \
  -i sv-xxxxlvuxx.rh.xxxx.local, \
  -e "requested_add_size_gb=1"

# Execute
ansible-playbook playbooks/tools/maintenance/extend_swap_space.yaml \
  -i sv-xxxxlvuxx.rh.xxxx.local, \
  -e "requested_add_size_gb=1 auth_token=XXXXXX"
```

Token locks: `swap_device`, `requested_add_size_gb`.

The dry-run report includes: swap device, current/new size, swap usage, RAM available vs swap used (swapoff safety), LVM topology, vCenter/datastore details if needed.

| Variable | Default | Description |
|---|---|---|
| `swap_device` | auto-detected | Override the swap device (auto-detected from `swapon` by default) |
| `swapoff_ram_safety_pct` | `20` | RAM safety margin for swapoff. RAM available must be ≥ swap used × (1 + safety/100) |

### Add CPU

```bash
# Dry-run
ansible-playbook playbooks/tools/maintenance/extend_cpu.yaml \
  -i sv-xxxxlvuxx.rh.xxxx.local, \
  -e "requested_cpu_count=8"

# Execute
ansible-playbook playbooks/tools/maintenance/extend_cpu.yaml \
  -i sv-xxxxlvuxx.rh.xxxx.local, \
  -e "requested_cpu_count=8 auth_token=XXXXXX"
```

Token locks: `requested_cpu_count`.

The `requested_cpu_count` is the target total (not a delta). The dry-run report includes: current vs requested vCPU count, CPU hot-add status (via vSphere REST API), cores per socket alignment, hardware version max CPU limit, OS/vCenter consistency. New CPUs are automatically brought online at the OS level after extension.

### Add memory

```bash
# Dry-run
ansible-playbook playbooks/tools/maintenance/extend_memory.yaml \
  -i sv-xxxxlvuxx.rh.xxxx.local, \
  -e "requested_memory_gb=8"

# Execute
ansible-playbook playbooks/tools/maintenance/extend_memory.yaml \
  -i sv-xxxxlvuxx.rh.xxxx.local, \
  -e "requested_memory_gb=8 auth_token=XXXXXX"
```

Token locks: `requested_memory_gb`.

The `requested_memory_gb` is the target total in whole GB (not a delta). The dry-run report includes: current vs requested memory, memory hot-add status (via vSphere REST API), hardware version max memory limit, OS/vCenter consistency. New memory blocks are automatically brought online at the OS level after extension.

## vCenter disk extension settings

When a vCenter disk extension is required, the playbook checks that the target datastore has enough remaining free space after the operation. This applies to `EXTEND_VOLUME` and `EXTEND_SWAP`.

| Variable | Default | Description |
|---|---|---|
| `datastore_min_free_pct` | `5` | Minimum free space (%) required on the datastore after extension. The dry-run will report BLOCKED if the remaining space would drop below this threshold. |

This variable can also be set in the role's `defaults/main.yaml` to apply globally.

## Usage

See `roles/tools/README.md` or the comments inside each playbook for the full syntax per operation.
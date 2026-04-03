# redhat_podman

Sets up rootless Podman with a dedicated service account, LVM storage, SELinux contexts, and Quadlet-based container services.

## How it works

The role handles the full setup in one shot:
- Fixes expired root passwords if needed
- Creates a dedicated service account
- Configures LVM storage (optional)
- Enables cgroups v2 (required for Quadlets on RHEL 8)
- Configures journald for user services
- Pre-loads container images from the controller
- Deploys Quadlet `.container` files as systemd user services
- Validates everything at the end

On RHEL 8, cgroups v2 activation requires a reboot. The role detects this and either reboots automatically or tells you what to do.

## Requirements

- RHEL/CentOS 8+
- Podman available on the Ansible controller (for image handling)
- Collections: `ansible.builtin`, `ansible.posix`, `community.general`

## Key variables

| Variable | Description |
|---|---|
| `podman_service_account_name` | Unix user for the Podman service account (required) |
| `podman_volume_groups` | LVM volume group config (optional) |
| `podman_mountpoints` | LVM mountpoint config (optional) |
| `podman_images_to_load` | List of container images to pre-load |
| `podman_quadlet_files` | List of `.container` Quadlet files to deploy |
| `auto_reboot` | Set to `true` to reboot automatically if needed (default: `false`) |

Place your Quadlet files in `roles/redhat_podman/files/quadlets/`.

## Usage

```bash
# Basic setup
ansible-playbook playbooks/managed_services/redhat_podman/setup.yaml -i sv-xxxxlvuxx.rh.xxxx.local,

# With automatic reboot (RHEL 8 cgroups v2)
ansible-playbook playbooks/managed_services/redhat_podman/setup.yaml -i sv-xxxxlvuxx.rh.xxxx.local, -e auto_reboot=true

# Deploy Quadlets only after a manual reboot
ansible-playbook playbooks/managed_services/redhat_podman/setup.yaml -i sv-xxxxlvuxx.rh.xxxx.local, --tags podman_quadlets_post_reboot
```
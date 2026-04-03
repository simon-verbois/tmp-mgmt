# common

This role is not a standalone role — it's a shared dependency used by almost every other role in the LAF.

## What it does

It loads shared variables that other roles rely on, like credentials and connection details for internal services:

- `centreon` — monitoring API
- `tower` / AAP — automation platform
- `gitlab` — Git repositories
- `satellite` — Foreman/Satellite
- `ipa` / `all_ipa` — Red Hat IdM instances
- `vcenter` — VMware vCenter
- `pmp` — Password Manager Pro
- `mailing` — SMTP settings
- etc.

## How it works

The `tasks/main.yaml` is essentially empty — the role just loads the vars files. The variables defined here become available to any role that lists `common` before itself.

## Usage

You don't call this role directly. Just add it before your target role in the playbook:

```yaml
roles:
  - common
  - your_role
```
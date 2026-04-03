# azure_arc

Installs and removes the Azure Arc Connected Machine Agent (`azcmagent`) on RHEL servers.

## How it works

The role sets up the internal Yum repo, installs the required packages, and connects the server to Azure Arc using a Service Principal. For the installation, it also checks if the disk needs to be extended first (via vCenter) before proceeding.

On removal, it disconnects the agent from Azure Arc and uninstalls the packages.

## Requirements

- The target must have access to the internal Yum repo (`yumrepos.csv.local`)
- A valid Service Principal with the right permissions in Azure
- vCenter access if disk extension is needed
- Proxy must allow these urls

| URLs |
|---|
| `gbl.his.arc.azure.com` |
| `login.windows.net` |
| `login.microsoftonline.com` |
| `pas.windows.net` |
| `management.azure.com` |
| `agentserviceapi.guestconfiguration.azure.com` |
| `dc.services.visualstudio.com` |
| `gw.gbl.his.arc.azure.com` |
| `his.arc.azure.com` |


## Variables

Set in `defaults/main.yaml`. The important ones:

| Variable | Description |
|---|---|
| `__azurearc_subscription_id` | Azure subscription ID |
| `__azurearc_resource_group` | Target resource group |
| `__azurearc_tenant_id` | Azure tenant ID |
| `__azurearc_sp_id` | Service Principal ID |
| `__azurearc_sp_secret` | Service Principal secret (use vault) |
| `__azurearc_tags` | Tags to apply to the Arc resource |

## Usage

```bash
# Install
ansible-playbook playbooks/agents/azure_arc/installation.yaml -i client/xxxx/azure-arc.ini -l hostname

# Remove
ansible-playbook playbooks/agents/azure_arc/remove.yaml -i client/xxxx/azure-arc.ini -l hostname
```
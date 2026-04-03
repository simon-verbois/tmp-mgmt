# Setup

This guide walks you through setting up your local environment to use the LAF.

<br>

## Requirements

- Python 3.8.13 with Ansible 2.13.10
- Access to PMP to fetch vault passwords
- SSH access to servers via foreman-proxy
- Proxy configured in your environment

<br>

## Quick Setup (recommended)

Run the setup script from the LAF root. It handles everything automatically.

```bash
source /opt/ebrc/linux/venvs/ansible_core_py38/bin/activate
bash setup.sh
```

The script will:
1. Pull the latest version of the project
2. Configure your `~/.ansible.cfg`
3. Check and fix your venv if needed
4. Install missing Ansible collections
5. Install missing pip modules (`dnspython`, `Pyvmomi`)
6. Fetch all vault passwords from PMP and write them to `./vaults/`

You'll be prompted for your PMP token (`api-ansible-ro-linux`) at the start.

<br>

## Manual Setup

If you prefer to do it step by step:

### 1. Activate the venv

```bash
source /opt/ebrc/linux/venvs/ansible_core_py38/bin/activate
```

Add this to your `~/.bashrc` to make it permanent.

### 2. Pull the project

```bash
git pull
```

### 3. Install Ansible collections

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

### 4. Install pip modules

```bash
pip3 install dnspython Pyvmomi
```

### 5. Fetch vault passwords

See `docs/VAULT.md` for the full vault setup guide.

### 6. Configure your SSH

Add this to your `~/.bashrc` and `~/.ssh/config`:

```bash
# ~/.bashrc
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval `ssh-agent -s` > /dev/null
fi
# Then once: ssh-add ~/.ssh/private_key
```

```
# ~/.ssh/config
Host infratool.bes
    Hostname 10.207.16.109
    User foreman-proxy
    IdentityFile ~/.ssh/foreman_private_key
    ForwardAgent yes
    AddKeysToAgent yes

Host *
    User foreman-proxy
    IdentityFile ~/.ssh/foreman_private_key
    ForwardAgent yes
    AddKeysToAgent yes
```

### 7. Configure your proxy

Add this to your `~/.bashrc`:

```bash
export http_proxy=webproxy.csv.local:3128
export https_proxy=webproxy.csv.local:3128
export no_proxy=10.0.0.0/8,127.0.0.0/8,172.16.0.0/12,192.168.0.0/16,local,localhost,ebrc.cloud,ebrc.lab
```

<br>

## Verify everything works

```bash
ansible --version           # should show 2.13.x
ansible-galaxy collection list | grep community.vmware
ssh sv-2000lvu42.rh.ebrc.local id
```
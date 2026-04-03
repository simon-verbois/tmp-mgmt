# Onboarding

Everything you need to get up and running with the LAF.

<br>

# Requirements

- Python 3.8.13 (for Ansible 2.13.10)
- Access to the internal network and VPN
- SSH access via foreman-proxy
- Access to PMP to retrieve vault passwords
- A GitLab account on `gitlab.rh.ebrc.local`

<br>

# First time setup

The `setup.sh` script handles most of the setup for you (venv activation, collections, pip modules, vault passwords).

```bash
git clone https://gitlab.rh.ebrc.local/ict-las/laf
cd laf
./setup.sh
```

If you prefer to do it manually:

```bash
# 1. Activate the Python venv
source /opt/ebrc/linux/venvs/ansible_core_py38/bin/activate

# 2. Install Ansible collections
ansible-galaxy collection install -r collections/requirements.yml

# 3. Install required pip modules
pip3 install dnspython Pyvmomi

# 4. Fetch vault passwords from PMP (see docs/VAULT.md)
```

<br>

# SSH configuration

Add this to your `~/.ssh/config` to be able to reach servers through the foreman-proxy jump host:

```
Host infratool.bes
    Hostname 10.207.16.109
    User foreman-proxy
    IdentityFile ~/.ssh/foreman_private_key
    ForwardAgent yes
    AddKeysToAgent yes

Host foreman.bes
    Hostname 10.207.16.105
    User username
    ProxyJump infratool.bes
    IdentityFile ~/.ssh/foreman_1629_private_key
    ForwardAgent yes
    AddKeysToAgent yes

Host *
    User foreman-proxy
    IdentityFile ~/.ssh/foreman_private_key
    ForwardAgent yes
    AddKeysToAgent yes
```

Also make sure ssh-agent is running. Add this to your `~/.bashrc`:

```bash
if [ -z "$SSH_AUTH_SOCK" ] ; then
    eval `ssh-agent -s` > /dev/null
fi
# Then run once: ssh-add ~/.ssh/private_key
```

<br>

# Proxy configuration

Add this to your `~/.bashrc`:

```bash
export http_proxy=webproxy.csv.local:3128
export https_proxy=webproxy.csv.local:3128
export no_proxy=10.0.0.0/8,127.0.0.0/8,172.16.0.0/12,192.168.0.0/16,localhost,ebrc.cloud,ebrc.lab,...
```

<br>

# Running your first playbook

```bash
# Make sure your venv is active
source /opt/ebrc/linux/venvs/ansible_core_py38/bin/activate

# Run a simple audit to test connectivity
ansible-playbook playbooks/tools/audits/selinux_status.yaml -i sv-xxxxlvuxx.rh.xxxx.local,
```

<br>

# Next steps

- Read `docs/CONTRIBUTING.md` before making any changes
- Read `docs/ARCHITECTURE.md` to understand how the project is structured
- Read `docs/VAULT.md` to understand how secrets work
- Check the Wiki: `https://portal.trustedcloudeurope.com` → ICT LINUX → Linux Automation Framework
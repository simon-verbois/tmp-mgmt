# What is this

This project is design to become the centralized system in the futur, to manage our infrastructure, so it centralize the roles, tasks, playbooks, etc.<br>
But also the authentification to sub-services (centreon, vcenter, etc.).<br>
To contribute to it, please read first `docs/CONTRIBUTING.md`<br>
You can also found a guide to help you with GIT commands if you are not used to `docs/GIT_CHEATSHEET.md`

# Secret management
This project is using ansible vault mainly as text variable.<br>
All the vault_id can be found on [PMP](https://pmp.corp.org.ebrc.local), with this format:<br>
`ICT-LAS - LAF - Ansible Vault - vault_id`

The setup.sh script can be used to fetch all the password automatically, and overwrite your ~/.ansible.cfg, for this it will use the ansible.cfg.sample file, here is an example of the vault configuration.<br>
```
vault_identity_list = centreon@/home/username/Gitlab/laf/vaults/centreon, tower@/home/username/Gitlab/laf/vaults/tower, etc...
```

To encrypt a password, and add it in a variable, please use this command:
```bash
echo -n 'my_strong_password' | ansible-vault encrypt_string --encrypt-vault-id vault_id
```

You will obtain this result (with your vault_id after the cipher, here ipa for the example), after this, just add the var in your file:
```bash
myvar: !vault |
          $ANSIBLE_VAULT;1.2;AES256;ipa
          38363232303362396661333130376530616438643638393935376262643338656261306464356132
          3737346433663536333837666331343537633038656266360a336238623130323634343566346136
          34313831663766623364613932333062653636646566646237363436376464613937373566663931
          6362613162333433620a336331623565323634373333303765323565666161643766376137643831
          64613739393036363265613134383838663739373362393432306165616464336237
```

# Requirements
Until we are on tower.csv.local, we need these requirements, they all can setup by the `setup.sh` script.
- Python 3.8.13, for ansible 2.13.10
  - Use `source /opt/ebrc/linux/venvs/ansible_core_py38/bin/activate`
- Ansible collections
  - Listed here: `collections/requirements.yml`
  - Use `ansible-galaxy collection install -r collections/requirements.yml`
- Some pip modules
  - Use `pip3 install dnspython Pyvmomi`
- The latest version of the project
  - Use `git pull`
- The **vaults** folder with all the vault passwords *(refer to [Secret management](#secret-management))*
- SSH authentification from your session to all server via foreman-proxy (atm), there is a complete example:
  ```
  # Add this in your ~/.bashrc
  #if [ -z "$SSH_AUTH_SOCK" ] ; then
  #  eval `ssh-agent -s` > /dev/null
  #fi
  # Then one time
  # ssh-add ~/.ssh/private_key

  Host gitlab.rh.ebrc.local 
    User username
    IdentityFile ~/.ssh/private_key
    ForwardAgent yes
    AddKeysToAgent yes

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
- Ensure your proxy configuration is OK in your `~/.bashrc`
  ```
  # Proxy
  export http_proxy=webproxy.csv.local:3128
  export https_proxy=webproxy.csv.local:3128
  export no_proxy=10.0.0.0/8,127.0.0.0/8,172.16.0.0/12,192.168.0.0/16,example,example.com,example.net,example.org,internal,invalid,local,localdomain,localhost,onion,private,test,ebrc.cloud,ebrc.lab,ebrc8002.cloud,obj.ebrc.com,10.3.2.15,agf.lu,azlu.lu,cornet,customer.onecloud.lu,customeruat.onecloud.lu,ext.allianz.lu,generali.lu
  ```


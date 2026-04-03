#!/bin/bash

# Color scheme for output
red="\033[00;31m"
NC="\033[00m"

# Font type
bold=$(tput bold)
normal=$(tput sgr0)

# Settings
PIP_MODULES_LIST=('dnspython' 'Pyvmomi' 'openpyxl')
ANSIBLE_MIN_REQUIRED_VERSION="2.13.10"
NOTIFY_FOREMAN="false"
LAF_DIR=$(pwd)


function Welcome() {
    echo -e "${bold}Welcome in L2-administration project setup script!${normal}"
    echo "This script will help you configure the project so that you can use it quickly."
    echo "It will :"
    echo "  - Pull the project (just in case)"
    echo "  - Create folders on which certain playbooks depends on, to being locally runned"
    echo "  - Uncomment the 'vault_identity_list' settings in ~/.ansible.cfg"
    echo "  - Check ansible version (propose to fix your venv if you want it)"
    echo "  - Check if all ansible collections are present, if not it will install them"
    echo "  - Check if all pip modules are present, if not it will install them"
    echo "  - Check if foreman key is set"
    echo "  - Fetch ansible vaults password on PMP"
    echo
    read -s -p "Provide the 'api-ansible-ro-linux' token (search on PMP): " PMP_TOKEN
    echo
}


function RefreshGitProject(){
    echo
    echo -e "${bold}Refresh folder data...${normal}"
    git pull
    echo
}


function SetupAnsibleConfigFile(){
    echo -e "${bold}Configure ansible config file...${normal}"

    if [[ -f ~/.ansible.cfg ]]; then
        echo "Backup ~/.ansible.cfg config file to ~/.ansible.cfg.bkp"
        cp -f ~/.ansible.cfg ~/.ansible.cfg.bkp
    fi

    echo "Copy sample file cfg to ~/.ansible.cfg..."
    cp -f ./utils/samples/ansible/ansible.cfg.sample ~/.ansible.cfg 

    echo "Update collections_path settings"
    sed -i "s#^collections_path.*#collections_path = ${LAF_DIR}/collections#" ~/.ansible.cfg

    echo "Update roles_path settings"
    sed -i "s#^roles_path.*#roles_path = ${LAF_DIR}/roles#" ~/.ansible.cfg

    echo "Fetch - Linux Galaxy Hub token"
    sed -i "s/<AAP-TOKEN>/$(PMPFetchPassword "LAF - AAP Automation Hub - Token")/g" ~/.ansible.cfg 

    local config_line='export ANSIBLE_CONFIG="$HOME/.ansible.cfg"'
    if grep -q 'export ANSIBLE_CONFIG' ~/.bashrc; then
        echo "Updating existing ANSIBLE_CONFIG export in ~/.bashrc"
        sed -i 's#^export ANSIBLE_CONFIG.*#'"$config_line"'#' ~/.bashrc
    else
        echo "Adding ANSIBLE_CONFIG export to ~/.bashrc"
        echo "$config_line" >> ~/.bashrc
    fi

    source ~/.bashrc
    echo "Ansible configuration setup is complete."
    echo
}


function CheckPipModules() {
    # Install pip module dependencies
    echo -e "${bold}Check pip modules...${normal}"

    for MODULE in "${PIP_MODULES_LIST[@]}"; do
        MODULE_PRESENT=$(pip3 list | grep -oi $MODULE)
        if [[ "${MODULE,,}" == "${MODULE_PRESENT,,}" ]]; then
            echo "PIP3 module ($MODULE) is OK"
        else
            echo "PIP3 module ($MODULE) not found, installation..."
            pip3 install $MODULE
        fi
    done
    echo
}


function CheckForVenv() {
    # Check if the venv is correclty set
    ANSIBLE_VERSION=$(ansible --version | sed -n 's/ansible \[core \([0-9.]*\)\]/\1/p')

    echo
    echo -e "${bold}Check ansible version...${normal}"

    if [[ "$(printf '%s\n' "$ANSIBLE_MIN_REQUIRED_VERSION" "$ANSIBLE_VERSION" | sort -V | head -n1)" != "$ANSIBLE_MIN_REQUIRED_VERSION" ]]; then
        echo "${red}Ansible version ($ANSIBLE_VERSION) is older than the minimum required version for this project ($ANSIBLE_MIN_REQUIRED_VERSION).${NC}"
        read -p "Do you want to add a venv to your .bashrc? (yes/no): " choice

        if [[ "$choice" == "yes" ]]; then
            sed -i '/source \/opt\/ebrc\/linux\/venvs/s/^/# /' ~/.bashrc
            echo -e "\n# Define default venv" >> ~/.bashrc
            echo "source /opt/ebrc/linux/venvs/ansible_core_py38/bin/activate" >> ~/.bashrc
            source ~/.bashrc
        else
            echo "Skip .bashrc modification."
        fi
    else
        echo "Ansible version ($ANSIBLE_VERSION) is OK."
    fi
}


function InstallAnsibleCollections() {
    # Install required collections
    echo -e "${bold}Check ansible collections...${normal}"

    ansible-galaxy collection install -r collections/requirements.yml
}


function CheckForSSHKey() {
    # Check if we can connect to another server
    echo -e "${bold}Check if foreman key is present...${normal}"

    ssh sv-2000lvu42.rh.ebrc.local -f id 2> /dev/null
    if [[ "&?" != "0" ]]; then
        echo 'Connection to sv-2000lvu42.rh.ebrc.local OK'
    else
        echo -e "${bold}Connection to sv-2000lvu42.rh.ebrc.local failed, check your ssh config of if the server is still there${normal}"
    fi
}


function FetchAnsibleVaultPasswords(){
    local PMP_ENTRIES_HEADER="ICT-LAS - LAF - Ansible Vault"
    echo
    echo -e "${bold}Fetching ansible vault passwords...${normal}"
    echo "List all passwords prefixed by > $PMP_ENTRIES_HEADER <"
    PASSWORD_LIST=$(curl -k -X GET -H "AUTHTOKEN:${PMP_TOKEN}" "https://pmp.corp.org.ebrc.local/restapi/json/v1/resources" 2> /dev/null | jq -r '.operation.Details[] | {"RESOURCE NAME", "RESOURCE ID"}' | grep "$PMP_ENTRIES_HEADER" | awk '{ gsub(/[",]/, "", $10); print $10 }' )
    
    echo 'Create vaults folder if necessary'
    mkdir -p ./vaults

    for PASSWORD in $PASSWORD_LIST; do
        echo "Fetch - $PASSWORD"
        echo $(PMPFetchPassword "$PMP_ENTRIES_HEADER - $PASSWORD") > $LAF_DIR/vaults/$PASSWORD
    done
    echo
    echo 'All password are downloaded'

    # Parse all password and fill the ansible.cfg
    for VAULT in $(ls -1 ./vaults/); do
        VAULTS_LIST+=" ${VAULT}@${LAF_DIR}/vaults/${VAULT},"
    done
    VAULTS_LIST=$(echo "$VAULTS_LIST" | sed 's/,$//')
    sed -i "s|^#vault_identity_list *=.*|vault_identity_list =$VAULTS_LIST|" ~/.ansible.cfg
}


function Goodbye(){
    echo 
    if [[ $NOTIFY_FOREMAN == "true" ]]; then
        echo
        echo -e "${red}Foreman key wasn't founded (${FOREMAN_KEY_PATH}).${NC}"
        echo "Please add the key or a symbolic link to it (foreman.key) with posix permissions '600' in your '~/.ssh'"
        echo 
        echo "vim $FOREMAN_KEY_PATH"
        echo "chmod 600 $FOREMAN_KEY_PATH"
        echo "OR"
        echo "ln -s /path/to/the/key $FOREMAN_KEY_PATH"
        echo "chmod 600 $FOREMAN_KEY_PATH"
    fi
    echo -e "${bold}Goodbye!${normal}"
}

function PMPFetchPassword(){
    local PASS_NAME="$1"

    # Get mandatory ressources
    RESOURCE_ID=$(curl -k -X GET -H "AUTHTOKEN:${PMP_TOKEN}" "https://pmp.corp.org.ebrc.local/restapi/json/v1/resources" 2> /dev/null | jq -r '.operation.Details[] | {"RESOURCE NAME", "RESOURCE ID"}' | grep "${PASS_NAME}" -A 1 | tail -n 1 | awk -F '"' '{print $4}')
    if [[ -z $RESOURCE_ID ]]; then
        echo -e "${red}PMP Token is not correct.${NC}"
        exit 1
    fi
    ACCOUNT_ID=$(curl -k -X GET -H "AUTHTOKEN:${PMP_TOKEN}" "https://pmp.corp.org.ebrc.local/restapi/json/v1/resources/$RESOURCE_ID/accounts" 2> /dev/null | jq -r '.operation.Details["ACCOUNT LIST"][0]["ACCOUNT ID"]')
    
    # Fetch password with a clean output
    curl -k -X GET -H "AUTHTOKEN:${PMP_TOKEN}" "https://pmp.corp.org.ebrc.local/restapi/json/v1/resources/$RESOURCE_ID/accounts/$ACCOUNT_ID/password" 2> /dev/null | jq  -r '.operation.Details["PASSWORD"]'
}

function CheckScriptRequirements(){
    # Check is token is providen
    if [ -z "$PMP_TOKEN" ]; then
        echo "Error: PMP_TOKEN is empty" >&2
        exit 1
    fi

    # Check PMP Access
    RESPONSE=$(curl -s -f -k -X GET -H "AUTHTOKEN:${PMP_TOKEN}" "https://pmp.corp.org.ebrc.local/restapi/json/v1/resources")
    if [ "$(echo "$RESPONSE" | jq -r '.operation.result.status // empty')" == "Failed" ]; then
        echo "Error: Failed to access PMP API. Check Token."
        exit 1
    fi
}

function Main() {
    Welcome

    CheckScriptRequirements
    
    CheckForVenv
    RefreshGitProject
    SetupAnsibleConfigFile
    CheckPipModules
    InstallAnsibleCollections
    FetchAnsibleVaultPasswords

    Goodbye
}


Main

exit 0
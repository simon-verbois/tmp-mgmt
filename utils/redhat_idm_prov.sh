#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

TEMPLATE_INV="$(realpath "$SCRIPT_DIR/samples/ipa/ipa.ini.sample")"
TEMPLATE_VARS="$(realpath "$SCRIPT_DIR/samples/ipa/main.yaml.sample")"

read -p "Enter Client ID: " CLIENT_ID
if [[ -z "$CLIENT_ID" ]]; then
    echo "Error: Client ID cannot be empty."
    exit 1
fi

read -p "Enter Domain (e.g., rh.domain.local): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    echo "Error: Domain cannot be empty."
    exit 1
fi

REALM="${DOMAIN^^}"

DEST_DIR="$(realpath -m "$SCRIPT_DIR/../clients/$CLIENT_ID")"
DEST_INV="$DEST_DIR/ipa.ini"
DEST_VARS_DIR="$DEST_DIR/group_vars/ipacluster"
DEST_VARS="$DEST_VARS_DIR/main.yaml"

echo ""
echo "--- Summary ---"
echo "Client ID: $CLIENT_ID"
echo "Domain:    $DOMAIN"
echo "Realm:     $REALM"
echo "Templates: $TEMPLATE_INV"
echo "           $TEMPLATE_VARS"
echo "Outputs:   $DEST_INV"
echo "           $DEST_VARS"
echo "---------------"
read -p "Confirm? (Y/n): " CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ ! "$CONFIRM" =~ ^[Yy] ]]; then
    echo "Aborted."
    exit 0
fi

if [[ ! -f "$TEMPLATE_INV" || ! -f "$TEMPLATE_VARS" ]]; then
    echo "Error: One or more template files not found."
    exit 1
fi

mkdir -p "$DEST_DIR"
mkdir -p "$DEST_VARS_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
for FILE in "$DEST_INV" "$DEST_VARS"; do
    if [[ -f "$FILE" ]]; then
        BACKUP_FILE="${FILE}_${TIMESTAMP}"
        mv "$FILE" "$BACKUP_FILE"
        echo "Info: Existing file backed up as ${BACKUP_FILE}"
    fi
done

PASS_ADMIN=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20)
PASS_DM=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 20)

set +e
# Suppression de --name pour récupérer uniquement le bloc !vault pur
VAULT_ADMIN=$(echo -n "$PASS_ADMIN" | ansible-vault encrypt_string --encrypt-vault-id client_data)
VAULT_DM=$(echo -n "$PASS_DM" | ansible-vault encrypt_string --encrypt-vault-id client_data)
VAULT_EXIT_CODE=$?
set -e

if [ $VAULT_EXIT_CODE -ne 0 ]; then
    echo "Error: Vault encryption failed. Check your 'client_data' vault setup."
    exit 1
fi

# awk reconstruit la ligne avec la clé YAML et ignore l'ancien contenu indenté
awk -v va="$VAULT_ADMIN" \
    -v vd="$VAULT_DM" \
    -v dom="$DOMAIN" \
    -v r="$REALM" '
/^ipaserver_domain:/ { print "ipaserver_domain: \"" dom "\""; next }
/^ipaserver_realm:/ { print "ipaserver_realm: \"" r "\""; next }
/^ipaadmin_password:/ { print "ipaadmin_password: " va; skip=1; next }
/^ipadm_password:/ { print "ipadm_password: " vd; skip=1; next }
skip && (/^[^ \t]/ || /^$/) { skip=0 }
skip { next }
{ print }
' "$TEMPLATE_VARS" > "$DEST_VARS"

sed "s/rh.smp.deep.cloud/$DOMAIN/g" "$TEMPLATE_INV" > "$DEST_INV"

echo "Success: Files generated in $DEST_DIR"
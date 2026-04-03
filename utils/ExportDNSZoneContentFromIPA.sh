#!/bin/bash

# --- Configuration ---
ZONE="rh.ebrc.local"
OUTPUT_FILE="export_dns_${ZONE}.csv

echo "Extraction des enregistrements DNS pour la zone : $ZONE ..."

# Écrire l'en-tête du fichier CSV (overwrite)
echo "Nom,Type,Donnée" > "$OUTPUT_FILE"

# Utiliser dnsrecord-find qui est la commande appropriée pour lister les enregistrements.
# Le résultat est ensuite "pipé" vers awk pour le formatage en CSV.
ipa dnsrecord-find "$ZONE" --sizelimit=0 --all | awk '
BEGIN {
  # Définit le séparateur de champ comme étant ":" suivi par un ou plusieurs espaces.
  # Parfait pour les lignes comme "A record: 10.253.6.150"
  FS=": +"
}

# Si la ligne contient "Record name:", on capture le nom de lhost.
/Record name:/ {
  # Le nom est dans le 2ème champ ($2).
  current_name = $2
  # On retire les espaces inutiles au début ou à la fin.
  gsub(/^[ \t]+|[ \t]+$/, "", current_name)
}

# Si la ligne contient "record:", on a trouvé un enregistrement DNS.
/record:/ {
  # Le type (A, AAAA, CNAME, etc.) est le premier mot du premier champ ($1).
  split($1, type_array, " ")
  type = type_array[1]

  # La donnée est tout ce qui se trouve dans le deuxième champ ($2).
  data = $2
  # On retire les espaces inutiles.
  gsub(/^[ \t]+|[ \t]+$/, "", data)

  # On définit le nom à "@" si aucun "Record name" n a été vu avant.
  # Utile pour les enregistrements à la racine de la zone.
  if (current_name == "") {
      host_name = "@"
  } else {
      host_name = current_name
  }

  # On imprime la ligne au format CSV.
  # Les guillemets autour de "data" protègent les données qui contiennent des espaces (ex: TXT).
  print host_name "," type "," "\"" data "\""
}

# Réinitialise current_name quand on voit une ligne de séparation "---"
# pour gérer correctement les enregistrements à la racine de la zone.
/^-+$/ {
  current_name = ""
}
' >> "$OUTPUT_FILE"

# Petite vérification à la fin
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
if [ ${LINE_COUNT} -le 1 ]; then
  echo "Avertissement : Aucun enregistrement n'a été trouvé."
  echo "Veuillez vérifier manuellement la sortie de la commande 'ipa dnsrecord-find ${ZONE} --sizelimit=0'."
else
  # On soustrait 1 (la ligne d'en-tête) pour avoir le nombre d'enregistrements.
  RECORD_COUNT=$((LINE_COUNT - 1))
  echo "Terminé. ${RECORD_COUNT} enregistrements ont été exportés dans le fichier : ${OUTPUT_FILE}"
fi

exit 0

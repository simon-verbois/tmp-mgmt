#!/bin/bash

# This script is used to generate role files header and make a small lint

# Usage
# bash role-linter-and-add-header.sh roles/role_name

usage() {
  echo "Usage: bash $0 <path_to_ansible_role>"
  echo "Example: bash $0 roles/my_ansible_role"
  exit 1
}

if [[ $# -eq 0 ]]; then
  usage
fi

ROLE_PATH=$1

if [[ ! -d "$ROLE_PATH" ]]; then
  echo "Error: Directory '$ROLE_PATH' does not exist."
  exit 1
fi

processed_files=0
updated_files=0

printf "Scanning Ansible role: %s\n" "${ROLE_PATH}"
printf -- "---\n"

while IFS= read -r -d '' file; do
  ((processed_files++))

  expected_header="# ${file}"
  first_line=$(head -n 1 "$file" || true)

  # --- Check 1: Double Dash ---
  header_lines_3_4=$(sed -n '3,4p' "$file")
  double_dash_error=0
  if [[ "$(echo "$header_lines_3_4" | sed -n '1p' | tr -d ' ')" == "---" ]] && \
     [[ "$(echo "$header_lines_3_4" | sed -n '2p' | tr -d ' ')" == "---" ]]; then
    double_dash_error=1
  fi

  # --- Check 2: Final Newline ---
  # We want exactly one trailing newline.
  # 'newline_ok=1' means the file is compliant.
  newline_ok=0
  # Check 1: Does it end with at least one newline? (POSIX compliant)
  if [[ -z "$(tail -c 1 "$file")" ]]; then
    # Check 2: Does it end with more than one?
    # If the 2nd-to-last char is NOT a newline, we are good.
    if [[ "$(tail -c 2 "$file" | head -c 1)" != $'\n' ]]; then
      newline_ok=1
    fi
  fi
  # Note: An empty file will have newline_ok=1, but fail on first_line check,
  # which is correct as it needs to be fixed.

  # --- Final Check ---
  # The file is "correct" only if all 3 conditions are met.
  if [[ "$first_line" == "$expected_header" ]] && \
     [[ $double_dash_error -eq 0 ]] && \
     [[ $newline_ok -eq 1 ]]; then
    echo "✔️  File is already correct: ${file}"
    continue
  fi

  echo "Updating file: ${file}"
  
  # --- Rebuild File ---
  (
    temp_file=$(mktemp)
    temp_content=$(mktemp)
    trap 'rm -f "$temp_file" "$temp_content"' EXIT INT TERM

    # 1. Header
    echo -e "${expected_header}\n\n---" > "${temp_file}"

    # 2. Body (cleaned of old headers)
    awk '!/^[ \t]*$/ && !/^[ \t]*#/ && !/^[ \t]*---/ {p=1} p' "$file" > "${temp_content}"

    # 3. Combine
    cat "${temp_content}" >> "${temp_file}"

    # 4. Normalize final newline and save to final temp file
    # 'awk 1' prints every line and ensures exactly one trailing newline
    awk 1 "${temp_file}" > "${temp_content}"

    # 5. Move final version
    mv "${temp_content}" "$file"
  )

  if [[ $? -ne 0 ]]; then
    echo "❌ Error processing file: ${file}" >&2
    exit 1
  fi
  
  echo "✅ File updated: ${file}"
  ((updated_files++))

done < <(find "$ROLE_PATH" -type f \( -name "*.yml" -o -name "*.yaml" \) -print0)

echo "-------------------------------------------"
echo "Done. Files processed: ${processed_files}. Files updated: ${updated_files}."
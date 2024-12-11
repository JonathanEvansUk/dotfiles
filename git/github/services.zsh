#!/opt/homebrew/bin/bash

local services_file=$ZSH/git/github/.cache/servicesByTeam.json

services_by_team() {
  if [ ! -f $services_file ]; then
    update_services_by_team
  fi
  cat $services_file
}

find_services_by_team() {
  local team=$1
  local services=$(gh search code "* @Paytrix-IO/$team" --owner=paytrix-io --filename=CODEOWNERS --json repository -q '[.[].repository.nameWithOwner | sub("Paytrix-IO/";"")]' | jq 'sort')

  # Add a key-value pair to the JSON object
  json_object=$(echo "$json_object" | jq --arg team "$team" --arg services "$services" '. + {($team): $services | fromjson}')
}

update_services_by_team() {
  # Create a JSON object with jq
  json_object=$(echo '{}' | jq '.')

  find_services_by_team "compliance"
  find_services_by_team "finance"
  find_services_by_team "foundations"
  find_services_by_team "payments"

  echo "$json_object" > $services_file
}


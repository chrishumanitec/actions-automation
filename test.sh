#!/bin/bash

# Uses the following Environment varaibles:
# GITHUB_ORG      The github organization the repo was forked to
# GITHUB_PAC      The Github Access Token to use for the request
# HUMANITEC_TOKEN The Humanitec API token to use to build the payload

# Wrapper around curl that handles errors and exists script on error
function make_request
{
  if ! resp=$(curl -s -w "%{http_code}" "$@")
  then
    echo "Error making request ${!#}" >&2
    exit 1
  fi

  status_code=$(echo "${resp}" | tail -n 1 | sed 's/^.*[^0-9]\([0-9]*\)$/\1/')
  if [ "${status_code}" -ge 400 ]
  then
    echo "Unexpected response from request ${!#}" >&2
    echo "${resp}" >&2
    exit 1
  fi
  echo -n "${resp}"
}


if ! [[ "$1" =~ ^/orgs/[a-z0-9-]+/apps/[a-z0-9-]+/envs/[a-z0-9-]+$ ]] || ! [[ "$2" =~ ^[a-z0-9-]+$ ]]
then
  echo 'USAGE:' >&2
  echo '  ./test.sh FULL_ENV_ID CLONE_TO_ENV_ID' >&2
  echo  >&2
  echo '  FULL_ENV_ID     must be of this form: "/orgs/{orgId}/apps/{appId}/envs/{envId}"' >&2
  echo '  CLONE_TO_ENV_ID must be the ID of an env in the same app.' >&2
  echo >&2
  echo 'EXAMPLE:' >&2
  echo '  ./test.sh /orgs/my-org/apps/my-app/envs/development verified-env' >&2
  echo >&2
  exit 1
fi

# shellcheck disable=2154
if [ -z "${GITHUB_ORG}" ] || [ -z "${GITHUB_PAC}" ] || [ -z "${HUMANITEC_TOKEN}" ]
then
  echo "Expected Environment Variables GITHUB_ORG, GITHUB_PAC and HUMANITEC_TOKEN to be set" >&2
  exit 1
fi

# Extract Org, App and Env IDs from the input parameter
org_id="${1#/orgs/}"
org_id="${org_id%%/*}"

app_id="${1#*/apps/}"
app_id="${app_id%%/*}"

env_id="${1#*/envs/}"
env_id="${env_id%%/*}"

# Fill in the missing details from the Humanitec API
env_obj=$(make_request \
  -H "Authorization: Bearer ${HUMANITEC_TOKEN}" \
  "https://api.humanitec.io${1}")

action_payload=$(echo "${env_obj}" | jq -s \
  --arg org_id "${org_id}" \
  --arg app_id "${app_id}" \
  --arg env_id "${env_id}" \
  --arg clone_to_env_id "${2}" \
'first |
{
  "ref": "main",
  "inputs": {
    "org_id": $org_id,
    "app_id": $app_id,
    "env_id": $env_id,
    "deploy_id": .from_deploy.id,
    "delta_id": .from_deploy.delta_id,
    "set_id": .from_deploy.set_id,
    "status": .from_deploy.status,
    "env_filter": $env_id,
    "clone_to_env_id": "staging"
  }
}
')

# Perform the request that triggers the workflow in GitHub
make_request \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_PAC}" \
  -d "${action_payload}" \
  "https://api.github.com/repos/${GITHUB_ORG}/actions-automation/actions/workflows/autoclone.yaml/dispatches"

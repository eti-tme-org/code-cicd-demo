#!/usr/bin/env bash

export PANOPTICA_REGION="us"
export CODE_CICD_VERSION=1.5.1
export CICD_COMMAND="bin/panoptica-cicd-${CODE_CICD_VERSION}"

ERRORS=0

if ! [ -f "${CICD_COMMAND}" ]; then
    echo "${CICD_COMMAND} not found"
    ERRORS=1
fi

if [ -z "${PANOPTICA_API_KEY}" ]; then
    echo "PANOPTICA_API_KEY not set"
    ERRORS=1
fi

# if [ -z "${PANOPTICA_CLI_ACCESS_KEY}" ]; then
#     echo "PANOPTICA_CLI_ACCESS_KEY not set"
#     ERRORS=1
# fi

# if [ -z "${PANOPTICA_CLI_SECRET_KEY}" ]; then
#     echo "PANOPTICA_CLI_SECRET_KEY not set"
#     ERRORS=1
# fi

if [ "${ERRORS}" -eq "0" ]; then
    echo "Panoptica CI/CD CLI Setup Successful"
fi

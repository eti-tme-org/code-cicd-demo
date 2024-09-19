#/usr/bin/env bash
# NOTE: Source this file, don't execute it.

# for keyname in PANOPTICA_CLI_ACCESS_KEY PANOPTICA_CLI_SECRET_KEY; do
for keyname in PANOPTICA_API_KEY; do
    hcp vault-secrets secrets open ${keyname} 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Key ${keyname} could not be loaded from HCP"
    fi

    export ${keyname}=$(hcp vault-secrets secrets open ${keyname} --format=json | jq -r '.static_version.value')
done

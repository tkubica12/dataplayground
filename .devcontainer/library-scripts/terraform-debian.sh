#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/terraform.md
# Maintainer: The VS Code and Codespaces Teams
#
# Syntax: ./terraform-debian.sh [terraform version]

TERRAFORM_VERSION=${1:-"latest"}

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Install curl, unzip if missing
if ! dpkg -s curl ca-certificates unzip > /dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        apt-get update
    fi
    apt-get -y install --no-install-recommends curl ca-certificates unzip
fi


if [ "${TERRAFORM_VERSION}" = "latest" ] || [ "${TERRAFORM_VERSION}" = "lts" ] || [ "${TERRAFORM_VERSION}" = "current" ]; then
    TERRAFORM_VERSION=$(curl -sSL https://releases.hashicorp.com/terraform/ | grep -m1 -oE '>terraform_[0-9]+\.[0-9]+\.[0-9]+<' | sed 's/^>terraform_\(.*\)<$/\1/')
fi

# Install Terraform
echo "Downloading terraform..."
mkdir -p /tmp/tf-downloads
curl -sSL -o /tmp/tf-downloads/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip /tmp/tf-downloads/terraform.zip
mv -f terraform /usr/local/bin/

rm -rf /tmp/tf-downloads
echo "Done!"

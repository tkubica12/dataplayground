# You can pick any Debian/Ubuntu-based image. 😊
FROM mcr.microsoft.com/vscode/devcontainers/base:0-buster

ENV TF_VERSION 1.3.1
ENV PACKER_VERSION 1.8.0

RUN curl -O https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
    && unzip terraform_${TF_VERSION}_linux_amd64.zip -d /usr/bin \
    && rm -f terraform_${TF_VERSION}_linux_amd64.zip \
    && chmod +x /usr/bin/terraform \
    && curl -O https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/bin \
    && rm -f packer_${PACKER_VERSION}_linux_amd64.zip \
    && chmod +x /usr/bin/packer
 
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash



# COPY library-scripts/*.sh /tmp/library-scripts/

# # [Option] Install zsh
# ARG INSTALL_ZSH="true"
# # [Option] Upgrade OS packages to their latest versions
# ARG UPGRADE_PACKAGES="false"

# # Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
# ARG USERNAME=vscode
# ARG USER_UID=1000
# ARG USER_GID=$USER_UID
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \ 
#     && apt-get install -y graphviz \
#     && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# # [Option] Install Azure CLI
# ARG INSTALL_AZURE_CLI="true"
# # [Option] Install Docker CLI
# ARG INSTALL_DOCKER="true"
# # [Option] Install Node.js
# ARG INSTALL_NODE="true"
# ARG NODE_VERSION="lts/*"
# ENV NVM_DIR=/usr/local/share/nvm
# ENV NVM_SYMLINK_CURRENT=true \
#     PATH=${NVM_DIR}/current/bin:${PATH}
# RUN if [ "${INSTALL_AZURE_CLI}" = "true" ]; then bash /tmp/library-scripts/azcli-debian.sh; fi \
#     && if [ "${INSTALL_NODE}" = "true" ]; then bash /tmp/library-scripts/node-debian.sh "${NVM_DIR}" "${NODE_VERSION}" "${USERNAME}"; fi \
#     && if [ "${INSTALL_DOCKER}" = "true" ]; then \
#         bash /tmp/library-scripts/docker-debian.sh "true" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}"; \
#     else \
#         echo '#!/bin/bash\n"$@"' > /usr/local/share/docker-init.sh && chmod +x /usr/local/share/docker-init.sh; \
#     fi \
#     && rm -rf /var/lib/apt/lists/*

# # Install Terraform
# ARG TERRAFORM_VERSION=0.12.16
# RUN bash /tmp/library-scripts/terraform-debian.sh "${TERRAFORM_VERSION}" \
#     && rm -rf /tmp/library-scripts


# ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
# CMD [ "sleep", "infinity" ]

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
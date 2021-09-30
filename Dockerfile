FROM ubuntu:20.04 as builder

# Install general dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
        # Needed for pre-commit in next build stage
        git \
        libpcre2-8-0 \
        # Builder deps
        unzip \
        software-properties-common \
        curl \
        python3 \
        python3-pip && \
    # Upgrade pip for be able get latest Checkov
    python3 -m pip install --upgrade pip && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*

ARG PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION:-latest}
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-latest}

# Install pre-commit
RUN [ ${PRE_COMMIT_VERSION} = "latest" ] && pip3 install --no-cache-dir pre-commit \
    || pip3 install --no-cache-dir pre-commit==${PRE_COMMIT_VERSION}

# Install terraform because pre-commit needs it
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt update && \
    ( \
        [ "$TERRAFORM_VERSION" = "latest" ] && apt install -y terraform \
        || apt install -y terraform=${TERRAFORM_VERSION} \
    ) && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*

#
# Install tools
#
WORKDIR /bin_dir

ARG CHECKOV_VERSION=${CHECKOV_VERSION:-false}
ARG TERRAFORM_DOCS_VERSION=${TERRAFORM_DOCS_VERSION:-false}
ARG TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION:-false}
ARG TERRASCAN_VERSION=${TERRASCAN_VERSION:-false}
ARG TFLINT_VERSION=${TFLINT_VERSION:-false}
ARG TFSEC_VERSION=${TFSEC_VERSION:-false}


# Tricky thing to install all tools by set only one arg.
# In RUN command below used `. /.env` <- this is sourcing vars that
# specified in step below
ARG INSTALL_ALL=${INSTALL_ALL:-false}
RUN if [ "$INSTALL_ALL" != "false" ]; then \
        echo "export CHECKOV_VERSION=latest" >> /.env && \
        echo "export TERRAFORM_DOCS_VERSION=latest" >> /.env && \
        echo "export TERRAGRUNT_VERSION=latest" >> /.env && \
        echo "export TERRASCAN_VERSION=latest" >> /.env && \
        echo "export TFLINT_VERSION=latest" >> /.env && \
        echo "export TFSEC_VERSION=latest" >> /.env \
    ; else \
        touch /.env \
    ; fi


# Checkov
RUN . /.env && \
    if [ "$CHECKOV_VERSION" != "false" ]; then \
    ( \
        [ "$CHECKOV_VERSION" = "latest" ] && pip3 install --no-cache-dir checkov \
        || pip3 install --no-cache-dir checkov==${CHECKOV_VERSION} \
    ) \
    ; fi

# Terraform docs
RUN . /.env && \
    if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then \
    ( \
        TERRAFORM_DOCS_RELEASES="https://api.github.com/repos/terraform-docs/terraform-docs/releases" && \
        [ "$TERRAFORM_DOCS_VERSION" = "latest" ] && curl -L "$(curl -s ${TERRAFORM_DOCS_RELEASES}/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz \
        || curl -L "$(curl -s ${TERRAFORM_DOCS_RELEASES} | grep -o -E "https://.+?v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz")" > terraform-docs.tgz \
    ) && tar -xzf terraform-docs.tgz terraform-docs && rm terraform-docs.tgz && chmod +x terraform-docs \
    ; fi

# Terragrunt
RUN . /.env \
    && if [ "$TERRAGRUNT_VERSION" != "false" ]; then \
    ( \
        TERRAGRUNT_RELEASES="https://api.github.com/repos/gruntwork-io/terragrunt/releases" && \
        [ "$TERRAGRUNT_VERSION" = "latest" ] && curl -L "$(curl -s ${TERRAGRUNT_RELEASES}/latest | grep -o -E -m 1 "https://.+?/terragrunt_linux_amd64")" > terragrunt \
        || curl -L "$(curl -s ${TERRAGRUNT_RELEASES} | grep -o -E -m 1 "https://.+?v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64")" > terragrunt \
    ) && chmod +x terragrunt \
    ; fi


# Terrascan
RUN . /.env && \
    if [ "$TERRASCAN_VERSION" != "false" ]; then \
    ( \
        TERRASCAN_RELEASES="https://api.github.com/repos/accurics/terrascan/releases" && \
        [ "$TERRASCAN_VERSION" = "latest" ] && curl -L "$(curl -s ${TERRASCAN_RELEASES}/latest | grep -o -E -m 1 "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz \
        || curl -L "$(curl -s ${TERRASCAN_RELEASES} | grep -o -E "https://.+?${TERRASCAN_VERSION}_Linux_x86_64.tar.gz")" > terrascan.tar.gz \
    ) && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && \
    ./terrascan init \
    ; fi

# TFLint
RUN . /.env && \
    if [ "$TFLINT_VERSION" != "false" ]; then \
    ( \
        TFLINT_RELEASES="https://api.github.com/repos/terraform-linters/tflint/releases" && \
        [ "$TFLINT_VERSION" = "latest" ] && curl -L "$(curl -s ${TFLINT_RELEASES}/latest | grep -o -E -m 1 "https://.+?_linux_amd64.zip")" > tflint.zip \
        || curl -L "$(curl -s ${TFLINT_RELEASES} | grep -o -E "https://.+?/v${TFLINT_VERSION}/tflint_linux_amd64.zip")" > tflint.zip \
    ) && unzip tflint.zip && rm tflint.zip \
    ; fi

# TFSec
RUN . /.env && \
    if [ "$TFSEC_VERSION" != "false" ]; then \
    ( \
        TFSEC_RELEASES="https://api.github.com/repos/aquasecurity/tfsec/releases" && \
        [ "$TFSEC_VERSION" = "latest" ] && curl -L "$(curl -s ${TFSEC_RELEASES}/latest | grep -o -E -m 1 "https://.+?/tfsec-linux-amd64")" > tfsec \
        || curl -L "$(curl -s ${TFSEC_RELEASES} | grep -o -E -m 1 "https://.+?v${TFSEC_VERSION}/tfsec-linux-amd64")" > tfsec \
    ) && chmod +x tfsec \
    ; fi

# Checking binaries versions and write it to debug file
RUN . /.env && \
    F=tools_versions_info && \
    pre-commit --version >> $F && \
    terraform --version | head -n 1 >> $F && \
    (if [ "$CHECKOV_VERSION"        != "false" ]; then echo "checkov $(checkov --version)" >> $F;     else echo "checkov SKIPPED" >> $F       ; fi) && \
    (if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then ./terraform-docs --version >> $F;              else echo "terraform-docs SKIPPED" >> $F; fi) && \
    (if [ "$TERRAGRUNT_VERSION"     != "false" ]; then ./terragrunt --version >> $F;                  else echo "terragrunt SKIPPED" >> $F    ; fi) && \
    (if [ "$TERRASCAN_VERSION"      != "false" ]; then echo "terrascan $(./terrascan version)" >> $F; else echo "terrascan SKIPPED" >> $F     ; fi) && \
    (if [ "$TFLINT_VERSION"         != "false" ]; then ./tflint --version >> $F;                      else echo "tflint SKIPPED" >> $F        ; fi) && \
    (if [ "$TFSEC_VERSION"          != "false" ]; then echo "tfsec $(./tfsec --version)" >> $F;       else echo "tfsec SKIPPED" >> $F         ; fi) && \
    echo "\n\n" && cat $F && echo "\n\n"

# based on debian:buster-slim
# https://github.com/docker-library/python/blob/master/3.9/buster/slim/Dockerfile
FROM python:3.9-slim-buster

# Python 3.8 (ubuntu 20.04) -> Python3.9 hacks
COPY --from=builder /usr/local/lib/python3.8/dist-packages/ /usr/local/lib/python3.9/site-packages/
COPY --from=builder /usr/lib/python3/dist-packages /usr/local/lib/python3.9/site-packages
RUN mkdir /usr/lib/python3 && \
    ln -s /usr/local/lib/python3.9/site-packages /usr/lib/python3/site-packages && \
    ln -s /usr/local/bin/python3 /usr/bin/python3
# Copy binaries needed for pre-commit
COPY --from=builder /usr/lib/git-core/ /usr/lib/git-core/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 /usr/lib/x86_64-linux-gnu/
# Copy tools
COPY --from=builder \
    /bin_dir/ \
    /usr/bin/terraform \
    /usr/local/bin/checkov* \
    /usr/local/bin/pre-commit \
    /usr/bin/git \
    /usr/bin/git-shell \
        /usr/bin/
# Copy terrascan policies
COPY --from=builder /root/ /root/

ENV PRE_COMMIT_COLOR=${PRE_COMMIT_COLOR:-always}

ENTRYPOINT [ "pre-commit" ]

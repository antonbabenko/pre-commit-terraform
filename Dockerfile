ARG TAG=3.10.1-alpine3.15
FROM python:${TAG} as builder

WORKDIR /bin_dir

RUN apk add --no-cache \
    # Builder deps
    curl=~7 \
    unzip=~6 && \
    # Upgrade pip for be able get latest Checkov
    python3 -m pip install --no-cache-dir --upgrade pip

ARG PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION:-latest}
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-latest}

# Install pre-commit
RUN [ ${PRE_COMMIT_VERSION} = "latest" ] && pip3 install --no-cache-dir pre-commit \
    || pip3 install --no-cache-dir pre-commit==${PRE_COMMIT_VERSION}

# Install terraform because pre-commit needs it
RUN if [ "${TERRAFORM_VERSION}" = "latest" ]; then \
        TERRAFORM_VERSION="$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | grep -o -E -m 1 "[0-9.]+")" \
    ; fi && \
    curl -L "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform.zip && \
    unzip terraform.zip terraform && rm terraform.zip

#
# Install tools
#
ARG CHECKOV_VERSION=${CHECKOV_VERSION:-false}
ARG INFRACOST_VERSION=${INFRACOST_VERSION:-false}
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
        echo "export INFRACOST_VERSION=latest" >> /.env && \
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
        apk add --no-cache gcc=~10 libffi-dev=~3 musl-dev=~1; \
        [ "$CHECKOV_VERSION" = "latest" ] && pip3 install --no-cache-dir checkov \
        || pip3 install --no-cache-dir checkov==${CHECKOV_VERSION}; \
        apk del gcc libffi-dev musl-dev \
    ) \
    ; fi

# infracost
RUN . /.env && \
    if [ "$INFRACOST_VERSION" != "false" ]; then \
    ( \
        INFRACOST_RELEASES="https://api.github.com/repos/infracost/infracost/releases" && \
        [ "$INFRACOST_VERSION" = "latest" ] && curl -L "$(curl -s ${INFRACOST_RELEASES}/latest | grep -o -E -m 1 "https://.+?-linux-amd64.tar.gz")" > infracost.tgz \
        || curl -L "$(curl -s ${INFRACOST_RELEASES} | grep -o -E "https://.+?v${INFRACOST_VERSION}/infracost-linux-amd64.tar.gz")" > infracost.tgz \
    ) && tar -xzf infracost.tgz && rm infracost.tgz && mv infracost-linux-amd64 infracost \
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
    ./terraform --version | head -n 1 >> $F && \
    (if [ "$CHECKOV_VERSION"        != "false" ]; then echo "checkov $(checkov --version)" >> $F;     else echo "checkov SKIPPED" >> $F        ; fi) && \
    (if [ "$INFRACOST_VERSION"      != "false" ]; then echo "$(./infracost --version)" >> $F;         else echo "infracost SKIPPED" >> $F      ; fi) && \
    (if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then ./terraform-docs --version >> $F;              else echo "terraform-docs SKIPPED" >> $F ; fi) && \
    (if [ "$TERRAGRUNT_VERSION"     != "false" ]; then ./terragrunt --version >> $F;                  else echo "terragrunt SKIPPED" >> $F     ; fi) && \
    (if [ "$TERRASCAN_VERSION"      != "false" ]; then echo "terrascan $(./terrascan version)" >> $F; else echo "terrascan SKIPPED" >> $F      ; fi) && \
    (if [ "$TFLINT_VERSION"         != "false" ]; then ./tflint --version >> $F;                      else echo "tflint SKIPPED" >> $F         ; fi) && \
    (if [ "$TFSEC_VERSION"          != "false" ]; then echo "tfsec $(./tfsec --version)" >> $F;       else echo "tfsec SKIPPED" >> $F          ; fi) && \
    echo -e "\n\n" && cat $F && echo -e "\n\n"



FROM python:${TAG}

RUN apk add --no-cache \
    # pre-commit deps
    git=~2 \
    # All hooks deps
    bash=~5

# Copy tools
COPY --from=builder \
    # Needed for all hooks
    /usr/local/bin/pre-commit \
    # Hooks and terraform binaries
    /bin_dir/ \
    /usr/local/bin/checkov* \
        /usr/bin/
# Copy pre-commit packages
COPY --from=builder /usr/local/lib/python3.10/site-packages/ /usr/local/lib/python3.10/site-packages/
# Copy terrascan policies
COPY --from=builder /root/ /root/

# Install hooks extra deps
RUN if [ "$(grep -o '^terraform-docs SKIPPED$' /usr/bin/tools_versions_info)" = "" ]; then \
        apk add --no-cache perl=~5 \
    ; fi && \
    if [ "$(grep -o '^infracost SKIPPED$' /usr/bin/tools_versions_info)" = "" ]; then \
        apk add --no-cache jq=~1 \
    ; fi

ENV PRE_COMMIT_COLOR=${PRE_COMMIT_COLOR:-always}

ENV INFRACOST_API_KEY=${INFRACOST_API_KEY:-}
ENV INFRACOST_SKIP_UPDATE_CHECK=${INFRACOST_SKIP_UPDATE_CHECK:-false}

ENTRYPOINT [ "pre-commit" ]

ARG TAG=3.12.0-alpine3.17@sha256:fc34b07ec97a4f288bc17083d288374a803dd59800399c76b977016c9fe5b8f2
FROM python:${TAG} as builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /bin_dir

RUN apk add --no-cache \
    # Builder deps
    bash=~5 \
    curl=~8 && \
    # Upgrade packages for be able get latest Checkov
    python3 -m pip install --no-cache-dir --upgrade \
        pip \
        setuptools

COPY tools/install/ /install/

#
# Install required tools
#
ARG PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION:-latest}
RUN touch /.env && \
    if [ "$PRE_COMMIT_VERSION" = "false" ]; then \
        echo "Vital software can't be skipped" && exit 1; \
    fi
RUN /install/pre-commit.sh

#
# Install tools
#
ARG OPENTOFU_VERSION=${OPENTOFU_VERSION:-false}
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-false}

ARG CHECKOV_VERSION=${CHECKOV_VERSION:-false}
ARG HCLEDIT_VERSION=${HCLEDIT_VERSION:-false}
ARG INFRACOST_VERSION=${INFRACOST_VERSION:-false}
ARG TERRAFORM_DOCS_VERSION=${TERRAFORM_DOCS_VERSION:-false}
ARG TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION:-false}
ARG TERRASCAN_VERSION=${TERRASCAN_VERSION:-false}
ARG TFLINT_VERSION=${TFLINT_VERSION:-false}
ARG TFSEC_VERSION=${TFSEC_VERSION:-false}
ARG TFUPDATE_VERSION=${TFUPDATE_VERSION:-false}
ARG TRIVY_VERSION=${TRIVY_VERSION:-false}


# Tricky thing to install all tools by set only one arg.
# In RUN command below used `. /.env` <- this is sourcing vars that
# specified in step below
ARG INSTALL_ALL=${INSTALL_ALL:-false}
RUN if [ "$INSTALL_ALL" != "false" ]; then \
        echo "OPENTOFU_VERSION=latest"       >> /.env && \
        echo "TERRAFORM_VERSION=latest"      >> /.env && \
        \
        echo "CHECKOV_VERSION=latest"        >> /.env && \
        echo "HCLEDIT_VERSION=latest"        >> /.env && \
        echo "INFRACOST_VERSION=latest"      >> /.env && \
        echo "TERRAFORM_DOCS_VERSION=latest" >> /.env && \
        echo "TERRAGRUNT_VERSION=latest"     >> /.env && \
        echo "TERRASCAN_VERSION=latest"      >> /.env && \
        echo "TFLINT_VERSION=latest"         >> /.env && \
        echo "TFSEC_VERSION=latest"          >> /.env && \
        echo "TFUPDATE_VERSION=latest"       >> /.env && \
        echo "TRIVY_VERSION=latest"          >> /.env \
    ; fi

RUN /install/opentofu.sh
RUN /install/terraform.sh

RUN /install/checkov.sh
RUN /install/hcledit.sh
RUN /install/infracost.sh
RUN /install/terraform-docs.sh
RUN /install/terragrunt.sh
RUN /install/terrascan.sh
RUN /install/tflint.sh
RUN /install/tfsec.sh
RUN /install/tfupdate.sh
RUN /install/trivy.sh


# Checking binaries versions and write it to debug file
RUN . /.env && \
    F=tools_versions_info && \
    pre-commit --version >> $F && \
    (if [ "$OPENTOFU_VERSION"       != "false" ]; then echo "./tofu --version | head -n 1" >> $F;      else echo "opentofu SKIPPED" >> $F      ; fi) && \
    (if [ "$TERRAFORM_VERSION"      != "false" ]; then echo "./terraform --version | head -n 1" >> $F; else echo "terraform SKIPPED" >> $F     ; fi) && \
    \
    (if [ "$CHECKOV_VERSION"        != "false" ]; then echo "checkov $(checkov --version)" >> $F;     else echo "checkov SKIPPED" >> $F        ; fi) && \
    (if [ "$HCLEDIT_VERSION"        != "false" ]; then echo "hcledit $(./hcledit version)" >> $F;     else echo "hcledit SKIPPED" >> $F        ; fi) && \
    (if [ "$INFRACOST_VERSION"      != "false" ]; then echo "$(./infracost --version)" >> $F;         else echo "infracost SKIPPED" >> $F      ; fi) && \
    (if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then ./terraform-docs --version >> $F;              else echo "terraform-docs SKIPPED" >> $F ; fi) && \
    (if [ "$TERRAGRUNT_VERSION"     != "false" ]; then ./terragrunt --version >> $F;                  else echo "terragrunt SKIPPED" >> $F     ; fi) && \
    (if [ "$TERRASCAN_VERSION"      != "false" ]; then echo "terrascan $(./terrascan version)" >> $F; else echo "terrascan SKIPPED" >> $F      ; fi) && \
    (if [ "$TFLINT_VERSION"         != "false" ]; then ./tflint --version >> $F;                      else echo "tflint SKIPPED" >> $F         ; fi) && \
    (if [ "$TFSEC_VERSION"          != "false" ]; then echo "tfsec $(./tfsec --version)" >> $F;       else echo "tfsec SKIPPED" >> $F          ; fi) && \
    (if [ "$TFUPDATE_VERSION"       != "false" ]; then echo "tfupdate $(./tfupdate --version)" >> $F; else echo "tfupdate SKIPPED" >> $F       ; fi) && \
    (if [ "$TRIVY_VERSION"          != "false" ]; then echo "trivy $(./trivy --version)" >> $F;       else echo "trivy SKIPPED" >> $F          ; fi) && \
    echo -e "\n\n" && cat $F && echo -e "\n\n"



FROM python:${TAG}

RUN apk add --no-cache \
    # pre-commit deps
    git=~2 \
    # All hooks deps
    bash=~5 \
    # pre-commit-hooks deps: https://github.com/pre-commit/pre-commit-hooks
    musl-dev=~1 \
    gcc=~12 \
    # entrypoint wrapper deps
    su-exec=~0.2 \
    # ssh-client for external private module in ssh
    openssh-client=~9

# Copy tools
COPY --from=builder \
    # Needed for all hooks
    /usr/local/bin/pre-commit \
    # Hooks and terraform binaries
    /bin_dir/ \
    /usr/local/bin/checkov* \
        /usr/bin/
# Copy pre-commit packages
COPY --from=builder /usr/local/lib/python3.12/site-packages/ /usr/local/lib/python3.12/site-packages/
# Copy terrascan policies
COPY --from=builder /root/ /root/

# Install hooks extra deps
RUN if [ "$(grep -o '^terraform-docs SKIPPED$' /usr/bin/tools_versions_info)" = "" ]; then \
        apk add --no-cache perl=~5 \
    ; fi && \
    if [ "$(grep -o '^infracost SKIPPED$' /usr/bin/tools_versions_info)" = "" ]; then \
        apk add --no-cache jq=~1 \
    ; fi && \
    # Fix git runtime fatal:
    # unsafe repository ('/lint' is owned by someone else)
    git config --global --add safe.directory /lint

COPY tools/entrypoint.sh /entrypoint.sh

ENV PRE_COMMIT_COLOR=${PRE_COMMIT_COLOR:-always}

ENV INFRACOST_API_KEY=${INFRACOST_API_KEY:-}
ENV INFRACOST_SKIP_UPDATE_CHECK=${INFRACOST_SKIP_UPDATE_CHECK:-false}

ENTRYPOINT [ "/entrypoint.sh" ]

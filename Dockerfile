ARG TAG=3.12.0-alpine3.17@sha256:fc34b07ec97a4f288bc17083d288374a803dd59800399c76b977016c9fe5b8f2
FROM python:${TAG} as builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /bin_dir

RUN apk add --no-cache \
    # Builder deps
    curl=~8 && \
    # Upgrade packages for be able get latest Checkov
    python3 -m pip install --no-cache-dir --upgrade \
        pip \
        setuptools

ARG PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION:-latest}
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-latest}

# Install pre-commit
RUN if [ ${PRE_COMMIT_VERSION} = "latest" ]; \
        then pip3 install --no-cache-dir pre-commit; \
        else pip3 install --no-cache-dir pre-commit==${PRE_COMMIT_VERSION}; \
    fi

# Install terraform because pre-commit needs it
RUN if [ "${TERRAFORM_VERSION}" = "latest" ]; then \
        TERRAFORM_VERSION="$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | grep -o -E -m 1 "[0-9.]+")" \
    ; fi && \
    curl -L "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TARGETOS}_${TARGETARCH}.zip" > terraform.zip && \
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
ARG TRIVY_VERSION=${TRIVY_VERSION:-false}
ARG TFUPDATE_VERSION=${TFUPDATE_VERSION:-false}
ARG HCLEDIT_VERSION=${HCLEDIT_VERSION:-false}


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
        echo "export TFSEC_VERSION=latest" >> /.env && \
        echo "export TRIVY_VERSION=latest" >> /.env && \
        echo "export TFUPDATE_VERSION=latest" >> /.env && \
        echo "export HCLEDIT_VERSION=latest" >> /.env \
    ; else \
        touch /.env \
    ; fi


# Checkov
RUN . /.env && \
    if [ "$CHECKOV_VERSION" != "false" ]; then \
    ( \
        # cargo, gcc, git, musl-dev, rust and CARGO envvar required for compilation of rustworkx@0.13.2, no longer required once checkov version depends on rustworkx >0.14.0
        # gcc libffi-dev musl-dev required for compilation of cffi, until it contains musl aarch64
        export CARGO_NET_GIT_FETCH_WITH_CLI=true && \
        apk add --no-cache cargo=~1 gcc=~12 git=~2 libffi-dev=~3 libgcc=~12 musl-dev=~1 rust=~1 ; \
        if [ "$CHECKOV_VERSION" = "latest" ]; \
            then pip3 install --no-cache-dir checkov || exit 1; \
            else pip3 install --no-cache-dir checkov==${CHECKOV_VERSION} || exit 1; \
        fi; \
        apk del cargo gcc git libffi-dev musl-dev rust \
    ) \
    ; fi

# infracost
RUN . /.env && \
    if [ "$INFRACOST_VERSION" != "false" ]; then \
    ( \
        INFRACOST_RELEASES="https://api.github.com/repos/infracost/infracost/releases" && \
        if [ "$INFRACOST_VERSION" = "latest" ]; \
            then curl -L "$(curl -s ${INFRACOST_RELEASES}/latest | grep -o -E -m 1 "https://.+?-${TARGETOS}-${TARGETARCH}.tar.gz")" > infracost.tgz; \
            else curl -L "$(curl -s ${INFRACOST_RELEASES} | grep -o -E "https://.+?v${INFRACOST_VERSION}/infracost-${TARGETOS}-${TARGETARCH}.tar.gz")" > infracost.tgz; \
        fi; \
    ) && tar -xzf infracost.tgz && rm infracost.tgz && mv infracost-${TARGETOS}-${TARGETARCH} infracost \
    ; fi

# Terraform docs
RUN . /.env && \
    if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then \
    ( \
        TERRAFORM_DOCS_RELEASES="https://api.github.com/repos/terraform-docs/terraform-docs/releases" && \
        if [ "$TERRAFORM_DOCS_VERSION" = "latest" ]; \
            then curl -L "$(curl -s ${TERRAFORM_DOCS_RELEASES}/latest | grep -o -E -m 1 "https://.+?-${TARGETOS}-${TARGETARCH}.tar.gz")" > terraform-docs.tgz; \
            else curl -L "$(curl -s ${TERRAFORM_DOCS_RELEASES} | grep -o -E "https://.+?v${TERRAFORM_DOCS_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz")" > terraform-docs.tgz; \
        fi; \
    ) && tar -xzf terraform-docs.tgz terraform-docs && rm terraform-docs.tgz && chmod +x terraform-docs \
    ; fi

# Terragrunt
RUN . /.env \
    && if [ "$TERRAGRUNT_VERSION" != "false" ]; then \
    ( \
        TERRAGRUNT_RELEASES="https://api.github.com/repos/gruntwork-io/terragrunt/releases" && \
        if [ "$TERRAGRUNT_VERSION" = "latest" ]; \
            then curl -L "$(curl -s ${TERRAGRUNT_RELEASES}/latest | grep -o -E -m 1 "https://.+?/terragrunt_${TARGETOS}_${TARGETARCH}")" > terragrunt; \
            else curl -L "$(curl -s ${TERRAGRUNT_RELEASES} | grep -o -E -m 1 "https://.+?v${TERRAGRUNT_VERSION}/terragrunt_${TARGETOS}_${TARGETARCH}")" > terragrunt; \
        fi; \
    ) && chmod +x terragrunt \
    ; fi


# Terrascan
RUN . /.env && \
    if [ "$TERRASCAN_VERSION" != "false" ]; then \
    if [ "$TARGETARCH" != "amd64" ]; then ARCH="$TARGETARCH"; else ARCH="x86_64"; fi; \
    # Convert the first letter to Uppercase
    OS="$(echo ${TARGETOS} | cut -c1 | tr '[:lower:]' '[:upper:]' | xargs echo -n; echo ${TARGETOS} | cut -c2-)"; \
    ( \
        TERRASCAN_RELEASES="https://api.github.com/repos/tenable/terrascan/releases" && \
        if [ "$TERRASCAN_VERSION" = "latest" ]; \
            then curl -L "$(curl -s ${TERRASCAN_RELEASES}/latest | grep -o -E -m 1 "https://.+?_${OS}_${ARCH}.tar.gz")" > terrascan.tar.gz; \
            else curl -L "$(curl -s ${TERRASCAN_RELEASES} | grep -o -E "https://.+?${TERRASCAN_VERSION}_${OS}_${ARCH}.tar.gz")" > terrascan.tar.gz; \
        fi; \
    ) && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && \
    ./terrascan init \
    ; fi

# TFLint
RUN . /.env && \
    if [ "$TFLINT_VERSION" != "false" ]; then \
    ( \
        TFLINT_RELEASES="https://api.github.com/repos/terraform-linters/tflint/releases" && \
        if [ "$TFLINT_VERSION" = "latest" ]; \
            then curl -L "$(curl -s ${TFLINT_RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.zip")" > tflint.zip; \
            else curl -L "$(curl -s ${TFLINT_RELEASES} | grep -o -E "https://.+?/v${TFLINT_VERSION}/tflint_${TARGETOS}_${TARGETARCH}.zip")" > tflint.zip; \
        fi; \
    ) && unzip tflint.zip && rm tflint.zip \
    ; fi

# TFSec
RUN . /.env && \
    if [ "$TFSEC_VERSION" != "false" ]; then \
    ( \
        TFSEC_RELEASES="https://api.github.com/repos/aquasecurity/tfsec/releases" && \
        if [ "$TFSEC_VERSION" = "latest" ]; then \
            curl -L "$(curl -s ${TFSEC_RELEASES}/latest | grep -o -E -m 1 "https://.+?/tfsec-${TARGETOS}-${TARGETARCH}")" > tfsec; \
            else curl -L "$(curl -s ${TFSEC_RELEASES} | grep -o -E -m 1 "https://.+?v${TFSEC_VERSION}/tfsec-${TARGETOS}-${TARGETARCH}")" > tfsec; \
        fi; \
    ) && chmod +x tfsec \
    ; fi

# Trivy
RUN . /.env && \
    if [ "$TRIVY_VERSION" != "false" ]; then \
    if [ "$TARGETARCH" != "amd64" ]; then ARCH="$TARGETARCH"; else ARCH="64bit"; fi; \
    ( \
        TRIVY_RELEASES="https://api.github.com/repos/aquasecurity/trivy/releases" && \
        if [ "$TRIVY_VERSION" = "latest" ]; \
            then curl -L "$(curl -s ${TRIVY_RELEASES}/latest | grep -o -E -i -m 1 "https://.+?/trivy_.+?_${TARGETOS}-${ARCH}.tar.gz")" > trivy.tar.gz; \
            else curl -L "$(curl -s ${TRIVY_RELEASES} | grep -o -E -i -m 1 "https://.+?/v${TRIVY_VERSION}/trivy_.+?_${TARGETOS}-${ARCH}.tar.gz")" > trivy.tar.gz; \
        fi; \
    ) && tar -xzf trivy.tar.gz trivy && rm trivy.tar.gz \
    ; fi

# TFUpdate
RUN . /.env && \
    if [ "$TFUPDATE_VERSION" != "false" ]; then \
    ( \
        TFUPDATE_RELEASES="https://api.github.com/repos/minamijoyo/tfupdate/releases" && \
        if [ "$TFUPDATE_VERSION" = "latest" ]; \
            then curl -L "$(curl -s ${TFUPDATE_RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.tar.gz")" > tfupdate.tgz; \
            else curl -L "$(curl -s ${TFUPDATE_RELEASES} | grep -o -E -m 1 "https://.+?${TFUPDATE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz")" > tfupdate.tgz; \
        fi; \
    ) && tar -xzf tfupdate.tgz tfupdate && rm tfupdate.tgz \
    ; fi

# hcledit
RUN . /.env && \
    if [ "$HCLEDIT_VERSION" != "false" ]; then \
    ( \
        HCLEDIT_RELEASES="https://api.github.com/repos/minamijoyo/hcledit/releases" && \
        if [ "$HCLEDIT_VERSION" = "latest" ]; \
            then curl -L "$(curl -s ${HCLEDIT_RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.tar.gz")" > hcledit.tgz; \
            else curl -L "$(curl -s ${HCLEDIT_RELEASES} | grep -o -E -m 1 "https://.+?${HCLEDIT_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz")" > hcledit.tgz; \
        fi; \
    ) && tar -xzf hcledit.tgz hcledit && rm hcledit.tgz \
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
    (if [ "$TRIVY_VERSION"          != "false" ]; then echo "trivy $(./trivy --version)" >> $F;       else echo "trivy SKIPPED" >> $F          ; fi) && \
    (if [ "$TFUPDATE_VERSION"       != "false" ]; then echo "tfupdate $(./tfupdate --version)" >> $F; else echo "tfupdate SKIPPED" >> $F       ; fi) && \
    (if [ "$HCLEDIT_VERSION"        != "false" ]; then echo "hcledit $(./hcledit version)" >> $F;     else echo "hcledit SKIPPED" >> $F       ; fi) && \
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

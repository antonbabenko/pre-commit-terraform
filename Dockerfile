ARG TAG=3.10.1-alpine3.15
FROM python:${TAG} as builder

ARG PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION:-latest}
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-latest}
ARG CHECKOV_VERSION=${CHECKOV_VERSION:-false}
ARG INFRACOST_VERSION=${INFRACOST_VERSION:-false}
ARG TERRAFORM_DOCS_VERSION=${TERRAFORM_DOCS_VERSION:-false}
ARG TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION:-false}
ARG TERRASCAN_VERSION=${TERRASCAN_VERSION:-false}
ARG TFLINT_VERSION=${TFLINT_VERSION:-false}
ARG TFSEC_VERSION=${TFSEC_VERSION:-false}
ARG INSTALL_ALL=${INSTALL_ALL:-false}

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk add --no-cache gcc libc-dev linux-headers git curl jq libffi-dev

# setup runtime venv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv --system-site-packages $VIRTUAL_ENV
ENV OLD_PATH=$PATH
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m pip install --no-cache-dir --upgrade pip

# pre-commit
COPY ./docker-scripts/install_pre-commit.sh /docker-scripts/install_pre-commit.sh
RUN /docker-scripts/install_pre-commit.sh

# Tricky thing to install all tools by set only one arg.
# In RUN command below used `. /.env` <- this is sourcing vars that
# specified in step below
COPY ./docker-scripts/populate-env-arch.sh /docker-scripts/populate-env-arch.sh
RUN /docker-scripts/populate-env-arch.sh

# Terraform
COPY ./docker-scripts/install_terraform.sh /docker-scripts/install_terraform.sh
RUN /docker-scripts/install_terraform.sh

COPY ./docker-scripts/populate-env-versions.sh /docker-scripts/populate-env-versions.sh
RUN /docker-scripts/populate-env-versions.sh

# PyPI

# Checkov
COPY ./docker-scripts/install_checkov.sh /docker-scripts/install_checkov.sh
RUN /docker-scripts/install_checkov.sh

# GitHub

COPY ./docker-scripts/install-from-github.sh /docker-scripts/install-from-github.sh

# infracost
COPY ./docker-scripts/install_infracost.sh /docker-scripts/install_infracost.sh
RUN /docker-scripts/install_infracost.sh

# Terraform docs
COPY ./docker-scripts/install_terraform-docs.sh /docker-scripts/install_terraform-docs.sh
RUN /docker-scripts/install_terraform-docs.sh

# Terragrunt
COPY ./docker-scripts/install_terragrunt.sh /docker-scripts/install_terragrunt.sh
RUN /docker-scripts/install_terragrunt.sh

# Terrascan
COPY ./docker-scripts/install_terrascan.sh /docker-scripts/install_terrascan.sh
RUN /docker-scripts/install_terrascan.sh

# TFLint
COPY ./docker-scripts/install_tflint.sh /docker-scripts/install_tflint.sh
RUN /docker-scripts/install_tflint.sh

# TFSec
COPY ./docker-scripts/install_tfsec.sh /docker-scripts/install_tfsec.sh
RUN /docker-scripts/install_tfsec.sh

# setup build venv
ENV VIRTUAL_ENV=/opt/build-venv
ENV PATH="$OLD_PATH"
RUN python3 -m venv --system-site-packages $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# install build tools
RUN python3 -m pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir --upgrade setuptools wheel build

# build
COPY . /src/
WORKDIR /src
RUN python3 -m build --wheel

# switch back to runtime venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$OLD_PATH"

# install package
RUN pip install --no-cache-dir --disable-pip-version-check ./dist/*.whl
WORKDIR /

# Checking binaries versions and write it to debug file
COPY ./docker-scripts/write-version-file.sh /docker-scripts/write-version-file.sh
RUN /docker-scripts/write-version-file.sh

# runtime image
FROM python:${TAG}

ENV PYTHONUNBUFFERED=1

RUN apk add --no-cache \
    # pre-commit deps
    git \
    # All hooks deps
    bash

# copy venv
ENV VIRTUAL_ENV=/opt/venv
COPY --from=builder /opt/venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy terrascan policies
COPY --from=builder /root/.terrascan/pkg/policies/opa/rego /root/.terrascan/pkg/policies/opa/rego

ENV PRE_COMMIT_COLOR=${PRE_COMMIT_COLOR:-always}

ENV INFRACOST_API_KEY=${INFRACOST_API_KEY:-}
ENV INFRACOST_SKIP_UPDATE_CHECK=${INFRACOST_SKIP_UPDATE_CHECK:-false}

ENTRYPOINT [ "pre-commit" ]

FROM ubuntu:18.04

ARG PRE_COMMIT_VERSION="2.11.1"
ARG TERRAFORM_VERSION="0.15.0"
ARG TFSEC_VERSION="latest" 
ARG TERRAFORM_DOCS_VERSION="latest"
ARG TFLINT_VERSION="latest"
ARG CHECKOV_VERSION="1.0.838"

# Install general dependencies
RUN apt update && \
    apt install -y curl git gawk unzip software-properties-common

# Install tools
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt install -y python3.7 python3-pip && \
    pip3 install pre-commit==${PRE_COMMIT_VERSION} && \
    curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/${TERRAFORM_DOCS_VERSION} | grep -o -E "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz && tar xzf terraform-docs.tgz && chmod +x terraform-docs && mv terraform-docs /usr/bin/ && \
    curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/${TFLINT_VERSION} | grep -o -E "https://.+?_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && mv tflint /usr/bin/ && \
    curl -L "$(curl -s https://api.github.com/repos/tfsec/tfsec/releases/${TFSEC_VERSION} | grep -o -E "https://.+?tfsec-linux-amd64")" > tfsec && chmod +x tfsec && mv tfsec /usr/bin/ && \
    python3.7 -m pip install -U checkov==${CHECKOV_VERSION}

# Install terraform because pre-commit needs it
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && apt-get install terraform=${TERRAFORM_VERSION}

# Checking all binaries are in the PATH
RUN terraform --help
RUN pre-commit --help
RUN terraform-docs --help
RUN tflint --help
RUN tfsec --help
RUN checkov --help

ENTRYPOINT [ "pre-commit" ]
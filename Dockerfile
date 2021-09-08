FROM ubuntu:20.04

ARG PRE_COMMIT_VERSION="2.11.1"
ARG TERRAFORM_VERSION="0.15.0"
ARG TFSEC_VERSION="v0.58.6"
ARG TERRAFORM_DOCS_VERSION="v0.12.0"
ARG TFLINT_VERSION="v0.27.0"
ARG CHECKOV_VERSION="1.0.838"
ARG TERRASCAN_VERSION="1.10.0"

# Install general dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
        gawk \
        unzip \
        software-properties-common \
        curl \
        python3 \
        python3-pip && \
    # Upgrade pip for be able get latest Checkov
    python3 -m pip install --upgrade pip && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*

# Install pre-commit
RUN pip3 install pre-commit==${PRE_COMMIT_VERSION}

# Install tools
WORKDIR /tmp
RUN \
    curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases | grep -o -E "https://.+?${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz")" > terraform-docs.tgz && tar xzf terraform-docs.tgz && chmod +x terraform-docs && mv terraform-docs /usr/bin/ && \
    curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases | grep -o -E "https://.+?/${TFLINT_VERSION}/tflint_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && mv tflint /usr/bin/ && \
    curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases | grep -o -E "https://.+?${TFSEC_VERSION}/tfsec-linux-amd64" | head -n 1)" > tfsec && chmod +x tfsec && mv tfsec /usr/bin/ && \
    curl -L "$(curl -s https://api.github.com/repos/accurics/terrascan/releases | grep -o -E "https://.+?${TERRASCAN_VERSION}_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xf terrascan.tar.gz terrascan && rm terrascan.tar.gz && mv terrascan /usr/bin/ && \
    pip3 install -U checkov==${CHECKOV_VERSION} && \
    # Cleanup
    rm -rf *

# Install terraform because pre-commit needs it
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt update && \
    apt install -y terraform=${TERRAFORM_VERSION} && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*

# Checking all binaries are in the PATH
RUN terraform --help
RUN pre-commit --help
RUN terraform-docs --help
RUN tflint --help
RUN tfsec --help
RUN checkov --help
RUN terrascan --help

ENTRYPOINT [ "pre-commit" ]

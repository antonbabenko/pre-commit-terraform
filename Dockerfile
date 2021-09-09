FROM ubuntu:20.04

ARG PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION:-2.11.1}
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-0.15.0}
ARG TFSEC_VERSION=${TFSEC_VERSION:-0.58.6}
ARG TERRAFORM_DOCS_VERSION=${TERRAFORM_DOCS_VERSION:-0.12.0}
ARG TFLINT_VERSION=${TFLINT_VERSION:-0.27.0}
ARG CHECKOV_VERSION=${CHECKOV_VERSION:-1.0.838}
ARG TERRASCAN_VERSION=${TERRASCAN_VERSION:-1.10.0}

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
RUN pip3 install --no-cache-dir pre-commit==${PRE_COMMIT_VERSION}

# Install tools
RUN \
    curl -L "$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases | grep -o -E "https://.+?v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz")" > terraform-docs.tgz && tar -xzf terraform-docs.tgz terraform-docs && chmod +x terraform-docs && mv terraform-docs /usr/bin/ && \
    curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases | grep -o -E "https://.+?/v${TFLINT_VERSION}/tflint_linux_amd64.zip")" > tflint.zip && unzip tflint.zip && rm tflint.zip && mv tflint /usr/bin/ && \
    curl -L "$(curl -s https://api.github.com/repos/aquasecurity/tfsec/releases | grep -o -E "https://.+?v${TFSEC_VERSION}/tfsec-linux-amd64" | head -n 1)" > tfsec && chmod +x tfsec && mv tfsec /usr/bin/ && \
    curl -L "$(curl -s https://api.github.com/repos/accurics/terrascan/releases | grep -o -E "https://.+?${TERRASCAN_VERSION}_Linux_x86_64.tar.gz")" > terrascan.tar.gz && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && mv terrascan /usr/bin/ && \
    pip3 install --no-cache-dir checkov==${CHECKOV_VERSION}

# Install terraform because pre-commit needs it
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt update && \
    apt install -y terraform=${TERRAFORM_VERSION} && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*

# Checking that all binaries are in the PATH and show their versions
RUN echo "\n\n" && \
    pre-commit --version && \
    terraform --version | head -n 1 && \
    terraform-docs --version && \
    tflint --version && \
    echo -n "tfsec " && tfsec --version && \
    echo -n "checkov " && checkov --version && \
    echo -n "terrascan " && terrascan version && \
    echo "\n\n"

ENTRYPOINT [ "pre-commit" ]

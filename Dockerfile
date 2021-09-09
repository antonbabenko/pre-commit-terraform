FROM ubuntu:20.04

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

ARG PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION:-2.11.1}
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-0.15.0}

ARG CHECKOV_VERSION=${CHECKOV_VERSION:-1.0.838}
ARG TERRAFORM_DOCS_VERSION=${TERRAFORM_DOCS_VERSION:-0.12.0}
ARG TERRASCAN_VERSION=${TERRASCAN_VERSION:-1.10.0}
ARG TFLINT_VERSION=${TFLINT_VERSION:-0.27.0}
ARG TFSEC_VERSION=${TFSEC_VERSION:-0.58.6}

# Install pre-commit
RUN [ ${PRE_COMMIT_VERSION} = "latest" ] && pip3 install --no-cache-dir pre-commit \
    || pip3 install --no-cache-dir pre-commit==${PRE_COMMIT_VERSION}

# Install tools
RUN \
    # Checkov
    ( \
        [ ${CHECKOV_VERSION} = "latest" ] && pip3 install --no-cache-dir checkov \
        || pip3 install --no-cache-dir checkov==${CHECKOV_VERSION} \
    ) && \
    # Terraform docs
    ( \
        TERRAFORM_DOCS_RELEASES="https://api.github.com/repos/terraform-docs/terraform-docs/releases" && \
        [ ${TERRAFORM_DOCS_VERSION} = "latest" ] && curl -L "$(curl -s ${TERRAFORM_DOCS_RELEASES}/latest | grep -o -E "https://.+?-linux-amd64.tar.gz")" > terraform-docs.tgz \
        || curl -L "$(curl -s ${TERRAFORM_DOCS_RELEASES} | grep -o -E "https://.+?v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz")" > terraform-docs.tgz \
    ) && tar -xzf terraform-docs.tgz terraform-docs && chmod +x terraform-docs && mv terraform-docs /usr/bin/ && \
    # Terrascan
    ( \
        TERRASCAN_RELEASES="https://api.github.com/repos/accurics/terrascan/releases" && \
        [ ${TERRASCAN_VERSION} = "latest" ] && curl -L "$(curl -s ${TERRASCAN_RELEASES}/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz \
        || curl -L "$(curl -s ${TERRASCAN_RELEASES} | grep -o -E "https://.+?${TERRASCAN_VERSION}_Linux_x86_64.tar.gz")" > terrascan.tar.gz \
    ) && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && mv terrascan /usr/bin/ && \
    # TFLint
    ( \
        TFLINT_RELEASES="https://api.github.com/repos/terraform-linters/tflint/releases" && \
        [ ${TFLINT_VERSION} = "latest" ] && curl -L "$(curl -s ${TFLINT_RELEASES}/latest | grep -o -E "https://.+?_linux_amd64.zip")" > tflint.zip \
        || curl -L "$(curl -s ${TFLINT_RELEASES} | grep -o -E "https://.+?/v${TFLINT_VERSION}/tflint_linux_amd64.zip")" > tflint.zip \
    ) && unzip tflint.zip && rm tflint.zip && mv tflint /usr/bin/ && \
    # TFSec
    ( \
        TFSEC_RELEASES="https://api.github.com/repos/aquasecurity/tfsec/releases" && \
        [ ${TFSEC_VERSION} = "latest" ] && curl -L "$(curl -s ${TFSEC_RELEASES}/latest | grep -o -E "https://.+?/tfsec-linux-amd64" | head -n 1)" > tfsec \
        || curl -L "$(curl -s ${TFSEC_RELEASES} | grep -o -E "https://.+?v${TFSEC_VERSION}/tfsec-linux-amd64" | head -n 1)" > tfsec \
    ) && chmod +x tfsec && mv tfsec /usr/bin/

# Install terraform because pre-commit needs it
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt update && \
    ( \
        [ ${TERRAFORM_VERSION} = "latest" ] && apt install -y terraform \
        || apt install -y terraform=${TERRAFORM_VERSION} \
    ) && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*

# Checking that all binaries are in the PATH and show their versions
RUN echo "\n\n" && \
    pre-commit --version && \
    terraform --version | head -n 1 && \
    echo -n "checkov " && checkov --version && \
    echo -n "terrascan " && terrascan version && \
    echo -n "tfsec " && tfsec --version && \
    terraform-docs --version && \
    tflint --version && \
    echo "\n\n"

ENTRYPOINT [ "pre-commit" ]

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

ARG PRE_COMMIT_VERSION=${PRE_COMMIT_VERSION:-2.15.0}
ARG TERRAFORM_VERSION=${TERRAFORM_VERSION:-1.0.6}

ARG CHECKOV_VERSION=${CHECKOV_VERSION:-2.0.405}
ARG TERRAFORM_DOCS_VERSION=${TERRAFORM_DOCS_VERSION:-0.15.0}
ARG TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION:-0.31.10}
ARG TERRASCAN_VERSION=${TERRASCAN_VERSION:-1.10.0}
ARG TFLINT_VERSION=${TFLINT_VERSION:-0.31.0}
ARG TFSEC_VERSION=${TFSEC_VERSION:-0.58.6}

# Install pre-commit
RUN [ ${PRE_COMMIT_VERSION} = "latest" ] && pip3 install --no-cache-dir pre-commit \
    || pip3 install --no-cache-dir pre-commit==${PRE_COMMIT_VERSION}

# Install tools
WORKDIR /bin_dir
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
    ) && tar -xzf terraform-docs.tgz terraform-docs && chmod +x terraform-docs && \
    # Terrascan
    ( \
        TERRASCAN_RELEASES="https://api.github.com/repos/accurics/terrascan/releases" && \
        [ ${TERRASCAN_VERSION} = "latest" ] && curl -L "$(curl -s ${TERRASCAN_RELEASES}/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz \
        || curl -L "$(curl -s ${TERRASCAN_RELEASES} | grep -o -E "https://.+?${TERRASCAN_VERSION}_Linux_x86_64.tar.gz")" > terrascan.tar.gz \
    ) && tar -xzf terrascan.tar.gz terrascan && rm terrascan.tar.gz && \
    ./terrascan init && \
    # Terragrunt
    ( \
        TERRAGRUNT_RELEASES="https://api.github.com/repos/gruntwork-io/terragrunt/releases" && \
        [ ${TERRAGRUNT_VERSION} = "latest" ] && curl -L "$(curl -s ${TERRAGRUNT_RELEASES}/latest | grep -o -E "https://.+?/terragrunt_linux_amd64" | head -n 1)" > terragrunt \
        || curl -L "$(curl -s ${TERRAGRUNT_RELEASES} | grep -o -E "https://.+?v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" | head -n 1)" > terragrunt \
    ) && chmod +x terragrunt && \
    # TFLint
    ( \
        TFLINT_RELEASES="https://api.github.com/repos/terraform-linters/tflint/releases" && \
        [ ${TFLINT_VERSION} = "latest" ] && curl -L "$(curl -s ${TFLINT_RELEASES}/latest | grep -o -E "https://.+?_linux_amd64.zip")" > tflint.zip \
        || curl -L "$(curl -s ${TFLINT_RELEASES} | grep -o -E "https://.+?/v${TFLINT_VERSION}/tflint_linux_amd64.zip")" > tflint.zip \
    ) && unzip tflint.zip && rm tflint.zip && \
    # TFSec
    ( \
        TFSEC_RELEASES="https://api.github.com/repos/aquasecurity/tfsec/releases" && \
        [ ${TFSEC_VERSION} = "latest" ] && curl -L "$(curl -s ${TFSEC_RELEASES}/latest | grep -o -E "https://.+?/tfsec-linux-amd64" | head -n 1)" > tfsec \
        || curl -L "$(curl -s ${TFSEC_RELEASES} | grep -o -E "https://.+?v${TFSEC_VERSION}/tfsec-linux-amd64" | head -n 1)" > tfsec \
    ) && chmod +x tfsec

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

# Checking binaries versions
RUN echo "\n\n" && \
    pre-commit --version && \
    terraform --version | head -n 1 && \
    echo -n "checkov " && checkov --version && \
    ./terraform-docs --version && \
    ./terragrunt --version && \
    echo -n "terrascan " && ./terrascan version && \
    ./tflint --version && \
    echo -n "tfsec " && ./tfsec --version && \
    echo "\n\n"

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
    /usr/local/bin/checkov \
    /usr/local/bin/pre-commit \
    /usr/bin/git \
    /usr/bin/git-shell \
        /usr/bin/
# Copy terrascan policies
COPY --from=builder /root/.terrascan/ /root/.terrascan/

ENV PRE_COMMIT_COLOR=${PRE_COMMIT_COLOR:-always}

ENTRYPOINT [ "pre-commit" ]

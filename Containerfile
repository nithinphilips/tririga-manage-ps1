
# podman build --platform linux/amd64 -t tririga-manage-ps1-dev .
# podman run -v .:/workspace -it tririga-manage-ps1-dev
# make dist

# Install-Module Pester -Force
# Import-Module Pester -PassThru
# Install-Module PSScriptAnalyzer -Force
# Import-Module PSScriptAnalyzer -PassThru

# The graalvm download file from Oracle only contains the major version (25).
# We want to be able to tag our image with the exact version.
# So, the downloaded files on file.chicago.nithinphilips.com are renamed to
# include the exact full version.
ARG gh_version=2.89.0
ARG tea_version=0.13.0
ARG mlr_version=6.20.2
ARG TARGETARCH=amd64

# -------------------------------
# Stage 1. Build markdown-extract
# TODO: this image is not compatible with buster.
FROM rust:slim-buster AS mdebuild
RUN cargo install --locked markdown-extract-cli

# -------------------------------
# Stage 2: Extract archived files
FROM debian:trixie as extractor

ARG tea_version TARGETARCH

RUN apt-get update && \
    apt-get install -y unzip curl

RUN ALT_ARCH="$TARGETARCH"; \
    case "$ALT_ARCH" in amd64) ALT_ARCH=x86_64 ;; arm64) ALT_ARCH=aarch64 ;; esac; \
    curl -L https://awscli.amazonaws.com/awscli-exe-linux-${ALT_ARCH}.zip --output /tmp/awscli-exe-linux.zip

RUN unzip -q -d /opt /tmp/awscli-exe-linux.zip

# -------------------------------
# Stage 3: Build image
FROM mcr.microsoft.com/dotnet/sdk:9.0
LABEL org.opencontainers.image.authors="nithin@nithinphilips.com"
ARG gh_version tea_version mlr_version TARGETARCH

# Install build deps
RUN apt-get update && \
    apt-get install -y unzip curl make xmlstarlet pandoc wget curl git zip unzip build-essential zlib1g-dev ca-certificates gawk dos2unix vim && \
    apt-get clean

# Tools for Release-mk (https://gitea.sterling.nithinphilips.com/nithin/release-mk#requirements)
# Install Tea and Markdown Extract
ADD https://gitea.com/gitea/tea/releases/download/v${tea_version}/tea-${tea_version}-linux-${TARGETARCH} /usr/local/bin/tea
COPY --from=mdebuild /usr/local/cargo/bin/markdown-extract /usr/local/bin/markdown-extract
RUN chmod ugo+x /usr/local/bin/tea /usr/local/bin/markdown-extract

ADD https://github.com/cli/cli/releases/download/v${gh_version}/gh_${gh_version}_linux_${TARGETARCH}.deb /tmp/gh_${gh_version}_linux_${TARGETARCH}.deb
RUN dpkg -i /tmp/gh_${gh_version}_linux_${TARGETARCH}.deb

COPY --from=extractor /opt/aws /opt/aws
RUN /opt/aws/install

# Install tririga-manage-ps1 build dependencies
ADD https://github.com/johnkerl/miller/releases/download/v${mlr_version}/miller-${mlr_version}-linux-${TARGETARCH}.deb /tmp/miller-${mlr_version}-linux-${TARGETARCH}.deb
RUN dpkg -i /tmp/miller-${mlr_version}-linux-${TARGETARCH}.deb
RUN pwsh -Command "Install-Module Pester -Force; Install-Module PSScriptAnalyzer -Force; Install-Module platyPS -Force"

# Install Step CLI and nithinphilips.com root CA
ADD https://dl.smallstep.com/cli/docs-cli-install/latest/step-cli_${TARGETARCH}.deb /tmp/step-cli_${TARGETARCH}.deb
RUN dpkg -i /tmp/step-cli_${TARGETARCH}.deb
RUN step ca bootstrap --ca-url https://stepca.sterling.nithinphilips.com --fingerprint c0231014f006b79252f38a8f6c1cf42dcb8095b803c15e5fc1768fe2c13cd3fd
RUN step certificate install "$(step path)/certs/root_ca.crt"

WORKDIR /workspace

ENTRYPOINT ["pwsh"]


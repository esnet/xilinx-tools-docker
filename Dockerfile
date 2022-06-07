FROM ubuntu:bionic
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
COPY sources.list /etc/apt/sources.list

# Install packages required for running the vivado installer
RUN \
  ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    g++ \
    graphviz \
    lib32gcc-7-dev \
    libtinfo-dev \
    libtinfo5 \
    libxi6 \
    libxrender1 \
    libxtst6  \
    locales \
    lsb-release \
    net-tools \
    unzip \
    wget \
    x11-apps \
    x11-utils \
    xvfb \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*

# Set up the base address for where our installer binaries are stored
ARG DISPENSE_BASE_URL="https://dispense.es.net/Linux/xilinx"

# Install the Xilinx Vivado tools in headless mode
# ENV var to help users to find the version of vivado that has been installed in this container
ENV VIVADO_VERSION=2022.1
# Xilinx installer tar file originally from: https://www.xilinx.com/support/download.html
ARG VIVADO_INSTALLER="Xilinx_Unified_${VIVADO_VERSION}_0420_0327.tar.gz"
COPY vivado-installer/ /vivado-installer/
RUN \
  ( \
    if [ -e /vivado-installer/$VIVADO_INSTALLER ] ; then \
      tar zxf /vivado-installer/$VIVADO_INSTALLER --strip-components=1 -C /vivado-installer ; \
    else \
      wget -qO- $DISPENSE_BASE_URL/$VIVADO_INSTALLER | tar zx --strip-components=1 -C /vivado-installer ; \
    fi \
  ) && \
  /vivado-installer/xsetup \
    --agree 3rdPartyEULA,XilinxEULA \
    --batch Install \
    --config /vivado-installer/install_config_vivado2022.txt && \
  rm -rf /vivado-installer

#
# ** ONLY REQUIRED WHEN BUILDING ON UBUNTU 20.04 **
#
# Install libssl 1.0.0 package from bionic since it is transitively required by the p4bm-vitisnet executable and is not
# properly vendored by the Xilinx runtime environment.
#
# Ubuntu 18.04/bionic provides libssl 1.0.0
# Ubuntu 20.04/focal  provides libssl 1.1
#
# p4bm-vitisnet is dynamically linked against
#   libthrift-0.11.0.so  (vendored properly)
#     libssl.so.1.0.0    (not vendored, must be provided by host)
#     libcrypto.so.1.0.0 (not vendored, must be provided by host)
#
# The libssl .deb package provides both libssl and libcrypto.
#
# This is a sketchy hack to grab a deb from a different Ubuntu release by reaching directly into the package mirror's
# pool and grabbing the .deb directly.  This is how we'll deal with it until Xilinx fixes this issue.
#
# ARG UBUNTU_MIRROR_BASE="http://linux.mirrors.es.net/ubuntu/pool/main/o/openssl1.0"
# ARG LIBSSL_PKG_FILE="libssl1.0.0_1.0.2n-1ubuntu5.7_amd64.deb"
# RUN \
#   wget -q $UBUNTU_MIRROR_BASE/$LIBSSL_PKG_FILE && \
#   dpkg -i ./$LIBSSL_PKG_FILE && \
#   rm ./$LIBSSL_PKG_FILE


#
# ** ONLY REQUIRED WHEN BUILDING ON UBUNTU 18.04 **
#
# Install libssl 1.0.0 package since it is transitively required by the p4bm-vitisnet executable and is not
# properly vendored by the Xilinx runtime environment.
#
RUN \
  ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    libssl1.0.0 \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Install specific packages required by esnet-smartnic build
RUN \
  ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    git \
    jq \
    libconfig-dev \
    libpci-dev \
    libsmbios-c2 \
    make \
    python3-click \
    python3-jinja2 \
    python3-libsmbios \
    python3-pip \
    python3-scapy \
    python3-yaml \
    rsync \
    tcpdump \
    tshark \
    wireshark-common \
    zip \
    zstd \
    && \
  pip3 install pyyaml-include && \
  pip3 install yq && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Install Minio/rados-rgw/s3 client
ARG MINIO_CLIENT_BASE_URL="https://dl.min.io/client/mc/release/linux-amd64/archive/"
ARG MINIO_CLIENT_VER="20220107060138.0.0"
RUN \
  wget -q $MINIO_CLIENT_BASE_URL/mcli_${MINIO_CLIENT_VER}_amd64.deb && \
    dpkg -i mcli_${MINIO_CLIENT_VER}_amd64.deb && \
    rm mcli_${MINIO_CLIENT_VER}_amd64.deb

CMD ["/bin/bash", "-l"]

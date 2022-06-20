FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
COPY sources.list.focal /etc/apt/sources.list

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
    pigz \
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

# Install the Xilinx Vivado tools and updates in headless mode
# ENV var to help users to find the version of vivado that has been installed in this container
ENV VIVADO_VERSION=2022.1
# Xilinx installer tar file originally from: https://www.xilinx.com/support/download.html
ARG VIVADO_INSTALLER="Xilinx_Unified_${VIVADO_VERSION}_0420_0327.tar.gz"
ARG VIVADO_UPDATE="Xilinx_Vivado_Vitis_Update_${VIVADO_VERSION}.1_0603_1803.tar.gz"
COPY vivado-installer/ /vivado-installer/
RUN \
  mkdir -p /vivado-installer/install && \
  ( \
    if [ -e /vivado-installer/$VIVADO_INSTALLER ] ; then \
      pigz -dc /vivado-installer/$VIVADO_INSTALLER | tar xa --strip-components=1 -C /vivado-installer/install ; \
    else \
      wget -qO- $DISPENSE_BASE_URL/$VIVADO_INSTALLER | pigz -dc | tar xa --strip-components=1 -C /vivado-installer/install ; \
    fi \
  ) && \
  /vivado-installer/install/xsetup \
    --agree 3rdPartyEULA,XilinxEULA \
    --batch Install \
    --config /vivado-installer/install_config_vivado2022.txt && \
  rm -r /vivado-installer/install && \
  mkdir -p /vivado-installer/update && \
  ( \
    if [ -e /vivado-installer/$VIVADO_UPDATE ] ; then \
      pigz -dc /vivado-installer/$VIVADO_UPDATE | pigz -dc | tar xa --strip-components=1 -C /vivado-installer/update ; \
    else \
      wget -qO- $DISPENSE_BASE_URL/$VIVADO_UPDATE | pigz -dc | tar xa --strip-components=1 -C /vivado-installer/update ; \
    fi \
  ) && \
  /vivado-installer/update/xsetup \
    --agree 3rdPartyEULA,XilinxEULA \
    --batch Update \
    --config /vivado-installer/install_config_vivado2022.txt && \
  rm -r /vivado-installer/update && \
  rm -rf /vivado-installer

# Install specific packages required by esnet-smartnic build
RUN \
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
ARG MINIO_CLIENT_VER="20220611211036.0.0"
RUN \
  wget -q $MINIO_CLIENT_BASE_URL/mcli_${MINIO_CLIENT_VER}_amd64.deb && \
    dpkg -i mcli_${MINIO_CLIENT_VER}_amd64.deb && \
    rm mcli_${MINIO_CLIENT_VER}_amd64.deb

CMD ["/bin/bash", "-l"]

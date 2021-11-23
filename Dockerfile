FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
COPY sources.list /etc/apt/sources.list

# Install packages required for running the vivado installer
RUN \
  ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    wget \
    libtinfo-dev \
    libxrender1 \
    libxtst6  \
    x11-apps \
    libxi6 \
    lib32gcc-7-dev \
    net-tools \
    graphviz \
    unzip \
    g++ \
    libtinfo5 \
    x11-utils \
    xvfb \
    unzip \
    lsb-release \
    locales \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*

# Set up the base address for where our installer binaries are stored
ARG DISPENSE_BASE_URL="http://dispense.es.net/Linux/xilinx"

# Install the Xilinx Vivado tools in headless mode
# Xilinx installer tar file originally from: https://www.xilinx.com/support/download.html
# https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Unified_2021.2_1021_0703.tar.gz
ARG VIVADO_INSTALLER="Xilinx_Unified_2021.2_1021_0703.tar.gz"
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
    --config /vivado-installer/install_config_vivado2021.txt && \
  rm -rf /vivado-installer

# Install extra packages required at runtime for Xilinx tools
# libssl1 is required due to it being improperly vendored in the sdnet tools.  This requirement may no longer exist in newer versions of the sdnet tools.
# RUN \
#   ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
#   apt-get update -y && \
#   apt-get upgrade -y && \
#   apt-get install -y --no-install-recommends \
#     libssl1.0.0 \
#     && \
#   apt-get autoclean && \
#   apt-get autoremove && \
#   locale-gen en_US.UTF-8 && \
#   update-locale LANG=en_US.UTF-8 && \
#   rm -rf /var/lib/apt/lists/*

# Install specific packages required by esnet-smartnic build
RUN \
  ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    libpci-dev \
    libconfig-dev \
    libsmbios-c2 \
    python3-libsmbios \
    python3-pip \
    python3-click \
    python3-yaml \
    python3-jinja2 \
    wireshark-common \
    tshark \
    make \
    git \
    rsync \
    zstd \
    jq \
    python3-scapy \
    && \
  pip3 install pyyaml-include && \
  pip3 install yq && \
  apt-get autoclean && \
  apt-get autoremove && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*

# Install Minio/rados-rgw/s3 client
ARG MINIO_CLIENT_BASE_URL="https://dl.min.io/client/mc/release/linux-amd64/"
ARG MINIO_CLIENT_VER="20211116203736.0.0"
RUN \
  wget -q $MINIO_CLIENT_BASE_URL/mcli_${MINIO_CLIENT_VER}_amd64.deb && \
    dpkg -i mcli_${MINIO_CLIENT_VER}_amd64.deb && \
    rm mcli_${MINIO_CLIENT_VER}_amd64.deb

CMD ["/bin/bash", "-l"]

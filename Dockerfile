FROM ubuntu:jammy
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
RUN \
  sed -i -re 's|(http://)([^/]+.*)/|\1linux.mirrors.es.net/ubuntu|g' /etc/apt/sources.list

# Install packages required for running the vivado installer
RUN \
  ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    libtinfo5 \
    locales \
    lsb-release \
    net-tools \
    patch \
    unzip \
    wget \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*

# Set up the base address for where installer binaries are stored within ESnet's private network
#
# NOTE: This URL is NOT REACHABLE outside of ESnet's private network.  Non-ESnet users must follow
#       the instructions in the README.md file and download their own copies of the installers
#       directly from the AMD/Xilinx website and drop them into the vivado-installer directory
#
ARG DISPENSE_BASE_URL="https://dispense.es.net/Linux/xilinx"

# Install the Xilinx Vivado tools and updates in headless mode
# ENV var to help users to find the version of vivado that has been installed in this container
ENV VIVADO_VERSION=2024.2
# Xilinx installer tar file originally from: https://www.xilinx.com/support/download.html
ARG VIVADO_INSTALLER="FPGAs_AdaptiveSoCs_Unified_${VIVADO_VERSION}_1113_1001.tar"
ARG VIVADO_UPDATE=""
# Installer config file
ARG VIVADO_INSTALLER_CONFIG="/vivado-installer/install_config_vivado.${VIVADO_VERSION}.txt"

COPY vivado-installer/ /vivado-installer/
RUN \
  mkdir -p /vivado-installer/install && \
  ( \
    if [ -e /vivado-installer/$VIVADO_INSTALLER ] ; then \
      tar xf /vivado-installer/$VIVADO_INSTALLER --strip-components=1 -C /vivado-installer/install ; \
    else \
      wget -qO- $DISPENSE_BASE_URL/$VIVADO_INSTALLER | tar x --strip-components=1 -C /vivado-installer/install ; \
    fi \
  ) && \
  if [ ! -e ${VIVADO_INSTALLER_CONFIG} ] ; then \
    /vivado-installer/install/xsetup \
      -p 'Vivado' \
      -e 'Vivado ML Enterprise' \
      -b ConfigGen && \
    echo "No installer configuration file was provided.  Generating a default one for you to modify." && \
    echo "-------------" && \
    cat /root/.Xilinx/install_config.txt && \
    echo "-------------" && \
    exit 1 ; \
  fi ; \
  /vivado-installer/install/xsetup \
    --agree 3rdPartyEULA,XilinxEULA \
    --batch Install \
    --config ${VIVADO_INSTALLER_CONFIG} && \
  rm -r /vivado-installer/install && \
  mkdir -p /vivado-installer/update && \
  if [ ! -z "$VIVADO_UPDATE" ] ; then \
    ( \
      if [ -e /vivado-installer/$VIVADO_UPDATE ] ; then \
        tar xf /vivado-installer/$VIVADO_UPDATE --strip-components=1 -C /vivado-installer/update ; \
      else \
        wget -qO- $DISPENSE_BASE_URL/$VIVADO_UPDATE | tar x --strip-components=1 -C /vivado-installer/update ; \
      fi \
    ) && \
    /vivado-installer/update/xsetup \
      --agree 3rdPartyEULA,XilinxEULA \
      --batch Update \
      --config ${VIVADO_INSTALLER_CONFIG} && \
    rm -r /vivado-installer/update ; \
  fi && \
  rm -rf /vivado-installer

# ONLY REQUIRED FOR Ubuntu 20.04 (focal) but harmless on other distros
# Hack: replace the stock libudev1 with a newer one from Ubuntu 22.04 (jammy) to avoid segfaults when invoked
#       from the flexlm license code within Vivado
RUN \
  if [ "$(lsb_release --short --release)" = "20.04" ] ; then \
    wget -q -P /tmp http://linux.mirrors.es.net/ubuntu/pool/main/s/systemd/libudev1_249.11-0ubuntu3_amd64.deb && \
    dpkg-deb --fsys-tarfile /tmp/libudev1_*.deb | \
      tar -C /tools/Xilinx/Vivado/${VIVADO_VERSION}/lib/lnx64.o/Ubuntu/20 --strip-components=4 -xavf - ./usr/lib/x86_64-linux-gnu/ && \
    rm /tmp/libudev1_*.deb ; \
  fi

# Hack: Install libssl 1.1.1 package from Ubuntu 20.04 (focal) since it is transitively required by the p4bm-vitisnet
#       executable and is not properly vendored by the Xilinx runtime environment.
#
# Ubuntu 20.04/focal  provides libssl 1.1
# Ubuntu 22.04/jammy  provides libssl 3.3
#
# p4bm-vitisnet is dynamically linked against
#   libthrift-0.11.0.so  (now vendored properly in 22.04)
#     libssl.so.1.1      (not vendored, pull the old version from Ubuntu 20.04)
#     libcrypto.so.1.1   (not vendored, pull the old version from Ubuntu 20.04)
#
# The libssl .deb package provides both libssl and libcrypto.
#
# This is a sketchy hack to grab a deb from a different Ubuntu release by reaching directly into the package mirror's
# pool and grabbing the .deb directly.  This is how we'll deal with it until Xilinx fixes this issue (again).

RUN \
  if [ "$(lsb_release --short --release)" = "22.04" ] ; then \
    wget -q -P /tmp http://linux.mirrors.es.net/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_amd64.deb && \
    dpkg-deb --fsys-tarfile /tmp/libssl1.*.deb | \
      tar -C /tools/Xilinx/Vivado/${VIVADO_VERSION}/lib/lnx64.o/Ubuntu/22 --strip-components=4 -xavf - ./usr/lib/x86_64-linux-gnu/ && \
    rm /tmp/libssl1.*.deb ; \
  fi

# Apply post-install patches to fix issues found on each OS release
# Common patches
#   * Disable workaround for X11 XSupportsLocale bug.  This workaround triggers additional requirements on the host
#     to have an entire suite of X11 related libraries installed even though we only use vivado in batch/tcl mode.
#     See: https://support.xilinx.com/s/article/62553?language=en_US
COPY patches/ /patches
RUN \
  if [ -e "/patches/ubuntu-$(lsb_release --short --release)-vivado-${VIVADO_VERSION}-postinstall.patch" ] ; then \
    patch -p 1 < /patches/ubuntu-$(lsb_release --short --release)-vivado-${VIVADO_VERSION}-postinstall.patch ; \
  fi ; \
  if [ -e "/patches/vivado-${VIVADO_VERSION}-postinstall.patch" ] ; then \
    patch -p 1 < /patches/vivado-${VIVADO_VERSION}-postinstall.patch ; \
  fi

# Install specific packages required by esnet-smartnic build
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    build-essential \
    git \
    jq \
    less \
    libconfig-dev \
    libpci-dev \
    libsmbios-c2 \
    make \
    pax-utils \
    python3-click \
    python3-jinja2 \
    python3-libsmbios \
    python3-pip \
    python3-scapy \
    python3-yaml \
    rsync \
    tcpdump \
    tshark \
    vim-tiny \
    wireshark-common \
    zip \
    zstd \
    && \
  pip3 install pyyaml-include && \
  pip3 install yq && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Set up the container to pre-source the vivado environment
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

CMD ["/bin/bash", "-l"]

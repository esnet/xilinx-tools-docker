FROM ubuntu:bionic
ENV DEBIAN_FRONTEND noninteractive
ARG VIVADO_INSTALLER="Xilinx_Unified_2020.2_1118_1232.tar.gz"
ARG SDNET_INSTALLER="Xilinx_SDNet_2020.2_0216_2201.tar.gz"
ARG VIVADO_CONFIG="install_config.vivado2020.txt"
ARG SDNET_CONFIG="install_config.sdnet.txt"

RUN \
  ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends wget libtinfo-dev libxrender1 libxtst6  x11-apps \
   libxi6 lib32gcc-7-dev net-tools graphviz unzip g++ libtinfo5 x11-utils xvfb unzip g++ libtinfo5 \
   libpci-dev libconfig-dev libsmbios-c2 python3-libsmbios python3-pip python3-click python3-yaml \
   python3-jinja2 wireshark-common tshark make lsb-release libssl1.0.0 locales git && \
  pip3 install pyyaml-include && \
  apt-get autoclean && \
  apt-get autoremove && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*


COPY $VIVADO_CONFIG /vivado-installer/
RUN \
wget -qO- http://dispense.es.net/Linux/xilinx/$VIVADO_INSTALLER | tar zx --strip-components=1 -C /vivado-installer && \
  /vivado-installer/xsetup \
    --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA \
    --batch Install \
    --config /vivado-installer/$VIVADO_CONFIG && \
  rm -rf /vivado-installer

COPY $SDNET_CONFIG /vivado-installer/
RUN \
wget -qO- http://dispense.es.net/Linux/xilinx/$SDNET_INSTALLER | tar zx --strip-components=1 -C /vivado-installer && \
  /vivado-installer/xsetup \
    --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA \
    --batch Install \
    --config /vivado-installer/$SDNET_CONFIG && \
  rm -rf /vivado-installer

CMD ["/bin/bash", "-l"]

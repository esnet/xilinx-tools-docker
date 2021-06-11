#!/bin/bash
#export LC_ALL=C; unset LANGUAGE
source /opt/Xilinx/Vivado/2020.2/settings64.sh
source /opt/Xilinx/SDNet/2020.2/settings64.sh
export XILINXD_LICENSE_FILE='2100@dmv.es.net'
exec "$@"

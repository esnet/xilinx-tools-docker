#!/bin/bash

# Source the Xilinx Vivado settings into the environment
source /tools/Xilinx/Vivado/${VIVADO_BASE_VERSION}/settings64.sh

# Apply workaround for crashes in FlexLM license manager in Ubuntu 22.04
# See: https://community.revenera.com/s/question/0D5PL00000NwuKu0AJ/issues-when-running-xilinx-tools-or-other-vendor-tools-in-docker-environment
# See: https://adaptivesupport.amd.com/s/question/0D54U00005Sgst2SAB/failed-batch-mode-execution-in-linux-docker-running-under-windows-host?language=en_US
export LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1

# Run the provided CMD
exec "$@"

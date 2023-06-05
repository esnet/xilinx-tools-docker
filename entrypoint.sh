#!/bin/bash

# Source the Xilinx Vivado settings into the environment
source /tools/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh

# Run the provided CMD
exec "$@"

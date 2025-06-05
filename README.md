# Copyright Notice

ESnet SmartNIC Copyright (c) 2022, The Regents of the University of
California, through Lawrence Berkeley National Laboratory (subject to
receipt of any required approvals from the U.S. Dept. of Energy),
12574861 Canada Inc., Malleable Networks Inc., and Apical Networks, Inc.
All rights reserved.

If you have questions about your rights to use or distribute this software,
please contact Berkeley Lab's Intellectual Property Office at
IPO@lbl.gov.

NOTICE.  This Software was developed under funding from the U.S. Department
of Energy and the U.S. Government consequently retains certain rights.  As
such, the U.S. Government has been granted for itself and others acting on
its behalf a paid-up, nonexclusive, irrevocable, worldwide license in the
Software to reproduce, distribute copies to the public, prepare derivative
works, and perform publicly and display publicly, and to permit others to do so.


# Support

The ESnet SmartNIC platform is made available in the hope that it will
be useful to the networking community. Users should note that it is
made available on an "as-is" basis, and should not expect any
technical support or other assistance with building or using this
software. For more information, please refer to the LICENSE.md file in
each of the source code repositories.

The developers of the ESnet SmartNIC platform can be reached by email
at smartnic@es.net.


Download the Xilinx Vivado Installer
------------------------------------

* Open a web browser to this page: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2024-2.html
* Under the `Vivado™ Edition Update 2 - 2024.2  Product Update` section
  * Download `AMD Unified Installer for FPGAs & Adaptive SoCs 2024.2.2: SFD All OS installer Single-File Download`
  * Save the file as exactly: `FPGAs_AdaptiveSoCs_Unified_2024.2.2_0306_2141.tar`
* Move the files into the `vivado-installer` directory in this repo

```
$ tree
.
├── Dockerfile
├── entrypoint.sh
├── LICENSE.md
├── patches
│   └── vivado-2024.2.2-postinstall.patch
├── README.md
└── vivado-installer
    ├── install_config_vivado.2024.2.2.txt
    └── FPGAs_AdaptiveSoCs_Unified_2024.2.2_0306_2141.tar   <--------- put the base installer here
```

Building the xilinx-tools-docker container
------------------------------------------

```
docker build --pull -t xilinx-tools-docker:v2024.2.2-latest .
docker image ls
```

You should see an image called `xilinx-tools-docker` with tag `v2024.2.2-latest`.

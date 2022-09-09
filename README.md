
Download the Xilinx Vivado Installer
------------------------------------

* Open a web browser to this page: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2022-1.html
* Under the `Vivado ML Edition - 2022.1 Full Product Installation` section
  * Download `Xilinx Unified Installer 2022.1 SFD`
  * Save the file as exactly: `Xilinx_Unified_2022.1_0420_0327.tar.gz`
* Under the `Vivado ML Edition Update 1 - 2022.1  Product Update` section
  * Download `Xilinx Unified 2022.1.1 : All OS installer Single-File Download`
  * Save the file as exactly: `Xilinx_Vivado_Vitis_Update_2022.1.1_0603_1803.tar.gz`
* Move the files into the `vivado-installer` directory in this repo

```
$ tree
.
├── Dockerfile
├── sources.list.bionic
├── sources.list.focal
└── vivado-installer
    ├── install_config_vivado2021.txt
    ├── install_config_vivado2022.txt
    ├── Xilinx_Unified_2022.1_0420_0327.tar.gz   <--------------------- put the base installer here
    └── Xilinx_Vivado_Vitis_Update_2022.1.1_0603_1803.tar.gz   <------- put the update installer here
```

Building the xilinx-tools-docker container
------------------------------------------

```
docker build --pull -t xilinx-tools-docker:v2022.1-latest .
docker image ls
```

You should see an image called `xilinx-tools-docker` with tag `v2022.1-latest`.

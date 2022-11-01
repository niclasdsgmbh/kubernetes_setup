#!/bin/bash

./calico/01_create_datastore.sh
./calico/02_create_ippools.sh
./calico/03_containerd.sh
./calico/04_config_cniplugin.sh
./calico/05_install_cniplugin.sh
./calico/06_install_typha.sh
./calico/07_install_typhadeployment.sh
./calico/08_install_caliconode.sh
./calico/09_configure_bgp.sh
./calico/10_finish.sh
./calico/11_install_csi.sh
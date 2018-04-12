# gentoo-install
Automated gentoo installation script

#### First things first
Download this from github using command
```
curl -sLk --user xianzhengzhou https://github.com/xianzhengzhou/gentoo-install/archive/master.zip -o tmp.zip; unzip tmp.zip; rm -f tmp.zip; cd gentoo-install-master

```

#### If partitioning is required. Remove LVM using
```
vgs
vgremove [group name]
./1_partition.sh
```

####
Once partition is done. Proceed with:
```
./2_base.sh
```
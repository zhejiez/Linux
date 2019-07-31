LVM    
---

>简介：    
当你Linux系统硬盘不够的时候,你添加硬盘只能挂载目录.但是lvm可以把很多硬盘整合到一起,当成一块硬盘用  
  
命令解释:  
pvs：查看物理卷   
lvs：查看逻辑卷   
vgs：查看卷组    
    
一，创建LVM    
--------

fdisk -l 查看硬盘信息,sdb是新加一块磁盘：   
```  
fdisk -l  
  
磁盘 /dev/sdb：21.5 GB, 21474836480 字节，41943040 个扇区  
Units = 扇区 of 1 * 512 = 512 bytes  
扇区大小(逻辑/物理)：512 字节 / 512 字节  
I/O 大小(最小/最佳)：512 字节 / 512 字节  
  
  
磁盘 /dev/sda：21.5 GB, 21474836480 字节，41943040 个扇区  
Units = 扇区 of 1 * 512 = 512 bytes  
扇区大小(逻辑/物理)：512 字节 / 512 字节  
I/O 大小(最小/最佳)：512 字节 / 512 字节  
磁盘标签类型：dos  
磁盘标识符：0x000a5c7d  
  
   设备 Boot      Start         End      Blocks   Id  System  
/dev/sda1   *        2048     2099199     1048576   83  Linux  
/dev/sda2         2099200    41943039    19921920   8e  Linux LVM  
  
磁盘 /dev/mapper/centos-root：18.2 GB, 18249416704 字节，35643392 个扇区  
Units = 扇区 of 1 * 512 = 512 bytes  
扇区大小(逻辑/物理)：512 字节 / 512 字节  
I/O 大小(最小/最佳)：512 字节 / 512 字节  
  
  
磁盘 /dev/mapper/centos-swap：2147 MB, 2147483648 字节，4194304 个扇区  
Units = 扇区 of 1 * 512 = 512 bytes  
扇区大小(逻辑/物理)：512 字节 / 512 字节  
I/O 大小(最小/最佳)：512 字节 / 512 字节  
```  
1. 将物理磁盘设备初始化为物理卷    
```  
pvcreate /dev/sdb1  
  Physical volume "/dev/sdb" successfully created.  
```  
+ 如果显示：    
```  
pvcreate /dev/sdb1  
  Can't open /dev/sdb1 exclusively.  Mounted filesystem?  
需要先卸载：umount /dev/sdb1    
```    
2.创建卷组Linuxrhel，并将PV加入卷组中    
```  
vgcreate linuxrhel /dev/sdb1  
  Volume group "linuxrhel" successfully created  
```  
查看卷组    
```  
vgs  
  VG        #PV #LV #SN Attr   VSize   VFree  
  centos      1   2   0 wz--n- <19.00g      0  
  linuxrhel   1   0   0 wz--n- <20.00g <20.00g  
```   
3.基于卷组创建逻辑卷mylv   
```   
lvcreate -n mylv -L 2G linuxrhel  
  Logical volume "mylv" created.  
```  
查看mylv逻辑卷    
```  
ls -l /dev/linuxrhel/mylv  
lrwxrwxrwx. 1 root root 7 7月  31 14:43 /dev/linuxrhel/mylv -> ../dm-2  
```  
4.为创建好的逻辑卷创建文件系统(mkfs.ext4)    
```  
mkfs.ext4 /dev/linuxrhel/mylv  
mke2fs 1.42.9 (28-Dec-2013)  
文件系统标签=  
OS type: Linux  
块大小=4096 (log=2)  
分块大小=4096 (log=2)  
Stride=0 blocks, Stripe width=0 blocks  
131072 inodes, 524288 blocks  
26214 blocks (5.00%) reserved for the super user  
第一个数据块=0  
Maximum filesystem blocks=536870912  
16 block groups  
32768 blocks per group, 32768 fragments per group  
8192 inodes per group  
Superblock backups stored on blocks:  
	32768, 98304, 163840, 229376, 294912  
  
Allocating group tables: 完成  
正在写入inode表: 完成  
Creating journal (16384 blocks): 完成  
Writing superblocks and filesystem accounting information: 完成  
```  
查看文件系统命令    
```  
cat /etc/fstab  
  
#  
# /etc/fstab  
# Created by anaconda on Mon Mar 18 11:00:56 2019  
#  
# Accessible filesystems, by reference, are maintained under '/dev/disk'  
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info  
#  
/dev/mapper/centos-root /                       xfs     defaults        0 0  
UUID=09366d10-a803-44f5-b815-2d957b3b45b4 /boot                   xfs     defaults        0 0  
/dev/mapper/centos-swap swap                    swap    defaults        0 0  
/dev/sdb1 /opt/c8o ext4 defaults 0 0  
  
```   
5.将格式化好的逻辑卷挂载到新建的test文件上使用    
```  
mkdir /opt/c8o   
mount /dev/linuxrhel/mylv /opt/c8o/  
/dev/mapper/centos-root      17G  3.1G   14G   19% /  
devtmpfs                    899M     0  899M    0% /dev  
tmpfs                       910M     0  910M    0% /dev/shm  
tmpfs                       910M  9.5M  901M    2% /run  
tmpfs                       910M     0  910M    0% /sys/fs/cgroup  
/dev/sda1                  1014M  233M  782M   23% /boot  
tmpfs                       910M   12K  910M    1% /var/lib/rancher/k3s/agent/kubelet/pods/fed3d189-b345-11e9-bf3a-000c294a91b6/volumes/kubernetes.io~secret/coredns-token-9x7r2  
overlay                      17G  3.1G   14G   19% /var/lib/docker/overlay2/dd7253b203619df31f4775e2131f3525dec14a9b4206e73c9b2abfffe3e0d0d3/merged  
shm                          64M     0   64M    0% /var/lib/docker/containers/c44d26b2c57f66563036509647f65d9ce8f6f8fbf6342714899790f643e79869/mounts/shm  
overlay                      17G  3.1G   14G   19% /var/lib/docker/overlay2/272cdec3a6f8d01c0f1919c7bc65db326bc92a45022f1186dcecb66b6a4c920c/merged  
tmpfs                       182M     0  182M    0% /run/user/0  
/dev/mapper/linuxrhel-mylv  2.0G  6.0M  1.8G    1% /opt/c8o  
```    
####二，扩展卷组vgs(卷组)：如果卷组空间不够用    
将要添加到VG(卷组)的硬盘格式化为PV(新添加的硬盘)    
```  
pvcreate /dev/sdc1  
  Physical volume "/dev/sdc1" successfully created.   
```  
2.把sdc磁盘添加到Linuxrhl卷组    
```  
vgextend linuxrhel /dev/sdc1  
  Volume group "linuxrhel" successfully extended   
```  
3.査看扩充后VG大小    
```  
vgs  
  VG        #PV #LV #SN Attr   VSize   VFree  
  centos      1   2   0 wz--n- <19.00g     0  
  linuxrhel   2   1   0 wz--n-  39.99g 37.99g  
```  
三、扩展逻辑卷lvs(逻辑卷)：    
-------

逻辑卷的拉伸操作可以在线执行，不需要卸载逻辑卷    
1.保证VG(卷组)中有足够的空闲空间    
```  
vgdisplay  
  --- Volume group ---  
  VG Name               linuxrhel  
  System ID  
  Format                lvm2  
  Metadata Areas        2  
  Metadata Sequence No  3  
  VG Access             read/write  
  VG Status             resizable  
  MAX LV                0  
  Cur LV                1  
  Open LV               1  
  Max PV                0  
  Cur PV                2  
  Act PV                2  
  VG Size               39.99 GiB  
  PE Size               4.00 MiB  
  Total PE              10238  
  Alloc PE / Size       512 / 2.00 GiB  
  Free  PE / Size       9726 / 37.99 GiB  
  VG UUID               8p6OH8-yDZ6-o2Hw-3aNb-5PMe-b1Jq-p6U6tC  
  
  --- Volume group ---  
  VG Name               centos  
  System ID  
  Format                lvm2  
  Metadata Areas        1  
  Metadata Sequence No  3  
  VG Access             read/write  
  VG Status             resizable  
  MAX LV                0  
  Cur LV                2  
  Open LV               2  
  Max PV                0  
  Cur PV                1  
  Act PV                1  
  VG Size               <19.00 GiB  
  PE Size               4.00 MiB  
  Total PE              4863  
  Alloc PE / Size       4863 / <19.00 GiB  
  Free  PE / Size       0 / 0  
  VG UUID               8TBUMe-kZdv-xf6G-Rp5b-80vm-NLcT-fxqvne  
```   
2.扩充逻辑卷    
```  
lvextend -L +2G /dev/linuxrhel/mylv  
  Size of logical volume linuxrhel/mylv changed from 2.00 GiB (512 extents) to 4.00 GiB (1024 extents).  
  Logical volume linuxrhel/mylv successfully resized.  
```    
3.査看扩充后LV大小    
```
lvdisplay  
  --- Logical volume ---  
  LV Path                /dev/linuxrhel/mylv  
  LV Name                mylv  
  VG Name                linuxrhel  
  LV UUID                WQsbdk-h61E-VCEx-ey3w-iCP8-XXJa-ES42N4  
  LV Write Access        read/write  
  LV Creation host, time c8o, 2019-07-31 16:20:53 +0800  
  LV Status              available  
  # open                 1  
  LV Size                4.00 GiB  
  Current LE             1024  
  Segments               1  
  Allocation             inherit  
  Read ahead sectors     auto  
  - currently set to     8192  
  Block device           253:2  
```  

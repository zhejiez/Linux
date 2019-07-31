#使用fdisk命令对sdb硬盘进行分区  
>这个本来没必要写文档的，百度一搜一大堆，但是我觉得这个操作比较重要，万一在网上搜索到坑人的文档，在升级生产环境的时候分错区，造成重大损失，觉得还是有必要写下，可能有点啰嗦  
  
命令介绍  
```  
fdisk命令用于管理磁盘分区，格式为：“fdisk [磁盘名称]”。  
管理某硬盘的分区:“fdisk /dev/sda”  
参数	作用  
m	查看全部可用的参数  
n	添加新的分区  
d	删除某个分区信息  
l	列出所有可用的分区类型  
t	改变某个分区的类型  
p	查看分区表信息  
w	保存并退出  
q	不保存直接退出  
```  
  
实践  
---  
先用fdisk -l查看硬盘,/dev/sda已经在设备上挂载,/dev/sdb没有  
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
使用fdisk命令对sdb硬盘进行分区：  
fdisk /dev/sdb  
```  
欢迎使用 fdisk (util-linux 2.23.2)。  
  
更改将停留在内存中，直到您决定将更改写入磁盘。  
使用写入命令前请三思。  
  
Device does not contain a recognized partition table  
使用磁盘标识符 0x4cfa5f2d 创建新的 DOS 磁盘标签。  
```  
p查看分区表信息（当前为空）:  
```  
磁盘 /dev/sdb：21.5 GB, 21474836480 字节，41943040 个扇区  
Units = 扇区 of 1 * 512 = 512 bytes  
扇区大小(逻辑/物理)：512 字节 / 512 字节  
I/O 大小(最小/最佳)：512 字节 / 512 字节  
磁盘标签类型：dos  
磁盘标识符：0x4cfa5f2d  
  
   设备 Boot      Start         End      Blocks   Id  System  
n创建新的分区信息：
```
命令(输入 m 获取帮助)：n
```
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
```
p代表是主分区，e为扩展分区：  
```   
Select (default p): p  
```  
1代表分区编号为1：  
```  
分区号 (1-4，默认 1)：1  
```  
磁盘的起始扇区，直接回车即可：  
```  
起始 扇区 (2048-41943039，默认为 2048)：  
```  
回车默认用所有,如果想用一部分就+nG：  
```  
Last 扇区, +扇区 or +size{K,M,G} (2048-41943039，默认为 41943039)：  
将使用默认值 41943039  
分区 1 已设置为 Linux 类型，大小设为 20 GiB  
```  
再看下分区表信息(增加了sdb1分区信息,一定要检查下在保存)：  
```  
磁盘 /dev/sdb：21.5 GB, 21474836480 字节，41943040 个扇区  
Units = 扇区 of 1 * 512 = 512 bytes  
扇区大小(逻辑/物理)：512 字节 / 512 字节  
I/O 大小(最小/最佳)：512 字节 / 512 字节  
磁盘标签类型：dos  
磁盘标识符：0x4cfa5f2d  
   设备 Boot      Start         End      Blocks   Id  System  
/dev/sdb1            2048    41943039    20970496   83  Linux  
```  
w，将上述分区信息保存：  
```  
The partition table has been altered!  
Calling ioctl() to re-read partition table.  
正在同步磁盘。  
```  
使用mkfs.ext4来对/dev/sdb1进行格式化：  
```  
mkfs.ext4 /dev/sdb1  
mke2fs 1.42.9 (28-Dec-2013)  
文件系统标签=  
OS type: Linux  
块大小=4096 (log=2)  
分块大小=4096 (log=2)  
Stride=0 blocks, Stripe width=0 blocks  
1310720 inodes, 5242624 blocks  
262131 blocks (5.00%) reserved for the super user  
第一个数据块=0  
Maximum filesystem blocks=2153775104  
160 block groups  
32768 blocks per group, 32768 fragments per group  
8192 inodes per group  
Superblock backups stored on blocks:  
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,  
	4096000  
Allocating group tables: 完成  
正在写入inode表: 完成  
Creating journal (32768 blocks): 完成  
Writing superblocks and filesystem accounting information: 完成  
```  
将硬盘设备挂载到/opt/c8o目录。  
mkdir /opt/c8o  
mount /dev/sdb1 /opt/c8o/  
设置系统启动后自动挂载该硬盘设备。  
echo /dev/sdb1 /opt/c8o ext4 defaults 0 0 >> /etc/fstab  
  
  
另外说几条用于日常了解硬盘使用情况的命令：  
---  
  
df命令用于查看挂载点信息与磁盘使用量，格式为：“df [选项] [文件]”。  
查看挂载信息与硬盘使用量:“df -h”  
```  
参数	作用  
-a	显示出所有的文件系统（包括虚拟的）  
--total	展出出总体使用量  
-h	更易读的容量格式如1K,234M,2G…  
-i	展示出Inode的信息（默认是磁盘使用信息）  
-T	显示出文件系统的类型  
```  
查看到所有已挂载的挂载信息与硬盘使用情况：  
  
```  
df -h  
文件系统                 容量  已用  可用 已用% 挂载点  
/dev/mapper/centos-root   17G  3.1G   14G   19% /  
devtmpfs                 899M     0  899M    0% /dev  
tmpfs                    910M     0  910M    0% /dev/shm  
tmpfs                    910M  9.5M  901M    2% /run  
tmpfs                    910M     0  910M    0% /sys/fs/cgroup  
/dev/sda1               1014M  233M  782M   23% /boot  
tmpfs                    910M   12K  910M    1% /var/lib/rancher/k3s/agent/kubelet/pods/fed3d189-b345-11e9-bf3a-000c294a91b6/volumes/kubernetes.io~secret/coredns-token-9x7r2  
overlay                   17G  3.1G   14G   19% /var/lib/docker/overlay2/dd7253b203619df31f4775e2131f3525dec14a9b4206e73c9b2abfffe3e0d0d3/merged  
shm                       64M     0   64M    0% /var/lib/docker/containers/c44d26b2c57f66563036509647f65d9ce8f6f8fbf6342714899790f643e79869/mounts/shm  
overlay                   17G  3.1G   14G   19% /var/lib/docker/overlay2/272cdec3a6f8d01c0f1919c7bc65db326bc92a45022f1186dcecb66b6a4c920c/merged  
tmpfs                    182M     0  182M    0% /run/user/0  
/dev/sdb1                 20G   45M   19G    1% /opt/c8o  
  
```  
```  
  
du命令用于查看磁盘的使用量，格式为：“ du [选项] [文件]”。  
```  
参数	作用  
-a	评估每个文件而非目录整体占用量。  
-c	评估每个文件并计算出总占用量总和。  
-h	更易读的容量格式如1K,234M,2G…  
-s	仅显示占用量总和。  
```  
  
查看某个目录中各文件夹所占空间:  
```  
du -sh /opt/c8o/  
24K	/opt/c8o/  
```
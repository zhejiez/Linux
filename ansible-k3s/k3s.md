# ansible-k3s
--------------------- 
>前言:公司打算对外销售项目,因为是微服务,不使用容器部署复杂,k8s太占资源,个人觉得swarm有些功能没k8s好用,最后决定使用k3s.我已经用ansible写好Ansible-Playbook了,这里主要讲这个文件来让大家了解部署k3s,虽然k3s部署已经够简单了,但是多台机器每次都得手动输入很麻烦,所以使用ansible部署
## 一,架构与文件讲解
所有操作都在主节点:
集群架构
Master:192.168.1.191   node:192.168.1.12 192.168.1.231
master目录结构:
[root@c8o k3s]# pwd  
/opt/k3s  
├── install  
│   ├── 1_master.sh  #安装准备脚本  
│   └── 2_k3s.yml     #部署k3s脚本  
└── str  
    ├── ansible  
    │   └── hosts        #ansible hosts文件  
    ├── k3s                #k3s二进制文件  
    ├── k3s.sh           #k3s安装脚本  
    ├── node.sh         #node节点运行k3s脚本requirements.txt  
    ├── requirements.txt   #pip安装ansible  
    └── pause.tar       #pause:3.1  没这个会一直停在拉取镜像阶段  
hosts文件,因为我的节点有点少,并且密码不一样,就这样写了,后续添加有点麻烦,可以添加个组变量,,但是需要用户名密码一样
cat /opt/k3s/str/ansible/hosts
```
[master]
127.0.0.1  ansible_ssh_user="root" ansible_ssh_pass="Ah6b^aV8nkbs&ECy" ansible_ssh_port=50024
[node]
172.17.57.241 ansible_ssh_user="root" ansible_ssh_pass="Ah6b^aV8nkbs&ECy" ansible_ssh_port=50024
172.17.57.239 ansible_ssh_user="root" ansible_ssh_pass="Ah6b^aV8nkbs&ECy" ansible_ssh_port=50024
```
1_master.sh文件讲解
```
#!/bin/bash
ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -q      #生成秘钥
yum -y install epel-release    #配置yum仓库
yum update -y           #更新系统       
yum -y install python-pip sshpass   #sshpass用来ansible传输秘钥
pip install -r /opt/k3s/str/requirements.txt   #安装ansible,不用yum装是因为总是404不是很稳定
cp -r /opt/k3s/str/ansible /etc     #拷贝ansible的hosts文件
```
2_k3s.yml文件讲解
```
- hosts: master,node        
  tasks:
  - name: "拷贝秘钥"
    authorized_key:
      user: root
      key: "{{ lookup('file', '/root/.ssh/id_rsa.pub') }}"      #这个主要用来拷贝秘钥,防止以后修改密码后连接不到
  - name: "添加hosts"
    shell: echo $(hostname -I | awk '{print $1}') $(hostname) >> /etc/hosts          #添加hosts,没这步k3s在启动的时候会报找不到主机名的错误
  - name: "关闭selinux"
    shell: sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
  - name: "拷贝k3s执行文件"
    copy:
      src=/opt/k3s/str/k3s
      dest=/usr/local/bin/k3s
  - name: "添加执行权限"
    shell: chmod +x /usr/local/bin/k3s
  - name: "关闭防火墙"
    service: name=firewalld enabled=no daemon_reload=no state=stopped
  - name: "yum安装环境"
    yum: name=yum-utils,device-mapper-persistent-data,lvm2 state=installed
  - name: "使用阿里源"
    shell: yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  - name: "yum安装docker"
    yum: name=docker-ce state=installed
  - name: "启动docker"
    service: name=docker enabled=yes daemon_reload=yes state=restarted

- hosts: master
  tasks:
  - name: "加载pause镜像"
    shell: docker load -i /opt/k3s/str/pause.tar
  - name: "启动k3s"
    shell: cat /opt/k3s/str/k3s.sh |INSTALL_K3S_EXEC="--docker --no-deploy traefik" sh -  #--docker 表示使用docker作为默认容器, --no-deploy traefik表示不安装traefik
  - name: "修改配置文件"
    shell: sed -i "s/主节点ip/$(hostname -I | awk '{print $1}')/g" /opt/k3s/str/node.sh
  - name: "修改主节点key"
    shell: sed -i "s/k3s_token/$(cat /var/lib/rancher/k3s/server/node-token)/g" /opt/k3s/str/node.sh

- hosts: node
  tasks:
  - name: "创建k3s目录"
    shell: mkdir /opt/k3s
  - name: "拷贝文件"
    copy:
      src=/opt/k3s/str/pause.tar
      dest=/opt/k3s/pause.tar
  - name: "拷贝k3s执行文件"
    copy:
      src=/opt/k3s/str/k3s.sh
      dest=/opt/k3s/k3s.sh
  - name: "拷贝node文件"
    copy:
      src=/opt/k3s/str/node.sh
      dest=/opt/k3s/node.sh
  - name: "加载pause镜像"
    shell: docker load -i /opt/k3s/pause.tar
  - name: "node安装k3s"
    shell: chmod +x /opt/k3s/node.sh 
    shell: sh /opt/k3s/node.sh 
 ```

## 二,部署与检查
下载部署文件:
https://github.com/zhejiez/Linux/tree/master/ansible-k3s
1,修改hosts文件
vim /opt/k3s/str/ansible/hosts
cat /opt/k3s/str/ansible/hosts
```
[master]
127.0.0.1  ansible_ssh_user="root" ansible_ssh_pass="Ah6b^aV8nkbs&ECy" ansible_ssh_port=50024
[node]
172.17.57.241 ansible_ssh_user="root" ansible_ssh_pass="Ah6b^aV8nkbs&ECy" ansible_ssh_port=50024
172.17.57.239 ansible_ssh_user="root" ansible_ssh_pass="Ah6b^aV8nkbs&ECy" ansible_ssh_port=50024
```
2,部署前准备:
chmox +x /opt/k3s/1_master.sh
sh /opt/k3s/1_master.sh
3,测试,如下表示正常
```
ansible all -m ping
172.17.57.239 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```
部署k3s,一般情况部署不会报错(无视粉色提示),报错请留言
ansible-playbook /opt/k3s/install/2_k3s.yml
查看 ,两个节点正常启用
```
kubectl get nodes
NAME     STATUS   ROLES    AGE   VERSION
master   Ready    master   24h   v1.14.3-k3s.1
node-1   Ready    worker   24h   v1.14.3-k3s.1
```
>报错
>kubectl get pod --all-namespaces发现pod一直处于ContainerCreating状态是因为缺少k8s.gcr.io/pause:3.1镜像
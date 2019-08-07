# ansible-k3s
--------------------- 

>前言:公司打算对外销售项目,因为是微服务,不使用容器部署复杂,k8s太占资源,个人觉得swarm有些功能没k8s好用,最后决定使用k3s.我已经用ansible写好Ansible-Playbook了,这里主要讲这个文件来让大家了解部署k3s,虽然k3s部署已经够简单了,但是多台机器每次都得手动输入很麻烦,所以使用ansible部署,官网的k3s.sh脚本有点问题,我做了下修改

ansible部署k3s  
拉取部署文件:  
git clone https://github.com/zhejiez/ansible-k3s.git  
1,修改hosts文件  
cat /opt/k3s/str/ansible/hosts  
[master]  
127.0.0.1  ansible_ssh_user="root" ansible_ssh_pass="qwe" ansible_ssh_port=22  
[node]  
192.168.1.12 ansible_ssh_user="root" ansible_ssh_pass="qweasd" ansible_ssh_port=22  
[add_node]  
2,部署前准备:  
chmox +x /opt/k3s/1_master.sh  
sh /opt/k3s/1_master.sh  
3,测试  
ansible all -m ping  
ansible-playbook /opt/k3s/install/2_k3s.yml  
查看 ,两个节点正常启用  
kubectl get nodes  
三,添加node节点
1,修改hosts,在[add_node]后面添加ip  
cat /etc/ansible/hosts  
[master]  
127.0.0.1  ansible_ssh_user="root" ansible_ssh_pass="qwe" ansible_ssh_port=22  
[node]  
192.168.1.12 ansible_ssh_user="root" ansible_ssh_pass="qweasd" ansible_ssh_port=22  
[add_node]  
192.168.1.12 ansible_ssh_user="root" ansible_ssh_pass="qweasd" ansible_ssh_port=22  
  
2,安装k3s  
ansible add_node -m ping  
ansible-playbook /opt/k3s/33_node.yml  
  
参考https://rancher.com/docs/k3s/latest/en/quick-start/  
因为本人也是小白,自己摸索,后续添加主节点教程  

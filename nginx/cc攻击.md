>```记录一次cc攻击,虽然没完全解决,但是屏蔽大量攻击,减轻服务器负担,大体上是先做访问nginx的限制,一秒只能访问5次,超过五次就会报503的错误,fail2ban提取nginx几秒内有503的日志,把这个ip加到firewalld里```  
贴吧id：喆劼xz，日期：2020年4月19日
一,配置nginx:  
conf.d/wxh.super.co.conf  
```  
limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;  
server {  
  
server_name wxh.super.com;  
listen      *:80;  
root  /opt/web_html/wxh.super.com;  
access_log logs/wxh.super.com_access.log main;  
error_log  logs/wxh.super.com_error.log;  
if  ($request_uri  ~* "kto0a81u") {  
return 503;  
}  #只要访问以kto0a81u为结尾的连接自动跳到503  
error_page  404  /view/404.html;  
  
location ~ landingPage  
{  
  rewrite ^.*$ /landPage.html last;  
}  
location /  
{  
    allow 122.14.1.21;     #白名单  
    limit_req zone=one burst=10; #限制访问/user/login链接每个ip一秒10次  
    try_files $uri $uri/ @router;  
    index index.html;  
}  
  
location @router  
{  
   rewrite ^.*$ /index.html last;  
}  
}  
```  
nginx.config:  
>这个很关键,主要fail2ban用来提取关键字,上面的配置文件访问过道会报出503的错误  
```  
http {  
    .....  
    log_format  main  '$remote_addr $status $request $body_bytes_sent [$time_local]  $http_user_agent $http_referer  $http_x_forwarded_for $upstream_addr $upstream_status $upstream_cache_status $upstream_response_time';  
    .....  
}  
```  
  
二,fail2ban  
1,安装:  
yum -y install epel-release  
yum -y install fail2ban  
2.准备fail2ban,注意,里面任何文件都不要删,否则会报错  
目录结构:  
/etc/fail2ban                 ## fail2ban 服务配置目录  
/etc/fail2ban/action.d        ## firewalld 、mail 等动作文件目录  
/etc/fail2ban/filter.d        ## 条件匹配文件目录，过滤日志关键内容  
/etc/fail2ban/jail.d          ## 规则文件目录，按具体防护项目分成文件  
/etc/fail2ban/jail.local      ## 默认规则文件  
/etc/fail2ban/jail.conf       ## fail2ban 防护配置文件  
/etc/fail2ban/fail2ban.conf   ## fail2ban 配置文件，定义日志级别、日志、sock 文件位置等  
  
修改00-firewalld.conf  
cat /etc/fail2ban/jail.d/00-firewalld.conf  
```  
# This file is part of the fail2ban-firewalld package to configure the use of  
# the firewalld actions as the default actions.  You can remove this package  
# (along with the empty fail2ban meta-package) if you do not use firewalld  
[DEFAULT]  
banaction = firewallcmd-ipset   #使用firewallcmd  
action = %(action_mwl)s         #触发后动作  
```  
添加jail.local  
cat /etc/fail2ban/jail.local  
```  
[DEFAULT]  
findtime    = 3600                      #扫描时间范文  
bantime     = 86400                     #屏蔽时间，单位为秒  
maxretry    = 5                         #尝试次数  
ignoreip    = 127.0.0.1,172.17.57.0/24  #白名单  
```  
3,防止ssh暴力破解:  
cat /etc/fail2ban/jail.d/sshd.local  
```  
[sshd]                                  #名字,查看封禁ip的时候用到  
enabled     = true                      #开启状态  
filter      = sshd                      #规则名称，必须填写位于filter.d目录里面的规则，sshd是fail2ban内置规则  
action      = %(action_mwl)s  
logpath     = /var/log/secure           #日志路径  
```  
4,防止cc登录  
cat /etc/fail2ban/filter.d/nginx.conf  
```  
[Definition]  
failregex =<HOST> 503.(GET|POST)*.*HTTP/1.*$  
ignoreregex =  
```  
cat /etc/fail2ban/jail.d/nginx.local  
```  
[nginx]  
enabled = true  
port = http,https              #端口  
filter = nginx  
action = %(action_mwl)s  
bantime  = 86400  
findtime = 1  
maxretry = 5  
logpath = /opt/nginx-1.13.7-prod/logs/openapi.juxinda360.cn_access.log  
```  
重启服务  
systemctl restart fail2ban  
查看被封禁的ip,别问我为什么这么多ip,这些都是攻击我们服务器的ip  
fail2ban-client status nginx  
```  
Status for the jail: nginx  
|- Filter  
|  |- Currently failed:	0  
|  |- Total failed:	0  
|  `- File list:	/opt/nginx-1.13.7-prod/logs/openapi.juxinda360.cn_access.log  
`- Actions  
   |- Currently banned:	79  
   |- Total banned:	79  
   `- Banned IP list:	1.193.69.212 1.56.17.17 1.56.21.168 1.56.22.168 1.56.23.197 1.56.23.20 1.56.23.27 1.58.169.134 1.62.145.3 106.91.160.102 112.49.224.157 113.127.205.129 113.232.162.157 113.232.165.90 113.232.176.51 113.239.196.205 113.4.124.189 113.4.176.241 113.4.251.111 114.101.211.22 117.136.30.21 117.136.75.203 117.136.81.63 117.28.80.103 119.115.240.68 119.118.115.196 119.118.126.237 119.52.40.18 119.52.40.218 119.52.58.142 119.52.59.80 119.55.114.184 119.55.119.191 119.55.75.28 123.147.248.213 139.214.144.40 175.168.15.107 175.172.176.235 175.174.95.244 182.149.201.235 202.110.40.130 218.24.58.240 218.7.116.157 218.7.116.2 220.195.66.70 220.197.208.38 220.201.199.241 221.200.177.210 221.200.184.244 221.203.85.168 221.206.200.181 221.206.200.209 221.206.200.222 221.206.200.233 221.206.200.236 221.206.200.64 221.206.201.114 221.206.201.124 221.206.201.173 221.206.201.95 221.210.130.139 221.210.130.150 223.104.178.83 223.104.251.59 223.104.3.184 223.104.65.233 223.104.96.86 42.176.11.18 42.176.9.149 42.178.136.167 42.185.16.167 42.185.18.225 42.185.20.30 42.185.20.44 42.185.21.115 42.185.23.104 42.55.16.57 42.59.233.96 42.86.58.84  
```

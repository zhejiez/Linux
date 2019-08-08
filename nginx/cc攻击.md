>记录一次cc攻击,虽然没完全解决,但是屏蔽大量攻击,减轻服务器负担,大体上是先做访问nginx的限制,一秒只能访问5次,超过五次就会报503的错误,fail2ban提取nginx几秒内有503的日志,把这个ip加到firewalld里

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
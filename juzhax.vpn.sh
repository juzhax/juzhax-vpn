#!/bin/bash -x

#
# juzhax/VPN
#
# Installs a PPTP for CentOS
#
# @author juzhax
#

(

VPN_IP=`curl ipv4.icanhazip.com>/dev/null 2>&1`

VPN_USER="myuser"
VPN_PASS="mypass"

VPN_LOCAL="192.168.0.150"
VPN_REMOTE="192.168.0.151-200"

wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && sudo rpm -Uvh epel-release-6*.rpm
yum install pptpd.x86_64 -y

echo "option /etc/ppp/options.pptpd" >> /etc/pptpd.conf
echo "localip $VPN_LOCAL" >> /etc/pptpd.conf # Local IP address of your VPN server
echo "remoteip $VPN_REMOTE" >> /etc/pptpd.conf # Scope for your home network

echo "$VPN_USER * $VPN_PASS *" >> /etc/ppp/chap-secrets

echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd # Google DNS Primary
echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd # Google DNS Secondary
echo "lock" >> /etc/ppp/options.pptpd
echo "name pptpd" >> /etc/ppp/options.pptpd
echo "require-mschap-v2" >> /etc/ppp/options.pptpd
echo "require-mppe-128" >> /etc/ppp/options.pptpd

sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

sysctl -p
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 1723 -j ACCEPT
iptables -A INPUT -i eth0 -p gre -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i ppp+ -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o ppp+ -j ACCEPT
service iptables save
service iptables restart
chkconfig pptpd on

/etc/init.d/pptpd restart-kill && /etc/init.d/pptpd start


echo -e '\E[37;44m'"\033[1m Installation Log: /var/log/vpn-installer.log \033[0m"
echo -e '\E[37;44m'"\033[1m You can now connect to your VPN via your external IP ($VPN_IP)\033[0m"

echo -e '\E[37;44m'"\033[1m Username: $VPN_USER\033[0m"
echo -e '\E[37;44m'"\033[1m Password: $VPN_PASS\033[0m"

) 2>&1 | tee /var/log/vpn-installer.log

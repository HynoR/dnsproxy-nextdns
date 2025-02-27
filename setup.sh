#!/usr/bin/env bash

Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/dnsproxy/releases/latest | grep tag_name | cut -d '"' -f 4)

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

checkos(){
    if [[ -f /etc/redhat-release ]];then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian";then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    elif cat /proc/version | grep -q -E -i "debian";then
        OS=Debian
    elif cat /proc/version | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    else
        echo "Not supported OS, Please reinstall OS and try again."
        exit 1
    fi
}

get_arch(){
get_arch=`arch`
    if [[ $get_arch =~ "x86_64" ]];then
       ARCHV=amd64
    elif [[ $get_arch =~ "aarch64" ]];then
       ARCHV=arm64
    elif [[ $get_arch =~ "mips64" ]];then
       ARCHV=mips64
    else
       echo "Unknown Architecture!!"
       exit 1
    fi
}

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

install(){
    echo -e "${Green}即将安装...${Font}"
    if [ "${OS}" == 'CentOS' ];then
        yum install epel-release -y
        yum install -y wget curl tar
        wget "https://github.com/AdguardTeam/dnsproxy/releases/download/${VERSION}/dnsproxy-linux-${ARCHV}-${VERSION}.tar.gz" -O /tmp/dnsproxy.tar.gz
        tar -xzvf /tmp/dnsproxy.tar.gz -C /tmp/
        mv /tmp/linux-${ARCHV}/dnsproxy /usr/bin/dnsproxy
        chmod +x /usr/bin/dnsproxy
        rm -rf /tmp/dnsproxy.tar.gz /tmp/linux-${ARCHV}/
    else
        apt-get -y update
        apt-get install -y wget curl tar
        wget "https://github.com/AdguardTeam/dnsproxy/releases/download/${VERSION}/dnsproxy-linux-${ARCHV}-${VERSION}.tar.gz" -O /tmp/dnsproxy.tar.gz
        tar -xzvf /tmp/dnsproxy.tar.gz -C /tmp/
        mv /tmp/linux-${ARCHV}/dnsproxy /usr/bin/dnsproxy
        chmod +x /usr/bin/dnsproxy
        rm -rf /tmp/dnsproxy.tar.gz /tmp/linux-${ARCHV}/
    fi
}

tips(){
    echo -e "${Green}done!${Font}"
    echo -e "${Blue}请将 /etc/resolv.conf 改为 nameserver 127.0.0.1${Font}"
    echo -e "${Blue}可使用 bash <(curl -sSL "https://raw.githubusercontent.com/9bingyin/Fast-DoH/master/lockdns.sh") 锁定DNS${Font}"
    echo -e "${Blue}如遇53端口占用请查看 https://www.moeelf.com/archives/270.html 或卸载其他 DNS 程序${Font}"
}

main(){
    rootness
    checkos
    get_arch
    disable_selinux
    install
}

nextdns(){
    main
    if [ -e 文件路径 ]; then
        echo "文件存在"
        exit 0
    else
        echo "文件不存在"
    fi
    wget -O /etc/systemd/system/dnsproxy-upstream.service https://raw.githubusercontent.com/HynoR/dnsproxy-nextdns/main/services/upstream.service
    wget -O /etc/systemd/system/dnsproxy.service https://raw.githubusercontent.com/HynoR/dnsproxy-nextdns/main/services/nextdns.service
    read -p "NextDNS ID：" query
    sed -i "s|dns-query|${query}|g" /etc/systemd/system/dnsproxy.service
    systemctl daemon-reload
    systemctl restart dnsproxy-upstream
    systemctl enable dnsproxy-upstream
    systemctl restart dnsproxy
    systemctl enable dnsproxy
    tips
}

nextdns

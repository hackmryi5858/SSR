#!/bin/bash
# shadowsocksR/SSRһ����װ�̳�
# Author: hijk<https://hijk.art>


RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

V6_PROXY=""
IP=`curl -sL -4 ip.sb`
if [[ "$?" != "0" ]]; then
    IP=`curl -sL -6 ip.sb`
    V6_PROXY="https://gh.hijk.art/"
fi

FILENAME="ShadowsocksR-v3.2.2"
URL="${V6_PROXY}https://github.com/shadowsocksrr/shadowsocksr/archive/3.2.2.tar.gz"
BASE=`pwd`

OS=`hostnamectl | grep -i system | cut -d: -f2`

CONFIG_FILE="/etc/shadowsocksR.json"
SERVICE_FILE="/etc/systemd/system/shadowsocksR.service"
NAME="shadowsocksR"

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}


checkSystem() {
    result=$(id | awk '{print $1}')
    if [[ $result != "uid=0(root)" ]]; then
        colorEcho $RED " ����root���ִ�иýű�"
        exit 1
    fi

    res=`which yum 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        res=`which apt 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " ����֧�ֵ�Linuxϵͳ"
            exit 1
        fi
        PMT="apt"
        CMD_INSTALL="apt install -y "
        CMD_REMOVE="apt remove -y "
        CMD_UPGRADE="apt update && apt upgrade -y; apt autoremove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
        CMD_REMOVE="yum remove -y "
        CMD_UPGRADE="yum update -y"
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " ϵͳ�汾���ͣ������������°汾"
        exit 1
    fi
}

getData() {
    echo ""
    read -p " ������SSR�����루��������������ɣ�:" PASSWORD
    [[ -z "$PASSWORD" ]] && PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    echo ""
    colorEcho $BLUE " ���룺 $PASSWORD"

    echo ""
    while true
    do
        read -p " ������SSR�Ķ˿ں�[1-65535]:" PORT
        [[ -z "$PORT" ]] && PORT=`shuf -i1025-65000 -n1`
        if [[ "${PORT:0:1}" = "0" ]]; then
            echo -e " ${RED}�˿ڲ�����0��ͷ${PLAIN}"
            exit 1
        fi
        expr $PORT + 0 &>/dev/null
        if [[ $? -eq 0 ]]; then
            if [ $PORT -ge 1 ] && [ $PORT -le 65535 ]; then
                echo ""
                colorEcho $BLUE " �˿ںţ� $PORT"
                break
            else
                colorEcho $RED " ������󣬶˿ں�Ϊ1-65535������"
            fi
        else
            colorEcho $RED " ������󣬶˿ں�Ϊ1-65535������"
        fi
    done

    echo ""
    colorEcho $BLUE " ��ѡ��SSR�ļ��ܷ�ʽ:" 
    echo "  1)aes-256-cfb"
    echo "  2)aes-192-cfb"
    echo "  3)aes-128-cfb"
    echo "  4)aes-256-ctr"
    echo "  5)aes-192-ctr"
    echo "  6)aes-128-ctr"
    echo "  7)aes-256-cfb8"
    echo "  8)aes-192-cfb8"
    echo "  9)aes-128-cfb8"
    echo "  10)camellia-128-cfb"
    echo "  11)camellia-192-cfb"
    echo "  12)camellia-256-cfb"
    echo "  13)chacha20-ietf"
    read -p " ��ѡ����ܷ�ʽ��Ĭ��aes-256-cfb��" answer
    if [[ -z "$answer" ]]; then
        METHOD="aes-256-cfb"
    else
        case $answer in
        1)
            METHOD="aes-256-cfb"
            ;;
        2)
            METHOD="aes-192-cfb"
            ;;
        3)
            METHOD="aes-128-cfb"
            ;;
        4)
            METHOD="aes-256-ctr"
            ;;
        5)
            METHOD="aes-192-ctr"
            ;;
        6)
            METHOD="aes-128-ctr"
            ;;
        7)
            METHOD="aes-256-cfb8"
            ;;
        8)
            METHOD="aes-192-cfb8"
            ;;
        9)
            METHOD="aes-128-cfb8"
            ;;
        10)
            METHOD="camellia-128-cfb"
            ;;
        11)
            METHOD="camellia-192-cfb"
            ;;
        12)
            METHOD="camellia-256-cfb"
            ;;
        13)
            METHOD="chacha20-ietf"
            ;;
        *)
            colorEcho $RED " ��Ч��ѡ��ʹ��Ĭ�ϼ��ܷ�ʽ"
            METHOD="aes-256-cfb"
        esac
    fi
    echo ""
    colorEcho $BLUE " ���ܷ�ʽ�� $METHOD"

    echo ""
    colorEcho $BLUE " ��ѡ��SSRЭ�飺"
    echo "   1)origin"
    echo "   2)verify_deflate"
    echo "   3)auth_sha1_v4"
    echo "   4)auth_aes128_md5"
    echo "   5)auth_aes128_sha1"
    echo "   6)auth_chain_a"
    echo "   7)auth_chain_b"
    echo "   8)auth_chain_c"
    echo "   9)auth_chain_d"
    echo "   10)auth_chain_e"
    echo "   11)auth_chain_f"
    read -p " ��ѡ��SSRЭ�飨Ĭ��origin��" answer
    if [[ -z "$answer" ]]; then
        PROTOCOL="origin"
    else
        case $answer in
        1)
            PROTOCOL="origin"
            ;;
        2)
            PROTOCOL="verify_deflate"
            ;;
        3)
            PROTOCOL="auth_sha1_v4"
            ;;
        4)
            PROTOCOL="auth_aes128_md5"
            ;;
        5)
            PROTOCOL="auth_aes128_sha1"
            ;;
        6)
            PROTOCOL="auth_chain_a"
            ;;
        7)
            PROTOCOL="auth_chain_b"
            ;;
        8)
            PROTOCOL="auth_chain_c"
            ;;
        9)
            PROTOCOL="auth_chain_d"
            ;;
        10)
            PROTOCOL="auth_chain_e"
            ;;
        11)
            PROTOCOL="auth_chain_f"
            ;;
        *)
            colorEcho $RED " ��Ч��ѡ��ʹ��Ĭ��Э��"
            PROTOCOL="origin"
        esac
    fi
    echo ""
    colorEcho $BLUE " SSRЭ�飺 $PROTOCOL"

    echo ""
    colorEcho $BLUE " ��ѡ��SSR����ģʽ��"
    echo "   1)plain"
    echo "   2)http_simple"
    echo "   3)http_post"
    echo "   4)tls1.2_ticket_auth"
    echo "   5)tls1.2_ticket_fastauth"
    read -p " ��ѡ�����ģʽ��Ĭ��plain��" answer
    if [[ -z "$answer" ]]; then
        OBFS="plain"
    else
        case $answer in
        1)
            OBFS="plain"
            ;;
        2)
            OBFS="http_simple"
            ;;
        3)
            OBFS="http_post"
            ;;
        4)
            OBFS="tls1.2_ticket_auth"
            ;;
        5)
            OBFS="tls1.2_ticket_fastauth"
            ;;
        *)
            colorEcho $RED " ��Ч��ѡ��ʹ��Ĭ�ϻ���ģʽ"
            OBFS="plain"
        esac
    fi
    echo ""
    colorEcho $BLUE " ����ģʽ�� $OBFS"
}

status() {
    res=`which python 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        echo 0
        return
    fi
    if [[ ! -f $CONFIG_FILE ]]; then
        echo 1
        return
    fi
    port=`grep server_port $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep python`
    if [[ -z "$res" ]]; then
        echo 2
    else
        echo 3
    fi
}

statusText() {
    res=`status`
    case $res in
        2)
            echo -e ${GREEN}�Ѱ�װ${PLAIN} ${RED}δ����${PLAIN}
            ;;
        3)
            echo -e ${GREEN}�Ѱ�װ${PLAIN} ${GREEN}��������${PLAIN}
            ;;
        *)
            echo -e ${RED}δ��װ${PLAIN}
            ;;
    esac
}

preinstall() {
    $PMT clean all
    [[ "$PMT" = "apt" ]] && $PMT update
    #echo $CMD_UPGRADE | bash
    echo ""
    colorEcho $BLUE " ��װ��Ҫ���"
    if [[ "$PMT" = "yum" ]]; then
        $CMD_INSTALL epel-release
    fi
    $CMD_INSTALL curl wget vim net-tools libsodium* openssl unzip tar qrencode
    res=`which wget 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL wget
    res=`which netstat 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL net-tools
    res=`which python 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        ln -s /usr/bin/python3 /usr/bin/python
    fi

    if [[ -s /etc/selinux/config ]] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

installSSR() {
    if [[ ! -d /usr/local/shadowsocks ]]; then
        colorEcho $BLUE " ���ذ�װ�ļ�"
        if ! wget --no-check-certificate -O ${FILENAME}.tar.gz ${URL}; then
            echo -e " [${RED}Error${PLAIN}] �����ļ�ʧ��!"
            exit 1
        fi

        tar -zxf ${FILENAME}.tar.gz
        mv shadowsocksr-3.2.2/shadowsocks /usr/local
        if [[ ! -f /usr/local/shadowsocks/server.py ]]; then
            colorEcho $RED " $OS ��װʧ�ܣ��뵽 https://hijk.art ��վ����"
            cd ${BASE} && rm -rf shadowsocksr-3.2.2 ${FILENAME}.tar.gz
            exit 1
        fi
        cd ${BASE} && rm -rf shadowsocksr-3.2.2 ${FILENAME}.tar.gz
    fi

cat > $SERVICE_FILE <<-EOF
[Unit]
Description=shadowsocksR
Documentation=https://hijk.art/
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
LimitNOFILE=32768
ExecStart=/usr/local/shadowsocks/server.py -c $CONFIG_FILE -d start
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable shadowsocksR
}

configSSR() {
    cat > $CONFIG_FILE<<-EOF
{
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "server_port":${PORT},
    "local_port":1080,
    "password":"${PASSWORD}",
    "timeout":600,
    "method":"${METHOD}",
    "protocol":"${PROTOCOL}",
    "protocol_param":"",
    "obfs":"${OBFS}",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
}

setFirewall() {
    res=`which firewall-cmd 2>/dev/null`
    if [[ $? -eq 0 ]]; then
        systemctl status firewalld > /dev/null 2>&1
        if [[ $? -eq 0 ]];then
            firewall-cmd --permanent --add-port=${PORT}/tcp
            firewall-cmd --permanent --add-port=${PORT}/udp
            firewall-cmd --reload
        else
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
            fi
        fi
    else
        res=`which iptables 2>/dev/null`
        if [[ $? -eq 0 ]]; then
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
            fi
        else
            res=`which ufw 2>/dev/null`
            if [[ $? -eq 0 ]]; then
                res=`ufw status | grep -i inactive`
                if [[ "$res" = "" ]]; then
                    ufw allow ${PORT}/tcp
                    ufw allow ${PORT}/udp
                fi
            fi
        fi
    fi
}

installBBR() {
    result=$(lsmod | grep bbr)
    if [[ "$result" != "" ]]; then
        colorEcho $GREEN " BBRģ���Ѱ�װ"
        INSTALL_BBR=false
        return
    fi
    res=`hostnamectl | grep -i openvz`
    if [ "$res" != "" ]; then
        colorEcho $YELLOW " openvz������������װ"
        INSTALL_BBR=false
        return
    fi
    
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    result=$(lsmod | grep bbr)
    if [[ "$result" != "" ]]; then
        colorEcho $GREEN " BBRģ��������"
        INSTALL_BBR=false
        return
    fi

    colorEcho $BLUE " ��װBBRģ��..."
    if [[ "$PMT" = "yum" ]]; then
        if [[ "$V6_PROXY" = "" ]]; then
            rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
            rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
            $CMD_INSTALL --enablerepo=elrepo-kernel kernel-ml
            $CMD_REMOVE kernel-3.*
            grub2-set-default 0
            echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
            INSTALL_BBR=true
        fi
    else
        $CMD_INSTALL --install-recommends linux-generic-hwe-16.04
        grub-set-default 0
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        INSTALL_BBR=true
    fi
}

showInfo() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSRδ��װ�����Ȱ�װ��${PLAIN}"
        return
    fi
    port=`grep server_port $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep python`
    [[ -z "$res" ]] && status="${RED}��ֹͣ${PLAIN}" || status="${GREEN}��������${PLAIN}"
    password=`grep password $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    method=`grep method $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    protocol=`grep protocol $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    obfs=`grep obfs $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    
    p1=`echo -n ${password} | base64 -w 0`
    p1=`echo -n ${p1} | tr -d =`
    res=`echo -n "${IP}:${port}:${protocol}:${method}:${obfs}:${p1}/?remarks=&protoparam=&obfsparam=" | base64 -w 0`
    res=`echo -n ${res} | tr -d =`
    link="ssr://${res}"

    echo ""
    echo ============================================
    echo -e " ${BLUE}ssr����״̬��${PLAIN}${status}"
    echo -e " ${BLUE}ssr�����ļ���${PLAIN}${RED}$CONFIG_FILE${PLAIN}"
    echo ""
    echo -e " ${RED}ssr������Ϣ��${PLAIN}"
    echo -e "   ${BLUE}IP(address):${PLAIN}  ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}�˿�(port)��${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}����(password)��${PLAIN}${RED}${password}${PLAIN}"
    echo -e "   ${BLUE}���ܷ�ʽ(method)��${PLAIN} ${RED}${method}${PLAIN}"
    echo -e "   ${BLUE}Э��(protocol)��${PLAIN} ${RED}${protocol}${PLAIN}"
    echo -e "   ${BLUE}����(obfuscation)��${PLAIN} ${RED}${obfs}${PLAIN}"
    echo
    echo -e " ${BLUE}ssr����:${PLAIN} $link"
    #qrencode -o - -t utf8 $link
}

showQR() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSRδ��װ�����Ȱ�װ��${PLAIN}"
        return
    fi
    port=`grep server_port $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep python`
    [[ -z "$res" ]] && status="${RED}��ֹͣ${PLAIN}" || status="${GREEN}��������${PLAIN}"
    password=`grep password $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    method=`grep method $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    protocol=`grep protocol $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    obfs=`grep obfs $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    
    p1=`echo -n ${password} | base64 -w 0`
    p1=`echo -n ${p1} | tr -d =`
    res=`echo -n "${IP}:${port}:${protocol}:${method}:${obfs}:${p1}/?remarks=&protoparam=&obfsparam=" | base64 -w 0`
    res=`echo -n ${res} | tr -d =`
    link="ssr://${res}"
    qrencode -o - -t utf8 $link
}

bbrReboot() {
    if [[ "${INSTALL_BBR}" == "true" ]]; then
        echo  
        colorEcho $BLUE  " ΪʹBBRģ����Ч��ϵͳ����30�������"
        echo  
        echo -e " �����԰� ctrl + c ȡ���������Ժ����� ${RED}reboot${PLAIN} ����ϵͳ"
        sleep 30
        reboot
    fi
}


install() {
    getData
    preinstall
    installBBR
    installSSR
    configSSR
    setFirewall

    start
    showInfo
    
    bbrReboot
}

reconfig() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSRδ��װ�����Ȱ�װ��${PLAIN}"
        return
    fi
    getData
    configSSR
    setFirewall
    restart

    showInfo
}

uninstall() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSRδ��װ�����Ȱ�װ��${PLAIN}"
        return
    fi

    echo ""
    read -p " ȷ��ж��SSR��(y/n)" answer
    [[ -z ${answer} ]] && answer="n"

    if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]]; then
        rm -f $CONFIG_FILE
        rm -f /var/log/shadowsocksr.log
        rm -rf /usr/local/shadowsocks
        systemctl disable shadowsocksR && systemctl stop shadowsocksR && rm -rf $SERVICE_FILE
    fi
    echo -e " ${RED}ж�سɹ�${PLAIN}"
}

start() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSδ��װ�����Ȱ�װ��${PLAIN}"
        return
    fi
    systemctl restart ${NAME}
    sleep 2
    port=`grep server_port $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep python`
    if [[ "$res" = "" ]]; then
        colorEcho $RED " SSR����ʧ�ܣ�����˿��Ƿ�ռ�ã�"
    else
        colorEcho $BLUE " SSR�����ɹ���"
    fi
}

restart() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSRδ��װ�����Ȱ�װ��${PLAIN}"
        return
    fi

    stop
    start
}

stop() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSRδ��װ�����Ȱ�װ��${PLAIN}"
        return
    fi
    systemctl stop ${NAME}
    colorEcho $BLUE " SSRֹͣ�ɹ�"
}

showLog() {
    tail /var/log/shadowsocksr.log
}

menu() {
    clear
    echo "#############################################################"
    echo -e "#             ${RED}ShadowsocksR/SSR һ����װ�ű�${PLAIN}               #"
    echo -e "# ${GREEN}����${PLAIN}: ������Խ(hijk)                                      #"
    echo -e "# ${GREEN}��ַ${PLAIN}: https://hijk.art                                    #"
    echo -e "# ${GREEN}��̳${PLAIN}: https://hijk.club                                   #"
    echo -e "# ${GREEN}TGȺ${PLAIN}: https://t.me/hijkclub                               #"
    echo -e "# ${GREEN}YoutubeƵ��${PLAIN}: https://youtube.com/channel/UCYTB--VsObzepVJtc9yvUxQ #"
    echo "#############################################################"
    echo ""

    echo -e "  ${GREEN}1.${PLAIN}  ��װSSR"
    echo -e "  ${GREEN}2.  ${RED}ж��SSR${PLAIN}"
    echo " -------------"
    echo -e "  ${GREEN}4.${PLAIN}  ����SSR"
    echo -e "  ${GREEN}5.${PLAIN}  ����SSR"
    echo -e "  ${GREEN}6.${PLAIN}  ֹͣSSR"
    echo " -------------"
    echo -e "  ${GREEN}7.${PLAIN}  �鿴SSR����"
    echo -e "  ${GREEN}8.${PLAIN}  �鿴���ö�ά��"
    echo -e "  ${GREEN}9.  ${RED}�޸�SSR����${PLAIN}"
    echo -e "  ${GREEN}10.${PLAIN} �鿴SSR��־"
    echo " -------------"
    echo -e "  ${GREEN}0.${PLAIN} �˳�"
    echo 
    echo -n " ��ǰ״̬��"
    statusText
    echo 

    read -p " ��ѡ�����[0-10]��" answer
    case $answer in
        0)
            exit 0
            ;;
        1)
            install
            ;;
        2)
            uninstall
            ;;
        4)
            start
            ;;
        5)
            restart
            ;;
        6)
            stop
            ;;
        7)
            showInfo
            ;;
        8)
            showQR
            ;;
        9)
            reconfig
            ;;
        10)
            showLog
            ;;
        *)
            echo -e "$RED ��ѡ����ȷ�Ĳ�����${PLAIN}"
            exit 1
            ;;
    esac
}

checkSystem

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
    menu|install|uninstall|start|restart|stop|showInfo|showQR|showLog)
        ${action}
        ;;
    *)
        echo " ��������"
        echo " �÷�: `basename $0` [menu|install|uninstall|start|restart|stop|showInfo|showQR|showLog]"
        ;;
esac


#!/bin/bash
set -euo pipefail

command_arg="status"

if [ $# -lt 1 ]; then 
    echo "extra parameters will be ommited"
fi

if [ $# -eq 0 ]; then 
    command_arg="status"
else 
    command_arg=$1
fi

url_vpnclient="https://www.softether-download.com/files/softether/v4.41-9787-rtm-2023.03.14-tree/Linux/SoftEther_VPN_Client/64bit_-_Intel_x64_or_AMD64/softether-vpnclient-v4.41-9787-rtm-2023.03.14-linux-x64-64bit.tar.gz"
server_ip="127.0.0.1"
server_port="9000"
hub_name="VPN"
user_name="user"
user_password="user_password"
nic_address="192.168.30.203"

if [[ $url_vpnclient =~ /([^/]+)$ ]]; then 
    file_vpnclient=${BASH_REMATCH[1]}
fi

uninstall() {
    if [[ -f "/etc/systemd/system/vpnclient.service" ]]; then
        systemctl start vpnclient
        /opt/vpnclient/vpncmd localhost /CLIENT /CMD NicDelete vpn
        systemctl stop vpnclient
        systemctl disable vpnclient
    fi
    rm -rf /etc/systemd/system/vpnclient.service
    systemctl daemon-reload
    rm -rf /opt/vpnclient
    rm -rf /opt/$file_vpnclient
    if [[ -f "/etc/network/interfaces.d/softether_vpn" ]]; then
        rm -rf /etc/network/interfaces.d/softether_vpn
        systemctl restart networking
    fi    
}

install() {
    uninstall
    apt update
    apt install -y gcc g++ make curl net-tools ufw
    cd /opt
    curl -O $url_vpnclient
    tar xzvf $file_vpnclient
    cd vpnclient
    make 

    echo '[Unit]
    Description=SoftEther VPN Client
    After=network.target

    [Service]
    Type=forking
    ExecStart=/opt/vpnclient/vpnclient start
    ExecStop=/opt/vpnclient/vpnclient stop
    KillMode=process
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target' | tee /etc/systemd/system/vpnclient.service

    systemctl daemon-reload
    systemctl enable vpnclient
    systemctl start vpnclient
    sed -i $'s/^cn\\r$/en\\r/' /opt/vpnclient/lang.config
    systemctl restart vpnclient

    /opt/vpnclient/vpncmd localhost /CLIENT /CMD NicCreate vpn
    echo "# The softether vpn client interface" >> /etc/network/interfaces.d/softether_vpn
    echo "auto vpn_vpn" >> /etc/network/interfaces.d/softether_vpn
    echo "iface vpn_vpn inet static" >> /etc/network/interfaces.d/softether_vpn
    echo "address $nic_address" >> /etc/network/interfaces.d/softether_vpn
    echo "netmask 255.255.255.0" >> /etc/network/interfaces.d/softether_vpn
    systemctl restart networking
    /opt/vpnclient/vpncmd localhost /CLIENT /CMD AccountCreate vpn /SERVER:$server_ip:$server_port /HUB:$hub_name /USERNAME:$user_name /NICNAME:vpn_vpn
    /opt/vpnclient/vpncmd localhost /CLIENT /CMD AccountPasswordSet vpn /PASSWORD:$user_password /TYPE:standard
    /opt/vpnclient/vpncmd localhost /CLIENT /CMD AccountConnect vpn
    /opt/vpnclient/vpncmd localhost /CLIENT /CMD AccountStartupSet vpn
}

enable() {
    systemctl start vpnclient
}

disable () {
    systemctl stop vpnclient
}

echo_status() {
    left=$1
    right=$2
    total_width=30
    mid_width=$((total_width - ${#left} - ${#right}))
    mid=$(printf '%*s' $mid_width | tr ' ' '.')
    printf "%s%s%s\n" "$left" "$mid" "$right"
}

status() {
    echo "=============================="
    if ps aux | grep -q "[v]pnclient"; then
        echo_status "vpn client process" "YES"
    else 
        echo_status "vpn client process" "NO"
    fi
    echo "=============================="
}

if [[ "$command_arg" == "install" ]]; then
    install
elif [[ "$command_arg" == "uninstall" ]]; then
    uninstall
elif [[ "$command_arg" == "status" ]]; then 
    status
elif [[ "$command_arg" == "enable" ]]; then
    enable
elif [[ "$command_arg" == "disable" ]]; then
    disable
else 
    echo "Usage: $0 install | uninstall | status | enable | disable"
    exit 0
fi

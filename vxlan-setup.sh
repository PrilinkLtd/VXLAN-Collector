#!/bin/bash

RC_PATH=/etc/rc.local
VXLAN_PATH=/etc/vxlan

prefix_to_netmask() {
    local value=$((0xffffffff ^ ((1 << (32 - $1)) - 1)))
    echo "$(((value >> 24) & 0xff)).$(((value >> 16) & 0xff)).$(((value >> 8) & 0xff)).$((value & 0xff))"
}

ip_netmask_to_defgateway() {
    local i1 i2 i3 i4 m1 m2 m3 m4
    IFS=. read -r i1 i2 i3 i4 <<<$1
    IFS=. read -r m1 m2 m3 m4 <<<$2
    printf "%d.%d.%d.%d\n" \
        "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((((i4 & m4)) + 1))"
}

get_interface_info() {
    local dev0 ipaddr netmask defgateway

    local ipout=$(ip -br -f inet address show | grep UP)

    local dev status cidr
    local i=0
    while read -r dev status cidr; do
        if [ $i -eq 0 ]; then
            dev0="$dev"
            ipaddr="${cidr%/*}"
            netmask=$(prefix_to_netmask "${cidr#*/}")
            defgateway=$(ip_netmask_to_defgateway $ipaddr $netmask)
        fi
        i=$((i + 1))
    done <<<"$ipout"

    echo "$dev0 $ipaddr $netmask $defgateway"
}

if (($# < 1)); then
    echo "Missing remote ip."
    exit 0
else
    echo "Setting up VXLAN: remote IP $1"
    read -r dev0 ipaddr netmask defgateway <<<$(get_interface_info)
    if [ -z "$dev0" ]; then
        echo "interface not found."
    else
        cat >"$VXLAN_PATH" <<EOF
ip link add vxlan0 type vxlan id 12 local $ipaddr remote $1 dev $dev0 dstport 4789
ip link set vxlan0 up
tc qdisc add dev $dev0 handle ffff: ingress
tc filter add dev $dev0 parent ffff: matchall action mirred egress mirror dev vxlan0
EOF
        printf "#!/bin/sh\n${VXLAN_PATH}\nexit 0\n" >"$RC_PATH"
        chmod 700 "$RC_PATH"
        chmod 700 "$VXLAN_PATH"
        echo "VXLAN setup complete. Reboot."
    fi

    exit 0
fi

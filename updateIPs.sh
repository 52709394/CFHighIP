#!/bin/sh

ips=$(cat /root/ips.txt)

i=0

while IFS=',' read -r ip port
do
    [ -z "$ip" ] && continue

    eval "ip${i}='$ip'"
    eval "port${i}='$port'"

    i=$((i+1))

done <<EOF
$ips
EOF

count=$i

_inbound() {
    printf '
    {
      "type": "mixed",
      "tag": "%s",
      "listen": "127.0.0.1",
      "listen_port": %s
    }' "$1" "$2"
}

_outbound() {
    printf '
    {
      "type": "vless",
      "tag": "%s",
      "server": "%s",
      "server_port": %s,
      "uuid": "uuid",
      "packet_encoding": "xudp",
      "tls": {
        "enabled": true,
        "server_name": "www.163.com",
        "insecure": false,
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        }
      },
      "transport": {
        "type": "ws",
        "path": "/fxxku",
        "headers": {
          "Host": "www.163.com"
        }
      }
    }' "$1" "$2" "$3"
}

_route() {
    printf '
      {
        "inbound": [
          "%s"
        ],
        "outbound": "%s"
      }' "$1" "$2"
}

_json(){
    printf '
    {
        "log": {
            "level": "warn",
            "timestamp": true
        },
        "inbounds": [%s],
        "outbounds": [%s],
        "route": {
            "rules": [%s]
        }
    }' "$1" "$2" "$3"
}


[ -e "/root/okIPs.txt" ] && rm /root/okIPs.txt

! [ -d "/tmp/sing-box" ] && mkdir /tmp/sing-box

size=10
x=0

while [ "$x" -lt "$count" ]; do
    inbounds=""
    outbounds=""
    routes=""

    i=0
    while [ $i -lt $size ] && [ $x -lt $count ]; do
        t=$((10000+i))
        eval "ip=\$ip${x}"
        eval "port=\$port${x}"
        tag=$t

        eval "newip${i}=\$ip"
        eval "newport${i}=\$port"
        eval "tag${i}=\$tag"

        [ -n "$inbounds" ] && inbounds="${inbounds},"
        inbounds="${inbounds}$(_inbound "in$tag" "$tag")"

        [ -n "$outbounds" ] && outbounds="${outbounds},"
        outbounds="${outbounds}$(_outbound "out$tag" "$ip" "$port")"

        [ -n "$routes" ] && routes="${routes},"
        routes="${routes}$(_route "in$tag" "out$tag")"

        x=$((x+1))
        i=$((i+1))
    done

    _json "$inbounds" "$outbounds" "$routes" | jq . > /tmp/sing-box/config.json
    
    /usr/bin/sing-box run -c /tmp/sing-box/config.json &
    pid=$!

    sleep 3
    
    y=0
    while [ "$y" -lt "$i" ]; do
        eval "ip=\$newip${y}"
        eval "port=\$newport${y}"
        eval "tagPort=\$tag${y}"

    delay=$(curl -x "socks5h://127.0.0.1:$tagPort" ifconfig.me/ip)
     
    if [ "$delay" == "ip" ]; then
        echo "$ip,$port,$delay"
        echo "$ip,$port" >> /root/okIPs.txt
    fi

        y=$((y+1))
    done

    kill $pid
    sleep 1
done

okIPs=$(cat /root/okIPs.txt)

i=1

while IFS=',' read -r ip port
do
    [ -z "$ip" ] && continue

    eval "okIp${i}='$ip'"
    eval "okPort${i}='$port'"

    i=$((i+1))

done <<EOF
$okIPs
EOF

if [ $i -lt 15 ]; then
    exit 1
fi

count=$i
size=10

if [ $size -lt $count ];then

list=""
i=0 
[ -e "/root/updateIPs.txt" ] && rm /root/updateIPs.txt

while [ $i -lt $size ]
do
    n=$(( 0x$(hexdump -n 2 -e '/2 "%04X"' /dev/urandom) % $count + 1 ))

    echo " $list " | grep -q " $n " && continue

    list="$list $n"
    
    eval "ip=\$okIp${n}"
    eval "port=\$okPort${n}"

    [ "$ip" != "" ]  && echo "$ip,$port" >> /root/updateIPs.txt

    i=$((i+1))
done
else
cp -rf /root/okIPs.txt /root/updateIPs.txt
fi


TOKEN="ghp_xxxxxxxxx"
REPO="用户名/仓库"
FILE="result.txt"

SHA=$(curl -s \
-H "Authorization: Bearer $TOKEN" \
https://api.github.com/repos/$REPO/contents/$FILE \
| jq -r '.sha')


CONTENT=$(base64 "/root/$FILE"| tr -d '\n')

curl -L \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/$REPO/contents/$FILE \
  -d "{
    \"message\":\"auto update\",
    \"content\":\"$CONTENT\",
    \"sha\":\"$SHA\"
  }"

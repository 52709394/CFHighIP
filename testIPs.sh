#!/bin/sh

DATA='
'

i=0

while IFS=',' read -r ip port
do
    [ -z "$ip" ] && continue

    # 保存
    eval "ip${i}='$ip'"
    eval "port${i}='$port'"

    i=$((i+1))

done <<EOF
$DATA
EOF

# 保存总数
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


echo "" > okIPs.txt

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

        # 保存每组变量
        eval "newip${i}=\$ip"
        eval "newport${i}=\$port"
        eval "tag${i}=\$tag"

        # 拼接 JSON
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
    
    echo $(cat /tmp/sing-box/config.json | jq .)

    /usr/bin/sing-box run -c /tmp/sing-box/config.json &
    pid=$!

    sleep 3
    
    y=0
    while [ "$y" -lt "$i" ]; do
        eval "ip=\$newip${y}"
        eval "port=\$newport${y}"
        eval "tagPort=\$tag${y}"

    delay=$(
    curl \
        --socks5 "127.0.0.1:$tagPort" \
        -o /dev/null \
        -s \
        -m 5 \
        -w '%{time_total}' \
        https://www.gstatic.com/generate_204
    )

    if [ $? -eq 0 ]; then
        echo "$ip,$port,$delay" 
        echo "$ip,$port" >> okIPs.txt
    fi

        y=$((y+1))
    done

    kill $pid
    wait "$pid" 2>/dev/null
    sleep 1
done

#!/bin/sh


_getIPs(){

  local iIP=$1
  local iPort=$2
  local iIPs=$3
  local i=0

while IFS=',' read -r ip port
do
    [ -z "$ip" ] && continue

    eval "$iIP${i}='$ip'"
    eval "$iPort${i}='$port'"

    i=$((i+1))

done <<EOF
$iIPs
EOF

COUNT=$i
}


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


_testIPs(){

local count=$1
local size=$2
local isGetMin=$3
local max=$((MIN+400))
local x=0

local  inbounds=""
local  outbounds=""
local  routes=""

local i=0
local t=0
local tag=0
local y=0
local pid=0
local delay="" 
local code=""
local time=""
local ms=""

[ -e "/root/okIPs.txt" ] && rm /root/okIPs.txt

! [ -d "/tmp/sing-box" ] && mkdir /tmp/sing-box

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
    kill -0 $pid 2>/dev/null || continue
    
    y=0
    while [ "$y" -lt "$i" ]; do
        eval "ip=\$newip${y}"
        eval "port=\$newport${y}"
        eval "tagPort=\$tag${y}"

    delay=$(curl \
            --connect-timeout 3 \
            --max-time 5 \
            -o /dev/null \
            -s \
            -w '%{http_code},%{time_total}' \
            -x "socks5h://127.0.0.1:$tagPort" \
            https://www.gstatic.com/generate_204)

    
    code=${delay%,*}
    time=${delay#*,}

    ms=$(awk "BEGIN{printf \"%d\", $time*1000}")

    if [ "$code" = "204" ] && [ "$isGetMin" = "true" ];then
     
     [ "$ms" -lt "$MIN" ] && MIN=$ms 

      echo "min:$MIN"
    fi 

    if [ "$code" = "204" ] && [ "$isGetMin" = "false" ]; then
            
      if [ "$ms" -lt "$max" ]; then
          echo "$ip,$port,$ms ok"
          echo "$ip,$port" >> /root/okIPs.txt
      else 
          echo "$ip,$port,$ms no"   
      fi

    fi
        y=$((y+1))
    done

    kill $pid
    sleep 1
done
}

_randomIPs(){

local size=$2
local count=$1 

if [ $size -lt $count ];then

local list=""
local i=0 
local n=0

[ -e "/root/updateIPs.txt" ] && rm /root/updateIPs.txt

while [ $i -lt $size ]
do
    n=$(( 0x$(hexdump -n 2 -e '/2 "%04X"' /dev/urandom) % $count ))

    case " $list " in
    *" $n "*) continue ;;
    esac

    list="$list $n"
    
    eval "ip=\$okIp${n}"
    eval "port=\$okPort${n}"

    [ "$ip" = "" ]  && continue
    
    echo "$ip,$port" >> /root/updateIPs.txt

    i=$((i+1))
done
else
cp -rf /root/okIPs.txt /root/updateIPs.txt
fi
}


_updateIPs() {

local token="ghp_xxxxxxxxx"
local repo="用户名/仓库"
local file="updateIPs.txt"

local content=$(base64 < "/root/$file" | tr -d '\n')

local sha=$(curl -s \
-H "Authorization: Bearer $token" \
https://api.github.com/repos/$repo/contents/$file \
| jq -r '.sha')

local date=""

if [ "$sha" = "null" ]; then
    data="
    \"message\":\"auto update\",
    \"content\":\"$content\"
  "
else
    data="
    \"message\":\"auto update\",
    \"content\":\"$content\",
    \"sha\":\"$sha\"
  "
fi

curl -L \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $token" \
  https://api.github.com/repos/$repo/contents/$file \
  -d "{$data}"
}

_run(){

local count=0
local size=10


local ips=""
local url="https://www.163.com/ips.txt"

ips=$(curl \
--connect-timeout 5 \
-s $url) || ips=""

if [ ips = "" ];then
   exit 1
fi

_getIPs "ip" "port" "$ips"
count=$COUNT 

MIN=99999
_testIPs $count $size "true"

_testIPs $count $size "false"

if ! [ -e "/root/okIPs.txt" ]; then
    exit 1
fi  

_getIPs "okIp" "okPort" "$(cat /root/okIPs.txt)"
count=$COUNT

if [ $count -lt 15 ]; then
    exit 1
fi

_randomIPs $count $size

_updateIPs

}

_run

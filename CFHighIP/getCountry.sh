#!/bin/sh

# 1. IP 段文本变量（不是数组）
IP_RANGES="
"

# 2. for 循环，一行一条
for line in $IP_RANGES; do
    # 3. 正则拆 IP 和 /xx
    ip=$(echo "$line" | sed -n 's#^\([0-9.]\+\)/[0-9]\+#\1#p')
    mask=$(echo "$line" | sed -n 's#^[0-9.]\+/\([0-9]\+\)#\1#p')

    # 防御：解析失败直接原样输出
    if [ -z "$ip" ] || [ -z "$mask" ]; then
        echo "$line"
        continue
    fi

    # 4. curl 获取国家（加超时，防卡死）
    country=$(curl -s --max-time 5 "https://api.country.is/$ip" \
        | sed -n 's/.*"country"[[:space:]]*:[[:space:]]*"\([A-Za-z]\{2\}\)".*/\1/p')

    # 5. 成功 or 失败处理
    if [ -n "$country" ]; then
        echo "$ip/$mask $country"
    else
        # 获取失败，保留原样
        echo "$ip/$mask"
    fi
done

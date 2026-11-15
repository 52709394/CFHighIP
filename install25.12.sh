#!/bin/bash

if [ ! -f "/etc/apk/keys/key-build.pem" ]; then
wget -P /tmp https://opkg.cooluc.com/key-build.pem && \
mv /tmp/key-build.pem /etc/apk/keys && \
echo "https://opkg.cooluc.com/openwrt-25.12/$(cat /etc/apk/arch)/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
fi

apk update
apk add luci-i18n-attendedsysupgrade-zh-cn luci-i18n-firewall-zh-cn luci-i18n-package-manager-zh-cn luci-i18n-base-zh-cn
apk add block-mount kmod-lib-crc16 kmod-fs-ext4 kmod-scsi-core kmod-usb-storage

wget -P /tmp "https://app.ifxxku.dpdns.org/ZhongGitHub/https://github.com/jerrykuku/luci-theme-argon/releases/download/v3.1.3/luci-app-argon-config-3.1.3-r1.apk"
wget -P /tmp "https://app.ifxxku.dpdns.org/ZhongGitHub/https://github.com/jerrykuku/luci-theme-argon/releases/download/v3.1.3/luci-i18n-argon-config-zh-cn-3.1.3-r1.apk"
wget -P /tmp "https://app.ifxxku.dpdns.org/ZhongGitHub/https://github.com/jerrykuku/luci-theme-argon/releases/download/v3.1.3/luci-theme-argon-3.1.3-r1.apk"

apk add --allow-untrusted /tmp/luci*argon*.apk

wget -P /tmp "https://app.ifxxku.dpdns.org/ZhongGitHub/https://github.com/linkease/openwrt-app-actions/raw/main/applications/luci-app-systools/root/usr/share/systools/istore-reinstall.run"
[ -f "/tmp/istore-reinstall.run" ] && chmod 755 /tmp/istore-reinstall.run && /tmp/istore-reinstall.run


uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci commit system
/etc/init.d/system restart

uci set network.lan.ipaddr='192.168.100.1/24'
uci commit network

# 1. 启用 5G 射频硬件（将 disabled 设为 0）
uci set wireless.radio1.disabled='0'

uci set wireless.radio1.channel='149'

# 2. 设置国家代码（非常重要，否则部分 5G 信道无法开启，CN 为中国，US 为美国）
uci set wireless.radio1.country='CN'

# 3. 启用对应的无线接口（如果接口默认是关闭状态）
uci set wireless.default_radio1.disabled='0'

# 4. 设置 5G Wi-Fi 名称 (SSID)
uci set wireless.default_radio1.ssid='iWiFi_5G'

# 5. 设置加密方式（推荐 psk2 即 WPA2-PSK）及密码（至少 8 位）
uci set wireless.default_radio1.encryption='psk2'
uci set wireless.default_radio1.key='aA123456xx'

# 6. 保存配置并使其生效
uci commit wireless
wifi reload

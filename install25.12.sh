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

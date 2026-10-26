#!/bin/sh
echo '== Sistema =='; uname -a
echo '== Placa =='; cat /proc/device-tree/model; echo
echo '== Modulos =='; lsmod | grep -E 'ssv6051|ssv6x5x|mac80211|cfg80211' || true
echo '== Interfaces =='; ip link show
echo '== Bloqueos =='; rfkill list 2>/dev/null || true
echo '== Arranque =='; cat /storage/wifi-start.log 2>/dev/null || true
echo '== Kernel (ultimas lineas pertinentes) =='; dmesg | grep -iE 'ssv|sdio|firmware|calib|fail' | tail -55

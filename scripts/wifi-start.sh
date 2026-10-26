#!/bin/sh
# GMJ RK3229 / LibreELEC - carga temporal del driver alternativo.
# Ejecutado en segundo plano por /storage/.config/autostart.sh.
sleep 10
modprobe cfg80211 || exit 1
modprobe mac80211 || exit 1
if lsmod | grep -q '^ssv6051 '; then
  rmmod ssv6051 || exit 1
fi
if ! lsmod | grep -q '^ssv6x5x '; then
  insmod /storage/ssv6x5x.ko \
    tu_stacfgpath=/storage/ssv6x5x-wifi.cfg \
    tu_cfgfirmwarepath=/storage/ \
    ssv6xxx_sdio_slow_clock=1 || exit 1
fi

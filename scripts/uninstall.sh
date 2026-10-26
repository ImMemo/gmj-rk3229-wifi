#!/bin/sh
# Revertir arranque automatico; NO borra firmware ni modulo.
set -eu
A=/storage/.config/autostart.sh
if [ -f "$A" ]; then
  sed '/^# GMJ-RK3229-WIFI-BEGIN$/,/^# GMJ-RK3229-WIFI-END$/d' "$A" > "$A.tmp"
  mv "$A.tmp" "$A"
fi
rm -f /storage/.config/wifi-start.sh
if [ -f /storage/.config/modprobe.d/ssv6051.conf.gmj-backup ]; then
  mv /storage/.config/modprobe.d/ssv6051.conf.gmj-backup /storage/.config/modprobe.d/ssv6051.conf
else
  rm -f /storage/.config/modprobe.d/ssv6051.conf
fi
sync
echo 'Arranque automatico revertido. Reinicia para restaurar el controlador original.'

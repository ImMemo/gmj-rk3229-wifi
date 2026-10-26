#!/bin/sh
# Ejecutar en LibreELEC por SSH, desde la carpeta que contiene este script.
set -eu
for f in ssv6x5x.ko ssv6x5x-sw.bin ssv6x5x-wifi.cfg; do
  test -s "/storage/$f" || { echo "Falta /storage/$f" >&2; exit 1; }
done
mkdir -p /storage/.config/modprobe.d
if [ -e /storage/.config/autostart.sh ]; then
  cp -p /storage/.config/autostart.sh /storage/.config/autostart.sh.gmj-backup
fi
if [ -e /storage/.config/modprobe.d/ssv6051.conf ]; then
  cp -p /storage/.config/modprobe.d/ssv6051.conf /storage/.config/modprobe.d/ssv6051.conf.gmj-backup
fi
cp "$(dirname "$0")/wifi-start.sh" /storage/.config/wifi-start.sh
chmod 755 /storage/.config/wifi-start.sh
printf '%s\n' 'blacklist ssv6051' > /storage/.config/modprobe.d/ssv6051.conf
: > /storage/.config/autostart.sh.tmp
if [ -f /storage/.config/autostart.sh ]; then
  sed '/^# GMJ-RK3229-WIFI-BEGIN$/,/^# GMJ-RK3229-WIFI-END$/d' /storage/.config/autostart.sh > /storage/.config/autostart.sh.tmp
fi
cat >> /storage/.config/autostart.sh.tmp <<'AUTOSTART'
# GMJ-RK3229-WIFI-BEGIN
(/storage/.config/wifi-start.sh >> /storage/wifi-start.log 2>&1) &
# GMJ-RK3229-WIFI-END
AUTOSTART
mv /storage/.config/autostart.sh.tmp /storage/.config/autostart.sh
chmod 755 /storage/.config/autostart.sh
sync
echo 'Instalado. Antes de reiniciar: /storage/.config/wifi-start.sh, luego lsmod | grep ssv y verificar conexion.'

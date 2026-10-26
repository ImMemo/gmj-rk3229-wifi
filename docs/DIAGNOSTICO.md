# Diagnóstico y aprendizaje de la prueba GMJ

## Secuencia observada

1. LibreELEC RK322X detectaba SSV6006C0 (`3030:3030`) mediante `ssv6051`, pero repetía `calibation fail after 100 iterations`, registro `0xca000200` y `Failed to initialize mac`.
2. Se compiló `ssv6x5x` con kernel 6.16.12 y se transfirió por `scp` a `/storage/`.
3. `insmod` funcionó, pero `ip link set wlan0 up` retornaba `Operation not permitted` y ConnMan `No carrier`.
4. Después de pasar `ssv6xxx_sdio_slow_clock=1`, el driver detectó chip, MAC efuse y puso SDIO a 25 MHz. Eso solo no bastó.
5. Se descubrió leyendo `smac/init.c` que `tu_cfgfirmwarepath` se CONCATENA con `ssv6x5x-sw.bin`. Pasar la ruta completa del archivo era incorrecto. **`tu_cfgfirmwarepath=/storage/`** resolvió la ubicación y el usuario confirmó conexión WiFi.
6. Tras reiniciar, la conexión desapareció. `/storage/wifi-start.log` mostró `Unknown symbol in module`. El bloqueo de `ssv6051` había evitado que sus dependencias se cargaran. Se corrigió el script con `modprobe cfg80211` y `modprobe mac80211` antes de `insmod`. Usuario confirmó el resultado positivo, pendiente de evidenciar por escrito un reinicio posterior y conexión automática en cada firmware.

## Capturar evidencias sin secretos

```sh
uname -r
modinfo /storage/ssv6x5x.ko | grep -E 'vermagic|alias|depends'
lsmod | grep -E 'ssv|mac80211|cfg80211'
rfkill list
cat /storage/wifi-start.log 2>/dev/null
dmesg | grep -iE 'ssv|firmware|sdio|calib|fail' | tail -60
```

Nunca compartas claves de WiFi, identidad SSH, MAC completas si se desea privacidad, IP pública, claves privadas ni datos personales. En equipos genéricos pueden existir revisiones de placa diferentes bajo el mismo nombre comercial.

## Error de display.service

El `[FAILED] Failed to start display.service` visto durante el trabajo correspondía al servicio de pantalla LED **TM16xx**. Se buscaba `/sys/class/leds/display` y el dispositivo no existía. Era independiente del WiFi y del HDMI. Si tu caja no incluye visor LED, puedes investigar su desactivación; nunca desactives servicios por su nombre sin leer primero `systemctl status` y `journalctl`.

## Recuperación tras fallos

Mantener Ethernet conectado permite SSH si falla WiFi. Los cambios están en `/storage`, de forma que Android original en NAND no se altera. Si la caja no inicia, restaurar desde otra máquina con lector de sistemas ext4 sobre la partición STORAGE. No cambiar DTB indiscriminadamente.

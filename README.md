# WiFi SSV6006C0 en GMJ RK3229 con LibreELEC 12.2

**Guía comunitaria no oficial, en español.** Caso real: TV Box GMJ RK3229 (ARMv7, 1 GB RAM) con chip SDIO `3030:3030` (**SSV6006C0**) y LibreELEC RK322X (ilmich) con kernel `6.16.12`. El controlador integrado `ssv6051` detectaba el chip, pero fallaba la calibración y la inicialización MAC. Se consiguió conectar por WiFi cargando un `ssv6x5x.ko` construido específicamente para ese kernel y proporcionando la **ruta de directorio** del firmware.

> **Estado:** conexión WiFi confirmada en esta unidad. El arranque automático se corrigió añadiendo `cfg80211` y `mac80211` antes de cargar el módulo. Se recomienda comprobar el reinicio en cada instalación, porque las versiones del kernel y del dispositivo pueden variar.

## Advertencias

- No es un driver universal ni una modificación oficial de LibreELEC, Rockchip o iComm.
- Mantén acceso por **Ethernet** durante la primera instalación y las pruebas de reinicio. Puedes quedarte temporalmente sin WiFi.
- **No instales el módulo de otra versión de kernel.** La cadena `vermagic` y, cuando se use `CONFIG_MODVERSIONS`, los símbolos del kernel deben ser compatibles.
- No necesitas flashear NAND/eMMC. En la experiencia documentada LibreELEC arrancaba desde microSD y Android quedó intacto.
- No hay binarios propietarios, imágenes de LibreELEC ni módulos precompilados incluidos en este repositorio. Hay enlaces e instrucciones para reproducirlos.

## Equipo de la prueba

| Dato | Valor |
| --- | --- |
| TV Box | GMJ, Rockchip RK3229 (rk322x) |
| CPU | ARM Cortex-A7 (32 bits) |
| RAM | 1 GB |
| LibreELEC | `nightly-20260311-1b9970a (RK322X.arm)` |
| Kernel de la TV Box | `6.16.12` |
| DTB | `rk322x-box.dtb` genérico |
| WiFi | SSV6006C0, SDIO `c*v3030d3030` |
| Driver integrado (no funcional en esta unidad) | `ssv6051` |
| Driver alternativo | [`cdhigh/armbian_sv6256p`](https://github.com/cdhigh/armbian_sv6256p) (`ssv6x5x`) |
| Plataforma de compilación | Ubuntu 24.04 dentro de Docker en WSL |

## Descargas y créditos

- [Controlador moderno SSV6X5X — cdhigh](https://github.com/cdhigh/armbian_sv6256p). Autor de la adaptación del driver a kernels Linux modernos. Consultar su repositorio y su `LICENSE` antes de redistribuir código.
- [LibreELEC RK322X — rk-unofficial-cfw / ilmich](https://github.com/rk-unofficial-cfw/LibreELEC.tv), rama `libreelec-12.2-rk322x`.
- [Imágenes RK322x y explicación de arranque desde SD](https://forum.libreelec.tv/thread/29006-unofficial-le12-rk3228-rk3229-box-libreelec-builds/).
- [Autostart de LibreELEC](https://wiki.libreelec.tv/configuration/startup-shutdown).

## 1. Identificar hardware

En la caja por SSH:

```sh
uname -r
cat /proc/device-tree/model; echo
ls /sys/bus/mmc/devices/
dmesg | grep -iE 'SSV6006|3030|mmc2|ssv6051' | tail -30
```

Se requiere distinguir el modelo comercial de la identidad **real** del chip. `wlan0` presente no implica que pueda activarse.

## 2. Preparar el controlador

Para un kernel **exactamente compatible** con el del dispositivo, compilar `ssv6x5x.ko` contra su árbol de kernel preparado y `Module.symvers`, con toolchain ARMv7 compatible. Nuestro procedimiento documentado está en [docs/COMPILACION.md](docs/COMPILACION.md). Se necesitan además `ssv6x5x-sw.bin` y `ssv6x5x-wifi.cfg` del repositorio original.

## 3. Copiar a LibreELEC

Desde Ubuntu/Linux, sustituyendo la dirección IP:

```sh
scp ssv6x5x.ko ssv6x5x-sw.bin ssv6x5x-wifi.cfg root@IP_DE_LA_TV_BOX:/storage/
scp scripts/*.sh root@IP_DE_LA_TV_BOX:/storage/
```

**No pongas contraseñas ni configuraciones privadas en Git.** Nunca subas `/storage/.kodi`, archivos de conexión WiFi, contraseñas SSH o logs sin revisar.

## 4. Primera prueba manual (Ethernet conectado)

En la GMJ (`LibreELEC:~ #`):

```sh
modprobe cfg80211
modprobe mac80211
rmmod ssv6051 2>/dev/null || true
insmod /storage/ssv6x5x.ko \
  tu_stacfgpath=/storage/ssv6x5x-wifi.cfg \
  tu_cfgfirmwarepath=/storage/ \
  ssv6xxx_sdio_slow_clock=1
ip link set wlan0 up
connmanctl scan wifi
connmanctl services
```

Configura la red desde el menú de LibreELEC o con ConnMan. **Fundamental:** `tu_cfgfirmwarepath` es el **directorio** `/storage/`, no el archivo completo. El driver concatena esa ruta con `ssv6x5x-sw.bin`. En este caso ese detalle fue decisivo.

Verifica:

```sh
lsmod | grep -E 'ssv6x5x|mac80211|cfg80211'
ip addr show wlan0
```

Si `insmod` falla con `Unknown symbol`, probablemente faltan las dependencias `cfg80211` y `mac80211`; revisar `dmesg` antes de seguir.

## 5. Arranque automático

Después de verificar que el WiFi funciona manualmente, dentro de la TV Box:

```sh
sh /storage/install.sh
```

El instalador comprueba la presencia de los 3 archivos del driver, copia `wifi-start.sh` a `/storage/.config/`, bloquea el autoload de `ssv6051` e inserta un bloque identificable en `autostart.sh`, conservando el contenido anterior. El script carga las dependencias `cfg80211` y `mac80211`, luego `ssv6x5x` con los parámetros que funcionaron.

Prueba **antes** de reiniciar:

```sh
/storage/.config/wifi-start.sh
lsmod | grep -E 'ssv6x5x|mac80211|cfg80211'
```

Si funciona, reinicia y comprueba que vuelve a conectar. `autostart.sh` y los archivos de `/storage` sobreviven a los reinicios en LibreELEC.

## 6. Recuperación

Con Ethernet, dentro de LibreELEC:

```sh
sh /storage/uninstall.sh
reboot
```

El script quita el bloque de inicio y restaura el bloqueo previo de `ssv6051` si existía, pero **conserva los archivos del driver**, por seguridad. Si no tienes SSH, apaga, extrae la microSD y modifica su partición `STORAGE` desde un Linux que lea ext4.

## Problemas frecuentes

| Síntoma | Interpretación / siguiente paso |
| --- | --- |
| `calibation fail after 100 iterations` | Falló la inicialización con `ssv6051`; no indica necesariamente chip dañado |
| `No carrier` | La interfaz no está lista para escanear; revisar inicialización del módulo |
| `Operation not permitted` al subir `wlan0` como root | El driver puede devolver error interno de inicialización; consultar `dmesg` |
| `Unknown symbol in module` | Cargar `cfg80211` y `mac80211` antes de `insmod`; comprobar también ABI y símbolos |
| `ssv6xxx_sdio_read_reg` | Fallo de comunicación SDIO; comprobar firmware, registros y alimentación |
| Conecta manualmente, falla tras reinicio | Comprobar `/storage/wifi-start.log`, `autostart.sh` y dependencias |
| `Failed to start display.service` | En este equipo era el servicio de visor LED TM16xx, **no HDMI/Kodi** |

Más detalles en [docs/DIAGNOSTICO.md](docs/DIAGNOSTICO.md).

## Licencias y alcance

Los scripts y la documentación escritos para esta guía se publican bajo [MIT](LICENSE). **Esto no cambia la licencia del controlador `cdhigh`, Linux, LibreELEC o sus firmwares**, que permanecen bajo sus respectivas licencias. No afirmamos autoría de esos componentes.

## Contribuir

Comparte modelo real de SoC y chip WiFi, kernel, DTB, `modinfo ... | grep vermagic`, resultados de `dmesg` y diferencias observadas. Elimina MAC, IP pública, SSID, contraseñas y cualquier identificador privado antes de publicar registros.

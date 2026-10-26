# Compilación reproducible del módulo ARMv7

Este procedimiento describe **cómo se consiguió** compilar para LibreELEC RK322X 6.16.12. No garantiza ABI para otros kernels ni otras revisiones de la misma versión. En particular, el repositorio LibreELEC usado para compilar tenía una revisión posterior a la imagen instalada. Aunque `insmod` funcionó en la prueba, eso **no sustituye la verificación de símbolos**.

## Requisitos

- PC Windows con Ubuntu WSL y Docker disponible dentro de Ubuntu, o Linux con Docker.
- Espacio: preferiblemente 30–40 GB libres durante compilación. El directorio de construcción puede ser grande.
- Ethernet hacia TV Box y microSD arrancable.

## Obtener fuentes

```sh
mkdir -p ~/gmj-wifi
cd ~/gmj-wifi
git clone -b libreelec-12.2-rk322x https://github.com/rk-unofficial-cfw/LibreELEC.tv.git LibreELEC-RK322X
git clone https://github.com/cdhigh/armbian_sv6256p.git
```

Se recomienda fijar ambos repositorios a commits conocidos y documentarlos al reproducir:

```sh
(cd LibreELEC-RK322X && git rev-parse HEAD)
(cd armbian_sv6256p && git rev-parse HEAD)
```

## Preparar Docker y compilar solo el kernel

Desde Ubuntu WSL:

```sh
cd ~/gmj-wifi/LibreELEC-RK322X
sudo docker build --pull -t libreelec tools/docker/noble
sudo docker run -it --rm --log-driver none \
  --user "$(id -u):$(id -g)" \
  -v "$PWD":/build -w /build -e HOME=/tmp \
  -e BUILDER_NAME=ilmich -e BUILD_PERIODIC=nightly \
  -e PROJECT=Rockchip -e DEVICE=RK322X -e ARCH=arm \
  -e UBOOT_SYSTEM=rk322x -e CONCURRENCY_MAKE_LEVEL=3 \
  libreelec ./scripts/install linux:target
```

Nota: en nuestra sesión se habían generado dependencias con un Ubuntu distinto, causando errores de GLIBC. Evita mezclar compilaciones host y Docker dentro del mismo `build.LibreELEC...`. La compilación de imagen completa se detuvo por un `udevil` 404, pero el **paquete del kernel** se pudo construir directamente.

Comprobar:

```sh
find build.LibreELEC-RK322X.arm-12.2-devel -name Module.symvers -o -name ssv6051.ko
```

## Adaptar `ssv6x5x` al kernel 6.16

En `~/gmj-wifi/armbian_sv6256p`:

```sh
cp Makefile Makefile.original
cp Makefile.cross_linux Makefile
```

Agregar una vez a `Makefile` las rutas de cabeceras debajo de `EXTRA_CFLAGS`:

```make
ccflags-y += -I$(src) -I$(src)/include
```

En la revisión utilizada, el controlador tenía una condición para Linux `>= 6.15` que declaraba la función `ssv6200_config` con 3 parámetros. Nuestro kernel 6.16 espera 2. Se corrigió en `smac/dev.c` **solo esa firma** para que coincida con el kernel:

```c
static int ssv6200_config(struct ieee80211_hw *hw, u32 changed) {
```

Verifica la firma exacta en el árbol de kernel **antes de aplicar esta adaptación**, porque el repositorio upstream podría cambiar. No ocultes el error desactivando `-Werror`.

## Construir el módulo

```sh
cd ~/gmj-wifi/armbian_sv6256p
sudo docker run -it --rm --log-driver none \
  --user "$(id -u):$(id -g)" \
  -v "$HOME/gmj-wifi":/build-parent \
  -v "$HOME/gmj-wifi/LibreELEC-RK322X":/build \
  -w /build-parent/armbian_sv6256p -e HOME=/tmp \
  libreelec make ARCH=arm \
  CROSS_COMPILE=/build/build.LibreELEC-RK322X.arm-12.2-devel/toolchain/bin/armv7ve-libreelec-linux-gnueabihf- \
  KSRC=/build/build.LibreELEC-RK322X.arm-12.2-devel/build/linux-6.16.12 \
  -j3
```

Verificar:

```sh
file ssv6x5x.ko
modinfo ssv6x5x.ko | grep -E 'vermagic|depends|alias'
```

Resultado registrado: ARM 32-bit, `sdio:c*v3030d3030*`, `depends: mac80211,cfg80211`, `vermagic: 6.16.12 SMP mod_unload modversions ARMv7 p2v8`.

**No subir el `.ko` sin ofrecer la cadena de fuentes/licencias correspondiente.** El módulo es obra derivada de código de terceros. Esta guía distribuye instrucciones y scripts, no ese binario.

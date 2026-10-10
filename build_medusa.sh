#!/usr/bin/env bash

##############################################
#       Project Medusa Kernel Builder        #
#          Samsung Galaxy J6+                #
##############################################

set -o pipefail

# Directorios
ROOT_DIR="$(pwd)"
OUT_DIR="$ROOT_DIR/out"
BUILD_START="$(date +%s)"

# Arquitectura
export ARCH=arm
export SUBARCH=arm

# Configuración del dispositivo
DEF="j6primelte_defconfig"
export DEFCONFIG="$DEF"
export LOCALVERSION="-Medusa"

# Identificación de compilación
export KBUILD_BUILD_USER="Batu33TR"
export KBUILD_BUILD_HOST="ProjectMedusa"

# Compilador
export CROSS_COMPILE="$ROOT_DIR/gcc/bin/arm-linux-androideabi-"

# Mostrar errores sin depender de tput
echo "=============================================="
echo "       Project Medusa Kernel Builder"
echo "=============================================="
echo "Dispositivo: Samsung Galaxy J6+"
echo "Defconfig: $DEF"
echo "Arquitectura: $ARCH"
echo "Directorio de salida: $OUT_DIR"
echo "Toolchain: GCC 4.9"
echo "Inicio: $(date)"
echo "=============================================="

# Comprobar archivos necesarios
if [ ! -f "$ROOT_DIR/Makefile" ]; then
    echo "ERROR: No se encuentra el Makefile del kernel."
    exit 1
fi

if [ ! -f "$ROOT_DIR/arch/arm/configs/$DEF" ]; then
    echo "ERROR: No existe arch/arm/configs/$DEF"
    exit 1
fi

if [ ! -x "${CROSS_COMPILE}gcc" ]; then
    echo "ERROR: No se encuentra el compilador:"
    echo "${CROSS_COMPILE}gcc"
    exit 1
fi

# Comprobar herramientas Python
echo "===== Comprobando Python ====="
if command -v python2 >/dev/null 2>&1; then
    echo "Python 2 disponible: $(command -v python2)"
elif command -v python2.7 >/dev/null 2>&1; then
    echo "Python 2.7 disponible: $(command -v python2.7)"
else
    echo "AVISO: Python 2 no está instalado."
    echo "Si algún script requiere Python 2, la compilación puede fallar."
fi

if command -v python3 >/dev/null 2>&1; then
    python3 --version
fi

# Comprobar compilador
echo "===== Versión del compilador ====="
"${CROSS_COMPILE}gcc" --version || exit 1

# Preparar salida
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR" || exit 1

# Generar configuración
echo "===== Generando defconfig ====="
make O="$OUT_DIR" ARCH="$ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    KCFLAGS=-mno-android "$DEF"

DEFCONFIG_STATUS=$?

if [ "$DEFCONFIG_STATUS" -ne 0 ]; then
    echo "ERROR: Falló la generación de la configuración."
    exit "$DEFCONFIG_STATUS"
fi

# Compilar kernel
echo "===== Iniciando compilación ====="
make O="$OUT_DIR" ARCH="$ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    KCFLAGS=-mno-android \
    -j"$(nproc --all)" zImage-dtb

BUILD_STATUS=$?

# Calcular duración después de guardar el resultado
BUILD_END="$(date +%s)"
DIFF=$((BUILD_END - BUILD_START))

if [ "$BUILD_STATUS" -ne 0 ]; then
    echo "ERROR: La compilación falló."
    echo "Código de salida: $BUILD_STATUS"
    echo "Duración: $((DIFF / 60)) min $((DIFF % 60)) s"
    exit "$BUILD_STATUS"
fi

echo "===== Compilación finalizada ====="
echo "Duración: $((DIFF / 60)) min $((DIFF % 60)) s"

# Verificar la imagen del kernel con DTB adjuntos
IMAGE="$OUT_DIR/arch/arm/boot/zImage-dtb"

if [ -f "$IMAGE" ]; then
    echo "Imagen zImage-dtb generada correctamente:"
    ls -lh "$IMAGE"
else
    echo "ERROR: No se encontró zImage-dtb."
    exit 1
fi

echo "===== DTB del Galaxy J6+ generados ====="
find "$OUT_DIR/arch/arm/boot/dts" -type f \
    -name '*j6primelte*swa-open*.dtb' -print

echo "=============================================="
echo "COMPILACIÓN COMPLETADA"
echo "=============================================="

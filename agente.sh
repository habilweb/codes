#!/bin/bash

### Script de instalación de Netdata con streaming hacia agente.webhosting.com.bo (buda)
### Autor: Hans + ChatGPT | Fecha: 2025-04-16

# Obtener nombre del nodo desde argumento
NODO_NAME=${1:-"$(hostname)"}

### Variables personalizables
RECEIVER="agente.webhosting.com.bo"
API_KEY="default"

### Paso 1: Instalar Netdata (versión estable)
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --disable-telemetry

### Paso 2: Esperar a que se cree el directorio de configuración
CONFIG_DIR="/opt/netdata/etc/netdata"

if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ No se encontró el directorio de configuración de Netdata en $CONFIG_DIR"
    exit 1
fi

### Paso 3: Desactivar cloud (por si quedó algo habilitado)
CLOUD_FILE="$CONFIG_DIR/cloud.conf"
[ -f "$CLOUD_FILE" ] && mv "$CLOUD_FILE" "$CLOUD_FILE.bak"

### Paso 4: Crear stream.conf
cat > "$CONFIG_DIR/stream.conf" <<EOF
[stream]
    enabled = yes
    destination = $RECEIVER
    api key = $API_KEY

[cloud]
    enabled = no
EOF

### Paso 5: Reiniciar Netdata para aplicar cambios
sudo systemctl restart netdata

### Paso 6: Mostrar estado final
echo "✅ Nodo '$NODO_NAME' configurado para transmitir vía streaming a $RECEIVER con api key '$API_KEY'"
echo "Puedes ver este nodo en https://netdata.webhosting.com.bo desde tu servidor central."

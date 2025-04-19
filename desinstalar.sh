#!/bin/bash

# Desinstalador de Wazuh Agent (v4.x) para sistemas basados en RHEL, AlmaLinux, CloudLinux o Debian/Ubuntu
# Autor: habilweb.com

set -e

log="/var/log/wazuh-uninstall.log"
echo "[+] Iniciando desinstalación de Wazuh Agent..." | tee -a $log

# Detener el servicio
if systemctl is-active --quiet wazuh-agent; then
    echo "[+] Deteniendo el servicio wazuh-agent..." | tee -a $log
    systemctl stop wazuh-agent || true
fi

# Deshabilitar el servicio
if systemctl is-enabled --quiet wazuh-agent; then
    echo "[+] Deshabilitando el servicio wazuh-agent..." | tee -a $log
    systemctl disable wazuh-agent || true
fi

# Eliminar el paquete
if command -v rpm &>/dev/null && rpm -q wazuh-agent &>/dev/null; then
    echo "[+] Eliminando paquete wazuh-agent (rpm)..." | tee -a $log
    rpm -e wazuh-agent || true
elif command -v dpkg &>/dev/null && dpkg -l | grep wazuh-agent &>/dev/null; then
    echo "[+] Eliminando paquete wazuh-agent (dpkg)..." | tee -a $log
    dpkg --purge wazuh-agent || true
fi

# Eliminar directorio de Wazuh
if [ -d "/var/ossec" ]; then
    echo "[+] Eliminando directorio /var/ossec..." | tee -a $log
    rm -rf /var/ossec
fi

# Eliminar usuario y grupo
if id ossec &>/dev/null; then
    echo "[+] Eliminando usuario ossec..." | tee -a $log
    userdel -r ossec || true
fi
if getent group ossec &>/dev/null; then
    echo "[+] Eliminando grupo ossec..." | tee -a $log
    groupdel ossec || true
fi

echo "[✔] Desinstalación completada con éxito." | tee -a $log

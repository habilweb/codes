#!/bin/bash

# ========================
# Instalador de Wazuh Agent
# Por: habilweb.com
# ========================

# CONFIGURA TUS DATOS
MANAGER="agente.webhosting.com.bo"
OSSEC_URL="https://raw.githubusercontent.com/habilweb/codes/main/ossec.conf"
AGENT_VERSION="4.11.2"

# DETECTAR DISTRIBUCIÓN
if [ -f /etc/debian_version ]; then
  echo "[+] Detección: Debian/Ubuntu"
  wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_${AGENT_VERSION}-1_amd64.deb
  WAZUH_MANAGER=$MANAGER WAZUH_PROTOCOL=udp dpkg -i wazuh-agent_${AGENT_VERSION}-1_amd64.deb

elif [ -f /etc/redhat-release ]; then
  echo "[+] Detección: RHEL, AlmaLinux o CloudLinux"
  curl -O https://packages.wazuh.com/4.x/yum/wazuh-agent-${AGENT_VERSION}-1.x86_64.rpm
  WAZUH_MANAGER=$MANAGER WAZUH_PROTOCOL=udp rpm -ivh wazuh-agent-${AGENT_VERSION}-1.x86_64.rpm
else
  echo "[!] Sistema no compatible"
  exit 1
fi

# REEMPLAZAR ossec.conf PERSONALIZADO
echo "[+] Descargando ossec.conf personalizado..."
curl -s -o /var/ossec/etc/ossec.conf $OSSEC_URL

# PERMISOS
chown root:ossec /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf

# REINICIAR SERVICIO
echo "[+] Iniciando Wazuh Agent..."
systemctl daemon-reexec
systemctl enable wazuh-agent
systemctl restart wazuh-agent

# MOSTRAR ESTADO
echo "[✔] Instalación finalizada en: $(hostname)"
systemctl status wazuh-agent --no-pager

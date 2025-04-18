#!/bin/bash

MANAGER="agente.webhosting.com.bo"
OSSEC_URL="https://raw.githubusercontent.com/habilweb/codes/main/ossec.conf"
AGENT_VERSION="4.11.2"

if [ -f /etc/debian_version ]; then
  echo "[+] Detección: Debian/Ubuntu"
  wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_${AGENT_VERSION}-1_amd64.deb
  WAZUH_MANAGER=$MANAGER WAZUH_PROTOCOL=udp dpkg -i wazuh-agent_${AGENT_VERSION}-1_amd64.deb

elif [ -f /etc/redhat-release ]; then
  echo "[+] Detección: RHEL/AlmaLinux/CloudLinux"
  curl -O https://packages.wazuh.com/4.x/yum/wazuh-agent-${AGENT_VERSION}-1.x86_64.rpm
  WAZUH_MANAGER=$MANAGER WAZUH_PROTOCOL=udp rpm -ivh wazuh-agent-${AGENT_VERSION}-1.x86_64.rpm
else
  echo "[!] Sistema no compatible"
  exit 1
fi

echo "[+] Descargando ossec.conf personalizado..."
curl -s $OSSEC_URL | iconv -f utf-8 -t utf-8 -c > /var/ossec/etc/ossec.conf

# Validación opcional si tienes xmllint
if command -v xmllint >/dev/null; then
  if ! xmllint /var/ossec/etc/ossec.conf --noout 2>/dev/null; then
    echo "[✖] ERROR: ossec.conf no válido. Abortando."
    exit 1
  fi
fi

groupadd ossec 2>/dev/null
chown root:ossec /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf

echo "[+] Iniciando Wazuh Agent..."
systemctl daemon-reexec
systemctl enable wazuh-agent
systemctl restart wazuh-agent
echo "[✔] Instalación finalizada en: $(hostname -f)"
systemctl status wazuh-agent --no-pager

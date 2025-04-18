#!/bin/bash

# --- CONFIGURACIÓN ---
WAZUH_MANAGER="agente.webhosting.com.bo"
AUTH_PASS="clave-secreta"
OSSEC_CONF_URL="https://raw.githubusercontent.com/habilweb/codes/main/ossec.conf"

echo "[+] Detectando sistema operativo..."

# --- DETECCIÓN Y PAQUETE ---
if grep -qi "Ubuntu" /etc/os-release; then
  echo "[+] Ubuntu detectado"
  curl -O https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.11.2-1_amd64.deb
  apt install -y ./wazuh-agent_4.11.2-1_amd64.deb
elif grep -Eqi "rhel|centos|alma|cloudlinux" /etc/os-release; then
  echo "[+] RHEL, AlmaLinux o CloudLinux detectado"
  curl -O https://packages.wazuh.com/4.x/yum/wazuh-agent-4.11.2-1.x86_64.rpm
  rpm -e wazuh-agent &>/dev/null
  rm -rf /var/ossec
  rpm -ivh wazuh-agent-4.11.2-1.x86_64.rpm
else
  echo "[-] Sistema no soportado"
  exit 1
fi

# --- ELIMINAR GRUPO/USUARIO SI EXISTE ---
if getent passwd ossec &>/dev/null; then
  echo "[+] Eliminando usuario ossec existente"
  userdel -r ossec
fi

if getent group ossec &>/dev/null; then
  echo "[+] Eliminando grupo ossec existente"
  groupdel ossec
fi

# --- CONFIGURACIÓN ---
echo "[+] Descargando ossec.conf personalizado..."
curl -s -o /var/ossec/etc/ossec.conf "$OSSEC_CONF_URL"

echo "[+] Estableciendo permisos..."
chown root:ossec /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf

echo "[+] Creando authd.pass..."
echo "$AUTH_PASS" > /var/ossec/etc/authd.pass
chmod 600 /var/ossec/etc/authd.pass

# --- INICIAR AGENTE ---
echo "[+] Iniciando Wazuh Agent..."
systemctl daemon-reexec
systemctl enable wazuh-agent
systemctl restart wazuh-agent

# --- VERIFICACIÓN ---
echo "[✔] Instalación finalizada en: $(hostname)"
systemctl status wazuh-agent --no-pager | grep Active

#!/bin/bash

# ---------------------------
# Script profesional de instalación del agente Wazuh
# Compatible con RHEL/AlmaLinux/CloudLinux y Ubuntu
# Optimizado para entornos WHM/cPanel
# ---------------------------

WAZUH_MANAGER="agente.webhosting.com.bo"
AUTH_PASS="clave-secreta"
OSSEC_CONF_URL="https://raw.githubusercontent.com/habilweb/codes/main/ossec.conf"

echo "[+] Detectando sistema operativo..."

# --- DETECCIÓN DEL SISTEMA ---
if grep -qi "Ubuntu" /etc/os-release; then
  echo "[+] Ubuntu detectado"
  curl -O https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.11.2-1_amd64.deb
  apt install -y ./wazuh-agent_4.11.2-1_amd64.deb
elif grep -Eqi "rhel|centos|alma|cloudlinux" /etc/os-release; then
  echo "[+] RHEL/AlmaLinux/CloudLinux detectado"
  curl -O https://packages.wazuh.com/4.x/yum/wazuh-agent-4.11.2-1.x86_64.rpm
  rpm -e wazuh-agent &>/dev/null
  rm -rf /var/ossec
  rpm -ivh wazuh-agent-4.11.2-1.x86_64.rpm
else
  echo "[-] Sistema operativo no soportado"
  exit 1
fi

# --- LIMPIEZA DE USUARIOS Y GRUPOS CONFLICTIVOS ---
if getent passwd ossec &>/dev/null; then
  echo "[+] Eliminando usuario conflictivo: ossec"
  userdel -r ossec 2>/dev/null
fi

if getent group ossec &>/dev/null; then
  echo "[+] Eliminando grupo conflictivo: ossec"
  groupdel ossec 2>/dev/null
fi

# --- CREAR GRUPO ossec SI NO EXISTE ---
if ! getent group ossec &>/dev/null; then
  echo "[+] Creando grupo ossec..."
  groupadd ossec
fi

# --- CONFIGURACIÓN DE ossec.conf ---
echo "[+] Descargando ossec.conf desde GitHub..."
curl -s -o /var/ossec/etc/ossec.conf "$OSSEC_CONF_URL"

echo "[+] Validando formato XML de ossec.conf..."
if ! command -v xmllint &>/dev/null; then
  echo "[-] xmllint no está instalado. Instalando..."
  if command -v apt &>/dev/null; then
    apt install -y libxml2-utils
  else
    yum install -y libxml2
  fi
fi

if ! xmllint --noout /var/ossec/etc/ossec.conf; then
  echo "❌ El archivo ossec.conf contiene errores XML. Abortando."
  exit 1
fi

echo "[+] Estableciendo permisos..."
chown root:ossec /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf

# --- CLAVE DE REGISTRO AUTOMÁTICO ---
echo "$AUTH_PASS" > /var/ossec/etc/authd.pass
chmod 600 /var/ossec/etc/authd.pass

# --- INICIO DEL SERVICIO ---
echo "[+] Iniciando el servicio wazuh-agent..."
systemctl daemon-reexec
systemctl enable wazuh-agent
systemctl restart wazuh-agent

echo "[✔] Agente instalado correctamente en: $(hostname)"
systemctl status wazuh-agent --no-pager | grep Active

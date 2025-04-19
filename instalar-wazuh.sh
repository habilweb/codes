#!/bin/bash

set -e

AGENTE_NAME=$(hostname -f)
MANAGER_HOST="agente.webhosting.com.bo"
AUTH_PASS="clave-secreta"

echo "[+] Detectando sistema operativo..."
if [ -f /etc/redhat-release ]; then
  echo "[+] RHEL/AlmaLinux/CloudLinux detectado"
else
  echo "[✘] Sistema no soportado en este script."
  exit 1
fi

# Detener agente si existe
systemctl stop wazuh-agent 2>/dev/null || true

# Limpiar instalaciones previas
rm -rf /var/ossec
rpm -e wazuh-agent --noscripts 2>/dev/null || true
groupdel ossec 2>/dev/null || true
userdel -r ossece 2>/dev/null || true

# Descargar e instalar el agente
curl -s -O https://packages.wazuh.com/4.x/yum/wazuh-agent-4.11.2-1.x86_64.rpm
rpm -ivh wazuh-agent-4.11.2-1.x86_64.rpm

# Crear configuración personalizada para cPanel
mkdir -p /var/ossec/etc
cat <<EOF > /var/ossec/etc/ossec.conf
<ossec_config>
  <client>
    <server>
      <address>$MANAGER_HOST</address>
      <port>1514</port>
      <protocol>udp</protocol>
    </server>
    <enrollment>
      <enabled>yes</enabled>
      <agent_name>$AGENTE_NAME</agent_name>
      <authorization_pass_path>etc/authd.pass</authorization_pass_path>
    </enrollment>
  </client>

  <client_buffer>
    <disabled>no</disabled>
    <queue_size>5000</queue_size>
    <events_per_second>500</events_per_second>
  </client_buffer>

  <wodle name="syscollector">
    <disabled>no</disabled>
    <interval>1h</interval>
    <scan_on_start>yes</scan_on_start>
    <hardware>yes</hardware>
    <os>yes</os>
    <network>yes</network>
    <packages>yes</packages>
    <ports all="no">yes</ports>
    <processes>yes</processes>
  </wodle>

  <rootcheck>
    <disabled>no</disabled>
    <frequency>43200</frequency>
  </rootcheck>

  <sca>
    <enabled>yes</enabled>
    <scan_on_start>yes</scan_on_start>
    <interval>12h</interval>
  </sca>

  <syscheck>
    <disabled>no</disabled>
    <frequency>43200</frequency>
    <scan_on_start>yes</scan_on_start>

    <directories check_all="yes" realtime="yes">/home/*/public_html/.htaccess</directories>
    <directories check_all="yes" realtime="yes">/home/*/public_html/wp-config.php</directories>
    <directories check_all="yes" realtime="yes">/home/*/public_html/index.php</directories>

    <ignore>/home/*/tmp</ignore>
    <ignore>/home/*/mail</ignore>

    <skip_nfs>yes</skip_nfs>
    <skip_dev>yes</skip_dev>
    <skip_proc>yes</skip_proc>
    <skip_sys>yes</skip_sys>
  </syscheck>

  <localfile>
    <log_format>command</log_format>
    <command>df -P</command>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>netstat -tulpn</command>
    <alias>netstat listening ports</alias>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>last -n 20</command>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>apache</log_format>
    <location>/usr/local/apache/domlogs/*</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/usr/local/cpanel/logs/access_log</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/usr/local/cpanel/logs/login_log</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/exim_mainlog</location>
  </localfile>
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/nginx/access.log</location>
  </localfile>
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/nginx/error.log</location>
  </localfile>

  <active-response>
    <disabled>no</disabled>
    <ca_store>etc/wpk_root.pem</ca_store>
    <ca_verification>yes</ca_verification>
  </active-response>

  <logging>
    <log_format>plain</log_format>
  </logging>
</ossec_config>
EOF

# Crear clave de autenticación
echo "$AUTH_PASS" > /var/ossec/etc/authd.pass
chmod 600 /var/ossec/etc/authd.pass
chown root:ossec /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf

# Iniciar servicio
systemctl daemon-reexec
systemctl enable wazuh-agent
systemctl restart wazuh-agent
systemctl status wazuh-agent --no-pager

echo "[✔] Agente instalado correctamente en: $AGENTE_NAME"

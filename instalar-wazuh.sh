#!/bin/bash

echo "[+] Detectando sistema operativo..."
OS=$(grep -Ei 'rhel|almalinux|cloudlinux' /etc/os-release)
if [[ -n "$OS" ]]; then
    echo "[+] RHEL/AlmaLinux/CloudLinux detectado"
else
    echo "[✘] Sistema no compatible por este script. Solo se admite RHEL/AlmaLinux/CloudLinux."
    exit 1
fi

echo "[+] Descargando e instalando Wazuh Agent..."
curl -s -O https://packages.wazuh.com/4.x/yum/wazuh-agent-4.11.2-1.x86_64.rpm
rpm -ivh wazuh-agent-4.11.2-1.x86_64.rpm

echo "[+] Verificando grupo y usuario ossec..."
if ! getent group ossec >/dev/null; then
    echo "    -> Creando grupo ossec"
    groupadd ossec
fi

if ! id ossec >/dev/null 2>&1; then
    echo "    -> Creando usuario ossec"
    useradd -r -g ossec -s /sbin/nologin ossec
fi

echo "[+] Descargando ossec.conf desde GitHub..."
curl -s -o /var/ossec/etc/ossec.conf https://raw.githubusercontent.com/habilweb/codes/main/ossec.conf

echo "[+] Validando formato XML..."
xmllint --noout /var/ossec/etc/ossec.conf || {
    echo "[✘] Error: El archivo ossec.conf no es válido XML"
    exit 1
}

echo "[+] Estableciendo permisos correctos..."
chown root:ossec /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf

echo "[+] Creando authd.pass..."
echo "clave-secreta" > /var/ossec/etc/authd.pass
chmod 600 /var/ossec/etc/authd.pass
chown root:ossec /var/ossec/etc/authd.pass

echo "[+] Iniciando el servicio wazuh-agent..."
systemctl daemon-reexec
systemctl enable wazuh-agent
systemctl restart wazuh-agent

echo "[✔] Agente instalado correctamente en: $(hostname -f)"
systemctl status wazuh-agent --no-pager | grep Active

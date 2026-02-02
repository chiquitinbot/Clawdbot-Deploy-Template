# 🔒 SECURITY - Mejores Prácticas

Este documento detalla todas las medidas de seguridad implementadas y recomendadas.

---

## ✅ Medidas Implementadas Automáticamente

### 1. Firewall (UFW)

El script de bootstrap configura UFW automáticamente:

```bash
# Solo permite estos puertos
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (para SSL redirect)
ufw allow 443/tcp   # HTTPS
ufw default deny incoming
ufw default allow outgoing
ufw enable
```

**Puertos bloqueados por defecto:**
- ❌ 8080 (APIs internas)
- ❌ 5678 (n8n)
- ❌ 18789 (OpenClaw gateway)
- ❌ Todos los demás

### 2. Permisos de Archivos

```bash
# Secrets con permisos restrictivos
chmod 600 ~/.env
chmod 600 ~/.config/**/credentials.json
chmod 600 ~/.config/**/cookies.json
chmod 700 ~/agent/.secrets/

# SSH keys
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
chmod 600 ~/.ssh/authorized_keys
```

### 3. SSH Hardening

Configuración recomendada en `/etc/ssh/sshd_config`:

```bash
# Deshabilitar login con password
PasswordAuthentication no
PermitEmptyPasswords no

# Deshabilitar root con password (solo key)
PermitRootLogin prohibit-password

# Limitar intentos
MaxAuthTries 3
MaxSessions 5

# Timeout de conexiones inactivas
ClientAliveInterval 300
ClientAliveCountMax 2

# Solo SSH protocol 2
Protocol 2
```

### 4. Variables de Entorno

```bash
# NUNCA hardcodear secrets en código
# ❌ MAL:
export API_KEY="sk-ant-xxx" # en .bashrc público

# ✅ BIEN:
# Usar archivo .env con permisos 600
# El archivo está en .gitignore
```

### 5. Git Security

`.gitignore` incluye:
```
.env
*.env
.env.*
!.env.example
credentials.json
cookies.json
*.key
*.pem
.secrets/
```

---

## 🛡️ Medidas Adicionales Recomendadas

### 1. Fail2ban (Anti brute-force)

```bash
# Instalar
apt install fail2ban

# Configurar /etc/fail2ban/jail.local
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

# Activar
systemctl enable fail2ban
systemctl start fail2ban
```

### 2. Actualizaciones Automáticas

```bash
# Instalar unattended-upgrades
apt install unattended-upgrades

# Configurar
dpkg-reconfigure -plow unattended-upgrades

# Verificar
cat /etc/apt/apt.conf.d/20auto-upgrades
# Debe mostrar:
# APT::Periodic::Update-Package-Lists "1";
# APT::Periodic::Unattended-Upgrade "1";
```

### 3. SSL/TLS con Let's Encrypt

```bash
# Instalar certbot
apt install certbot

# Obtener certificado
certbot certonly --standalone -d tu-dominio.com

# Auto-renovación (ya configurado por defecto)
systemctl status certbot.timer
```

### 4. Docker Security

```bash
# No correr containers como root cuando sea posible
docker run --user 1000:1000 ...

# Limitar recursos
docker run --memory=512m --cpus=1 ...

# No exponer puertos innecesariamente
# ❌ MAL:
docker run -p 8080:8080 ...  # Expone a internet

# ✅ BIEN:
docker run -p 127.0.0.1:8080:8080 ...  # Solo localhost
```

### 5. Backups Encriptados

```bash
# Backup del workspace
tar -czf - ~/agent | gpg --symmetric --cipher-algo AES256 > backup-$(date +%Y%m%d).tar.gz.gpg

# Subir a storage seguro (no en el mismo servidor)
rclone copy backup-*.gpg remote:backups/
```

---

## 🔐 Checklist de Seguridad

### Antes del Deploy

- [ ] Generar SSH key nueva (Ed25519)
- [ ] Agregar key a Digital Ocean / servidor
- [ ] Preparar .env con todos los secrets
- [ ] Verificar que .gitignore incluye secrets

### Después del Deploy

- [ ] Verificar UFW está activo: `ufw status`
- [ ] Verificar permisos de .env: `ls -la ~/.env`
- [ ] Verificar SSH config: `grep PasswordAuth /etc/ssh/sshd_config`
- [ ] Instalar fail2ban
- [ ] Configurar actualizaciones automáticas
- [ ] Configurar SSL si tienes dominio

### Periódicamente

- [ ] Rotar API keys cada 90 días
- [ ] Revisar logs: `journalctl -u sshd | grep Failed`
- [ ] Actualizar sistema: `apt update && apt upgrade`
- [ ] Verificar backups funcionan
- [ ] Revisar puertos abiertos: `ss -tlnp`

---

## 🚨 Qué Hacer Si...

### Crees que comprometieron una API key

1. **Revoca inmediatamente** en el dashboard del proveedor
2. Genera nueva key
3. Actualiza .env
4. Reinicia servicios: `openclaw gateway restart`
5. Revisa logs por uso sospechoso

### Ves intentos de login fallidos

```bash
# Ver intentos fallidos
grep "Failed password" /var/log/auth.log | tail -20

# Si hay muchos de una IP, banearla
ufw deny from 1.2.3.4

# O instalar fail2ban que lo hace automático
```

### Necesitas acceso de emergencia

```bash
# Desde Digital Ocean console (si SSH no funciona)
# 1. Ir a Droplet > Access > Launch Recovery Console
# 2. Login como root
# 3. Arreglar SSH config si está roto
```

---

## 📊 Auditoría de Seguridad

Script para verificar estado de seguridad:

```bash
#!/bin/bash
echo "=== Security Audit ==="

echo -e "\n[UFW Status]"
ufw status | head -10

echo -e "\n[SSH Config]"
grep -E "PasswordAuth|PermitRoot" /etc/ssh/sshd_config

echo -e "\n[Failed Logins (last 24h)]"
grep "Failed" /var/log/auth.log | wc -l

echo -e "\n[Open Ports]"
ss -tlnp | grep LISTEN

echo -e "\n[File Permissions]"
ls -la ~/.env 2>/dev/null || echo ".env not found"
ls -la ~/.ssh/ 2>/dev/null | head -5

echo -e "\n[Fail2ban Status]"
systemctl is-active fail2ban 2>/dev/null || echo "not installed"

echo -e "\n[Updates Available]"
apt list --upgradable 2>/dev/null | wc -l
```

---

## 🔗 Referencias

- [Digital Ocean Security Best Practices](https://docs.digitalocean.com/products/droplets/how-to/secure/)
- [SSH Hardening Guide](https://www.ssh-audit.com/hardening_guides.html)
- [Docker Security](https://docs.docker.com/engine/security/)
- [OWASP Security Guidelines](https://owasp.org/www-project-web-security-testing-guide/)

# 🤖 Clawdbot Deploy Template

**Deploy automatizado de OpenClaw AI agents en segundos.**

Infraestructura como código para desplegar tu propio agente AI personal — ya sea en tu máquina local o en un VPS de Digital Ocean. Todo automatizado, seguro, y listo para producción.

## 🚀 Quick Start

### Modo Básico (sin dominio)

```bash
# 1. Clonar
git clone https://github.com/chiquitinbot/Clawdbot-Deploy-Template
cd Clawdbot-Deploy-Template

# 2. Configurar
cp .env.example .env
nano .env  # Llenar con tus API keys

# 3. Validar
./scripts/validate-env.sh

# 4. Deploy
./scripts/bootstrap-vps.sh      # VPS
./scripts/bootstrap-local.sh    # Mac/Linux local

# 5. Iniciar
openclaw wizard        # Primera vez
openclaw gateway start # Iniciar agente
```

### Modo Completo (con dominio + SSL)

```bash
# 1-4. Igual que arriba...

# 5. Configurar DNS (apuntar dominio a IP del VPS)

# 6. Configurar SSL
./scripts/setup-nginx-ssl.sh agent.tudominio.com

# 7. Iniciar
openclaw wizard
openclaw gateway start

# Tu agente estará en https://agent.tudominio.com
```

## ⚠️ ANTES DE EMPEZAR

**Lee [PREREQUISITES.md](PREREQUISITES.md) para obtener todo lo necesario.**

### Checklist obligatorio:
- [ ] **Anthropic API Key** o Claude Max subscription
- [ ] **Discord Bot Token** O **Telegram Bot Token** (al menos uno)

### Opcional:
- [ ] **Dominio** - Solo si quieres SSL y webhooks externos
- [ ] Gemini API Key - gratis, para tareas económicas
- [ ] Digital Ocean Token - si usas Terraform

### Dos modos de deploy:

| Modo | Dominio | Nginx | SSL | Webhooks |
|------|---------|-------|-----|----------|
| **Básico** | ❌ No | ❌ No | ❌ No | ❌ No |
| **Completo** | ✅ Sí | ✅ Sí | ✅ Sí | ✅ Sí |

---

## 📋 Qué incluye

### Core
- **OpenClaw** - Framework de agente AI
- **Workspace** - Estructura de archivos (SOUL.md, AGENTS.md, etc.)
- **Cron Jobs** - Tareas programadas

### Integraciones
- **Discord** - Canal de comunicación principal
- **Telegram** - Canal alternativo
- **Gmail** - Clasificación automática de emails (gog CLI)
- **Twitter/X** - Engagement social (bird CLI)
- **Google Calendar** - Eventos y recordatorios

### Infraestructura
- **UFW** - Firewall configurado
- **SSL** - Certificados Let's Encrypt (opcional)
- **Supabase** - Base de datos para dashboard (opcional)

### Dashboard
- **Agent Dashboard** - Next.js + Supabase (Mission Control UI)
- **Mission Control** - Kanban de tareas
- **Agent Profiles** - Visualización de agentes

### Judgment System
- **DeepEval** - Evaluación de decisiones con LLM-as-Judge
- **Risk Matrix** - Clasificación automática de riesgo
- **Confidence Scoring** - Calibración de confianza
- **Decision Logging** - Auditoría de todas las decisiones

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    LOCAL / VPS                               │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    OPENCLAW GATEWAY                      ││
│  │                                                         ││
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    ││
│  │  │ Discord │  │Telegram │  │  Cron   │  │  Tools  │    ││
│  │  │   Bot   │  │   Bot   │  │  Jobs   │  │ gog/bird│    ││
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    ││
│  │                                                         ││
│  │  ┌─────────────────────────────────────────────────┐   ││
│  │  │              AI Model (Claude)                   │   ││
│  │  └─────────────────────────────────────────────────┘   ││
│  └─────────────────────────────────────────────────────────┘│
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                      WORKSPACE                           ││
│  │   ~/agent/                                              ││
│  │   ├── SOUL.md          (Personalidad)                   ││
│  │   ├── AGENTS.md        (Instrucciones)                  ││
│  │   ├── USER.md          (Info del usuario)               ││
│  │   ├── MEMORY.md        (Memoria largo plazo)            ││
│  │   ├── memory/          (Logs diarios)                   ││
│  │   ├── scripts/         (Automatizaciones)               ││
│  │   └── projects/        (Proyectos)                      ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SERVICIOS EXTERNOS                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │Anthropic│  │ Google  │  │ Discord │  │ Telegram│        │
│  │ Claude  │  │ Gemini  │  │   API   │  │   API   │        │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Deployment

### Opción 1: Terraform (VPS - Recomendado)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores
terraform init
terraform plan
terraform apply
```

### Opción 2: Script Bootstrap (VPS existente)

```bash
curl -fsSL https://raw.githubusercontent.com/mexaverse/agent-template/main/scripts/bootstrap-vps.sh | bash
```

### Opción 3: Bare Metal (Mac/Linux)

```bash
./scripts/bootstrap-local.sh
```

## ⚙️ Configuración Post-Deploy

1. **Anthropic API Key**
   ```bash
   openclaw auth add anthropic --mode api_key
   ```

2. **Discord Bot**
   - Crear bot en https://discord.com/developers
   - Copiar token
   - Actualizar config

3. **Gmail (opcional)**
   ```bash
   gog auth add tu@email.com --services gmail,calendar
   ```

4. **Twitter (opcional)**
   - Obtener cookies AUTH_TOKEN y CT0
   - Configurar en ~/.bashrc

## 📁 Estructura del Workspace

```
/root/agent/
├── SOUL.md              # Personalidad del agente
├── AGENTS.md            # Instrucciones operativas
├── USER.md              # Info del usuario (tú)
├── IDENTITY.md          # Nombre, avatar, etc.
├── MEMORY.md            # Memoria de largo plazo
├── TOOLS.md             # Notas de herramientas
├── HEARTBEAT.md         # Tareas de heartbeat
├── JUDGMENT-RULES.md    # Reglas de decisión
├── memory/              # Logs diarios
│   └── YYYY-MM-DD.md
├── scripts/             # Scripts de automatización
├── projects/            # Proyectos activos
├── skills/              # Skills custom
└── .secrets/            # Credenciales (chmod 600)
```

## 🔧 Variables de Entorno Requeridas

```bash
# Core
ANTHROPIC_API_KEY=sk-ant-...

# Google (opcional)
GOG_KEYRING_PASSWORD=...
GOG_ACCOUNT=tu@email.com
GEMINI_API_KEY=...

# Twitter (opcional)
AUTH_TOKEN=...
CT0=...

# Dashboard (opcional)
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

## 📱 Cron Jobs Incluidos

| Job | Frecuencia | Descripción |
|-----|------------|-------------|
| Email Classifier | 15 min | Clasifica emails con AI |
| Morning Briefing | 8 AM L-V | Resumen diario |
| Twitter Activity | 2 horas | Engagement social |
| BTC Alert | 4 horas | Alertas de precio |

## 🔒 Seguridad

**Ver [SECURITY.md](SECURITY.md) para guía completa.**

### Implementado automáticamente:
- ✅ UFW firewall (solo 22, 80, 443)
- ✅ SSH hardening (password auth disabled)
- ✅ Fail2ban (anti brute-force)
- ✅ Automatic security updates
- ✅ Secure file permissions (600/700)
- ✅ .gitignore para secrets

### Script de auditoría:
```bash
./scripts/security-audit.sh
```

### Checklist post-deploy:
- [ ] Verificar UFW: `ufw status`
- [ ] Verificar SSH: `grep PasswordAuth /etc/ssh/sshd_config`
- [ ] Verificar fail2ban: `systemctl status fail2ban`
- [ ] Configurar SSL si tienes dominio

## 🖥️ Dashboard (Opcional)

El template incluye un **Dashboard visual** (Mission Control) para gestionar tu agente.

**Repo:** https://github.com/chiquitinbot/autonomis-dashboard

### Features:
- Kanban de tareas con drag & drop
- Perfiles de agentes
- Chat con agentes
- Broadcast a todos los agentes
- Live feed de actividad
- Mobile responsive

### Deploy:

1. **Fork el repo** del dashboard

2. **Crear proyecto en Supabase:**
   - Ir a https://supabase.com
   - Crear proyecto
   - Correr el SQL de `supabase-schema.sql`

3. **Deploy en Vercel:**
   ```bash
   # En el repo del dashboard
   vercel --prod
   # Agregar env vars:
   # NEXT_PUBLIC_SUPABASE_URL
   # NEXT_PUBLIC_SUPABASE_ANON_KEY
   ```

4. **Conectar con tu agente** via webhooks de Supabase

## 📖 Documentación

- [Configuración detallada](docs/configuration.md)
- [Personalización del agente](docs/customization.md)
- [Agregar integraciones](docs/integrations.md)
- [Dashboard setup](docs/dashboard.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Créditos

Template basado en Chiquitín 🦀 - el asistente AI de @mexaverse

# 🤖 Autonomis Agent Template

Template completo para desplegar un agente AI personal con la arquitectura de Chiquitín.

## ⚠️ ANTES DE EMPEZAR

**Lee [PREREQUISITES.md](PREREQUISITES.md) primero!**

Necesitas tener listas TODAS tus API keys y credenciales antes de correr cualquier script.

### Quick Checklist:
- [ ] Anthropic API Key (obligatorio)
- [ ] Discord Bot Token O Telegram Bot Token (al menos uno)
- [ ] Gemini API Key (recomendado, es gratis)
- [ ] Digital Ocean Token (si usas Terraform)

```bash
# Validar que tienes todo configurado:
cp .env.example .env
# Editar .env con tus valores
./scripts/validate-env.sh
```

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
- **Docker** - n8n, nginx, servicios custom
- **UFW** - Firewall configurado
- **SSL** - Certificados Let's Encrypt
- **Supabase** - Base de datos para dashboard

### Dashboard
- **Autonomis Dashboard** - Next.js + Supabase
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
│                     DIGITAL OCEAN VPS                        │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                      NGINX (443)                         ││
│  │         SSL + Reverse Proxy + WebSocket                  ││
│  └─────────────────────────────────────────────────────────┘│
│           │                    │                             │
│           ▼                    ▼                             │
│  ┌──────────────┐    ┌──────────────┐                       │
│  │     n8n      │    │   CrewAI     │                       │
│  │   (5678)     │    │   (8080)     │                       │
│  └──────────────┘    └──────────────┘                       │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    OPENCLAW GATEWAY                      ││
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    ││
│  │  │ Discord │  │Telegram │  │  Cron   │  │  Tools  │    ││
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    ││
│  └─────────────────────────────────────────────────────────┘│
│                           │                                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                      WORKSPACE                           ││
│  │   /root/agent/                                          ││
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
│  │ Anthropic│  │ Google  │  │ Supabase│  │ Discord │        │
│  │   API   │  │  APIs   │  │   DB    │  │   Bot   │        │
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

El template incluye **Autonomis Dashboard** - un Mission Control visual para tu agente.

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

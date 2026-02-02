# 📋 PREREQUISITES - Todo lo que necesitas ANTES de empezar

**⚠️ IMPORTANTE: Reúne TODO esto antes de correr cualquier script.**

---

## ✅ Checklist

### 🔑 Anthropic (OBLIGATORIO - elige una opción)

**Opción A: API Key (pago por uso)**
| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ Anthropic API Key | https://console.anthropic.com/settings/keys | `ANTHROPIC_API_KEY` |

**Opción B: Claude Max Subscription ($100-200/mes, uso ilimitado)**
| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ Claude Max Token | https://claude.ai → Settings → API | `ANTHROPIC_API_KEY` |

> 💡 **¿Cuál elegir?**
> - **API Key**: Mejor si usas poco (~$3-15/mes)
> - **Claude Max**: Mejor si usas mucho (ilimitado por $100-200/mes)

### 🔑 API Keys (Opcionales pero recomendadas)

| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ Google/Gemini API Key | https://aistudio.google.com/apikey | `GEMINI_API_KEY` |
| ☐ OpenAI API Key | https://platform.openai.com/api-keys | `OPENAI_API_KEY` |

### 💬 Canales de Comunicación (al menos uno)

| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ Discord Bot Token | https://discord.com/developers/applications | `DISCORD_BOT_TOKEN` |
| ☐ Discord Guild ID | Click derecho en servidor > Copy Server ID | `DISCORD_GUILD_ID` |
| ☐ Discord Channel ID | Click derecho en canal > Copy Channel ID | `DISCORD_CHANNEL_ID` |
| ☐ Telegram Bot Token | https://t.me/BotFather → /newbot | `TELEGRAM_BOT_TOKEN` |

### 🌐 Dominio (OBLIGATORIO)

| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ Dominio registrado | Namecheap, Cloudflare, GoDaddy, etc. | `DOMAIN` |
| ☐ Subdominio para el agente | Ej: agent.tudominio.com | `AGENT_SUBDOMAIN` |

> 💡 El dominio es necesario para SSL (HTTPS) y webhooks. Puedes usar un subdominio de un dominio que ya tengas.

### ☁️ Infraestructura (VPS)

| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ Digital Ocean Token | https://cloud.digitalocean.com/account/api/tokens | `DO_TOKEN` |
| ☐ SSH Key Fingerprint | `doctl compute ssh-key list` o DO dashboard | `SSH_KEY_NAME` |

### 📧 Google Workspace (opcional)

| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ Google Cloud Project | https://console.cloud.google.com | - |
| ☐ OAuth Client ID | GCP > APIs & Services > Credentials | `credentials.json` |
| ☐ Cuenta de Gmail | Tu email de Google Workspace o Gmail | `GOG_ACCOUNT` |

### 🐦 Twitter/X (opcional)

| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ AUTH_TOKEN cookie | Browser DevTools en x.com | `AUTH_TOKEN` |
| ☐ CT0 cookie | Browser DevTools en x.com | `CT0` |

### 🖥️ Dashboard (opcional)

| Item | Dónde obtenerlo | Variable |
|------|-----------------|----------|
| ☐ Supabase Project URL | https://supabase.com > Project Settings > API | `SUPABASE_URL` |
| ☐ Supabase Anon Key | Supabase > Project Settings > API | `SUPABASE_ANON_KEY` |
| ☐ Vercel Account | https://vercel.com | - |

---

## 📝 Instrucciones Detalladas

### 1. Anthropic - API Key o Claude Max (OBLIGATORIO)

**Opción A: API Key (pago por uso)**

1. Ve a https://console.anthropic.com/
2. Crea cuenta o inicia sesión
3. Ve a Settings > API Keys
4. Click "Create Key"
5. Copia la key (empieza con `sk-ant-`)

**Costo:** ~$3/millón de tokens con Claude Sonnet, ~$15/millón con Opus

---

**Opción B: Claude Max Subscription (uso ilimitado)**

1. Ve a https://claude.ai/
2. Suscríbete a Claude Max ($100 o $200/mes)
3. Ve a Settings > API (o claude.ai/settings)
4. Genera un token de API
5. Copia el token

**Costo:** $100/mes (Max) o $200/mes (Max con más límites)

> 💡 Claude Max es mejor si planeas usar el agente intensivamente (muchas conversaciones, tareas largas, múltiples agentes)

---

### 2. Discord Bot

1. Ve a https://discord.com/developers/applications
2. Click "New Application" → nombre: tu-agente-bot
3. Ve a "Bot" en el sidebar
4. Click "Reset Token" → Copia el token
5. Habilita estos Intents:
   - ✅ MESSAGE CONTENT INTENT
   - ✅ SERVER MEMBERS INTENT
   - ✅ PRESENCE INTENT
6. Ve a "OAuth2" > "URL Generator"
   - Scopes: `bot`, `applications.commands`
   - Permissions: `Send Messages`, `Read Message History`, `Add Reactions`
7. Copia la URL y ábrela para invitar el bot a tu servidor

**Para obtener IDs:**
- Habilita Developer Mode: Discord Settings > Advanced > Developer Mode
- Click derecho en servidor → Copy Server ID (Guild ID)
- Click derecho en canal → Copy Channel ID

---

### 3. Telegram Bot

1. Abre Telegram y busca @BotFather
2. Envía `/newbot`
3. Sigue las instrucciones (nombre, username)
4. Copia el token que te da

---

### 4. Google/Gemini API Key

1. Ve a https://aistudio.google.com/apikey
2. Click "Create API Key"
3. Selecciona o crea un proyecto
4. Copia la key

**Gratis:** 15 RPM, 1M tokens/día

---

### 5. Dominio y DNS (OBLIGATORIO)

Necesitas un dominio para SSL y webhooks.

**Opción A: Usar subdominio de dominio existente**

1. Ve al panel de DNS de tu dominio (Cloudflare, Namecheap, etc.)
2. Crea un registro A:
   - Nombre: `agent` (o el subdominio que quieras)
   - Tipo: A
   - Valor: IP de tu VPS (la obtienes después de crear el droplet)
   - TTL: Auto o 300

**Opción B: Registrar dominio nuevo**

1. Compra un dominio en Namecheap, Cloudflare, etc. (~$10-15/año)
2. Apunta los nameservers a Digital Ocean (opcional) o configura DNS en el registrar
3. Crea registro A apuntando a tu VPS

**Ejemplo de configuración DNS:**
```
agent.midominio.com  →  A  →  167.99.123.45  (IP del VPS)
```

---

### 6. Digital Ocean (para Terraform)

1. Ve a https://cloud.digitalocean.com/account/api/tokens
2. Click "Generate New Token"
3. Nombre: agent-terraform
4. Permisos: Read + Write
5. Copia el token

**Para SSH Key:**
```bash
# Si no tienes una, créala:
ssh-keygen -t ed25519 -C "tu@email.com"

# Sube a DO:
doctl compute ssh-key create my-key --public-key-file ~/.ssh/id_ed25519.pub

# O manualmente en DO dashboard > Settings > Security > SSH Keys
```

---

### 6. Twitter Cookies

1. Inicia sesión en https://x.com
2. Abre DevTools (F12)
3. Ve a Application > Cookies > https://x.com
4. Busca y copia:
   - `auth_token` → `AUTH_TOKEN`
   - `ct0` → `CT0`

**Nota:** Estas cookies expiran. Si el bot deja de funcionar, actualízalas.

---

### 7. Supabase (Dashboard)

1. Ve a https://supabase.com y crea cuenta
2. Click "New Project"
3. Nombre: autonomis-dashboard
4. Genera password seguro (guárdalo)
5. Espera a que se cree (~2 min)
6. Ve a Project Settings > API
7. Copia:
   - Project URL → `SUPABASE_URL`
   - anon/public key → `SUPABASE_ANON_KEY`

---

## 🚀 Una vez que tengas todo

1. Copia `.env.example` a `.env`
2. Llena todas las variables que apliquen
3. Corre el script de tu elección:
   - Terraform: `cd terraform && terraform apply`
   - VPS: `./scripts/bootstrap-vps.sh`
   - Local: `./scripts/bootstrap-local.sh`

---

## ❓ FAQ

**¿Puedo empezar sin todo?**
Sí, pero mínimo necesitas:
- Anthropic API Key (el agente no funciona sin esto)
- Al menos un canal (Discord o Telegram)

**¿Cuánto cuesta?**
- Anthropic: ~$3-15/mes uso normal
- Gemini: Gratis hasta cierto límite
- Digital Ocean: $6-24/mes
- Supabase: Gratis tier disponible
- Vercel: Gratis tier disponible

**¿Puedo usar otros proveedores de LLM?**
OpenClaw soporta: Anthropic, OpenAI, Google, Amazon Bedrock, y más.

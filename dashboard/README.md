# 🖥️ Autonomis Dashboard

Visual Mission Control para tu agente AI.

**Repo completo:** https://github.com/chiquitinbot/autonomis-dashboard

## Features

- 📋 **Kanban Board** - Tareas con drag & drop
- 👥 **Agent Profiles** - Ver status de cada agente
- 💬 **Chat** - Mensajes directos a agentes
- 📡 **Broadcast** - Enviar a todos los agentes
- 📊 **Live Feed** - Actividad en tiempo real
- 📱 **Mobile Responsive** - Funciona en cualquier dispositivo

## Quick Deploy

### 1. Supabase

1. Crear cuenta en [supabase.com](https://supabase.com)
2. Crear nuevo proyecto
3. Ir a SQL Editor
4. Copiar y ejecutar `supabase-schema.sql`
5. Copiar URL y anon key de Settings > API

### 2. Vercel

1. Fork https://github.com/chiquitinbot/autonomis-dashboard
2. Ir a [vercel.com](https://vercel.com)
3. Import tu fork
4. Agregar Environment Variables:
   - `NEXT_PUBLIC_SUPABASE_URL` = tu URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = tu anon key
5. Deploy!

### 3. Conectar con Agente

El agente puede interactuar con el dashboard via:

**Supabase JS Client:**
```javascript
import { createClient } from '@supabase/supabase-js'
const supabase = createClient(url, key)

// Crear ticket
await supabase.from('tickets').insert({
  id: 'TASK-001',
  title: 'Nueva tarea',
  assignee: 'Chiquitín'
})

// Agregar comentario
await supabase.from('comments').insert({
  ticket_id: 'TASK-001',
  author: 'Agent',
  content: 'Tarea completada!'
})
```

**O via REST API:**
```bash
curl -X POST 'https://xxx.supabase.co/rest/v1/tickets' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id":"TASK-001","title":"Test","assignee":"Agent"}'
```

## Customization

### Colores de Agentes

Editar en `src/app/mission-control/page.tsx`:

```typescript
const agents = [
  { 
    name: 'Mi Agente', 
    color: 'from-blue-500 to-cyan-600',
    icon: Bot,
    // ...
  }
]
```

### Columnas del Kanban

```typescript
const statusColumns = [
  { id: "backlog", title: "INBOX" },
  { id: "todo", title: "TODO" },
  // Agregar/modificar columnas
]
```

## Tech Stack

- Next.js 15 (App Router)
- Tailwind CSS
- shadcn/ui
- Supabase (Postgres + Realtime)
- Vercel (hosting)

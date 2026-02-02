# 🧠 Mission Control - Judgment System

Sistema de toma de decisiones con evaluación continua usando DeepEval.

## Concepto

Basado en el artículo "Judgment-First AI" - los agentes deben evaluar riesgo × confianza antes de actuar.

```
┌─────────────────────────────────────────────────┐
│              JUDGMENT MATRIX                     │
├─────────────────────────────────────────────────┤
│                 CONFIDENCE                       │
│         Low(<30)  Med(30-70)  High(>70)         │
│  ┌────────────────────────────────────────────┐ │
│  │ Low    ESCALAR   FLAG      ACT             │ │
│R │ Med    ESCALAR   FLAG      ACT             │ │
│I │ High   BLOCK     ESCALAR   FLAG            │ │
│S │ Crit   BLOCK     BLOCK     ESCALAR         │ │
│K │                                            │ │
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

## Componentes

### 1. judgment.js
Módulo principal de evaluación de decisiones.

```javascript
const { evaluateDecision, logDecision } = require('./lib/judgment');

const decision = await evaluateDecision({
  action: 'send_email',
  context: 'User asked to send email to boss',
  risk: 'medium',
  confidence: 75
});

// decision.action = 'ACT' | 'FLAG' | 'ESCALATE' | 'BLOCK'
```

### 2. evaluator.py
Evaluación con DeepEval usando LLM-as-Judge.

```bash
# Evaluar decisiones del día
python lib/evaluator.py --date 2024-02-01

# Evaluar última decisión
python lib/evaluator.py --last
```

## Setup

### 1. Instalar DeepEval

```bash
pip install deepeval
```

### 2. Configurar API Key

```bash
# Para usar Gemini como judge (más económico)
export GEMINI_API_KEY="tu-key"

# O para usar OpenAI
export OPENAI_API_KEY="tu-key"
```

### 3. Crear directorio de logs

```bash
mkdir -p logs
```

## Uso en el Agente

### Antes de acciones de riesgo:

```javascript
// En tu código del agente
const judgment = require('./mission-control/lib/judgment');

async function handleUserRequest(request) {
  // Evaluar la acción
  const decision = await judgment.evaluateDecision({
    action: request.action,
    context: request.context,
    input: request.input,
    risk: determineRisk(request),
    confidence: calculateConfidence(request)
  });

  // Actuar según el resultado
  switch(decision.action) {
    case 'ACT':
      return executeAction(request);
    case 'FLAG':
      logWarning(decision);
      return executeAction(request);
    case 'ESCALATE':
      return askUserForApproval(request, decision);
    case 'BLOCK':
      return rejectAction(decision.reason);
  }
}
```

### Clasificación de Riesgo:

| Riesgo | Ejemplos |
|--------|----------|
| **low** | Leer archivos, buscar, listar |
| **medium** | Modificar archivos, crear cosas |
| **high** | Enviar mensajes externos, postear |
| **critical** | Borrar, mover dinero, credenciales |

## Métricas de DeepEval

El evaluator.py mide:

1. **Decision Quality** - ¿La decisión fue correcta?
2. **Confidence Calibration** - ¿La confianza reportada fue precisa?
3. **Escalation Judgment** - ¿Escaló cuando debía?

## Logs

Las decisiones se guardan en `logs/decisions.jsonl`:

```json
{
  "timestamp": "2024-02-01T12:00:00Z",
  "action": "send_tweet",
  "risk": "high",
  "confidence": 85,
  "decision": "FLAG",
  "reason": "High confidence but high risk - proceeding with warning"
}
```

## Cron Job de Evaluación

Agregar evaluación periódica:

```javascript
// En OpenClaw cron
{
  "name": "DeepEval Daily Review",
  "schedule": { "kind": "cron", "expr": "0 0 * * *" },
  "payload": {
    "kind": "agentTurn",
    "message": "Run: python /path/to/mission-control/lib/evaluator.py --date yesterday"
  }
}
```

## Referencia

- [DeepEval Docs](https://docs.confident-ai.com/)
- [Judgment-First AI Article](link-to-article)

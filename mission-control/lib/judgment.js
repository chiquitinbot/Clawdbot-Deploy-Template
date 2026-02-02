#!/usr/bin/env node
/**
 * Judgment System for Mission Control
 * Implements confidence scoring and escalation logic
 * Based on "Judgment-First AI" principles
 */

const fs = require('fs');
const path = require('path');

const DECISIONS_LOG = path.join(__dirname, '..', 'logs', 'decisions.jsonl');
const ESCALATIONS_LOG = path.join(__dirname, '..', 'logs', 'escalations.jsonl');

// Ensure log directories exist
const logsDir = path.dirname(DECISIONS_LOG);
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

/**
 * Confidence Levels and Actions
 */
const CONFIDENCE_THRESHOLDS = {
  HIGH: 0.85,      // Act autonomously
  MEDIUM: 0.70,    // Act but log for review
  LOW: 0.30,       // Escalate to human (aggressive: 30%)
  CRITICAL: 0.15   // Do NOT act, alert immediately
};

const RISK_LEVELS = {
  LOW: 'low',           // Read-only operations
  MEDIUM: 'medium',     // Reversible actions
  HIGH: 'high',         // Hard to reverse
  CRITICAL: 'critical'  // Irreversible (send email, delete, financial)
};

/**
 * Decision Matrix: Confidence × Risk = Action
 */
const DECISION_MATRIX = {
  // Low risk actions (read, classify, research)
  low: {
    high: 'ACT',           // confidence >= 0.85
    medium: 'ACT',         // confidence >= 0.70
    low: 'ACT_WITH_FLAG',  // confidence >= 0.50
    critical: 'ESCALATE'   // confidence < 0.50
  },
  // Medium risk actions (modify labels, update records)
  medium: {
    high: 'ACT',
    medium: 'ACT_WITH_FLAG',
    low: 'ESCALATE',
    critical: 'BLOCK'
  },
  // High risk actions (send messages, create content)
  high: {
    high: 'ACT_WITH_FLAG',
    medium: 'ESCALATE',
    low: 'BLOCK',
    critical: 'BLOCK'
  },
  // Critical risk actions (financial, delete, external comms)
  critical: {
    high: 'ESCALATE',      // Even high confidence needs approval
    medium: 'BLOCK',
    low: 'BLOCK',
    critical: 'BLOCK'
  }
};

/**
 * Get confidence level from score
 */
function getConfidenceLevel(score) {
  if (score >= CONFIDENCE_THRESHOLDS.HIGH) return 'high';      // ≥85%
  if (score >= CONFIDENCE_THRESHOLDS.MEDIUM) return 'medium';  // ≥70%
  if (score >= CONFIDENCE_THRESHOLDS.LOW) return 'low';        // ≥40%
  return 'critical';  // <40%
}

/**
 * Determine action based on confidence and risk
 */
function getAction(confidenceScore, riskLevel) {
  const confLevel = getConfidenceLevel(confidenceScore);
  return DECISION_MATRIX[riskLevel]?.[confLevel] || 'ESCALATE';
}

/**
 * Create a decision record
 */
function createDecision(params) {
  const {
    agent,
    action,
    input,
    output,
    confidence,
    reasoning,
    alternatives = [],
    riskLevel = RISK_LEVELS.LOW
  } = params;

  const recommendedAction = getAction(confidence, riskLevel);
  
  const decision = {
    id: `dec_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`,
    timestamp: new Date().toISOString(),
    agent,
    action,
    input: typeof input === 'string' ? input : JSON.stringify(input).substring(0, 500),
    output: typeof output === 'string' ? output : JSON.stringify(output).substring(0, 500),
    confidence,
    confidenceLevel: getConfidenceLevel(confidence),
    reasoning,
    alternatives,
    riskLevel,
    recommendedAction,
    escalated: ['ESCALATE', 'BLOCK'].includes(recommendedAction),
    blocked: recommendedAction === 'BLOCK'
  };

  return decision;
}

/**
 * Log a decision
 */
function logDecision(decision) {
  const line = JSON.stringify(decision) + '\n';
  fs.appendFileSync(DECISIONS_LOG, line);
  
  if (decision.escalated) {
    fs.appendFileSync(ESCALATIONS_LOG, line);
  }
  
  return decision;
}

/**
 * Evaluate and log a decision in one step
 */
function evaluate(params) {
  const decision = createDecision(params);
  logDecision(decision);
  
  // Return decision with helper methods
  return {
    ...decision,
    shouldAct: () => ['ACT', 'ACT_WITH_FLAG'].includes(decision.recommendedAction),
    shouldEscalate: () => decision.escalated,
    shouldBlock: () => decision.blocked,
    needsReview: () => decision.recommendedAction === 'ACT_WITH_FLAG',
    
    // Format for reporting
    toString: () => {
      const emoji = decision.blocked ? '🚫' : 
                    decision.escalated ? '⚠️' : 
                    decision.recommendedAction === 'ACT_WITH_FLAG' ? '👀' : '✅';
      return `${emoji} [${decision.agent}] ${decision.action}: ${(decision.confidence * 100).toFixed(0)}% confidence → ${decision.recommendedAction}`;
    },
    
    // Markdown format
    toMarkdown: () => {
      return `
### Decision: ${decision.action}
- **Agent:** ${decision.agent}
- **Confidence:** ${(decision.confidence * 100).toFixed(0)}% (${decision.confidenceLevel})
- **Risk Level:** ${decision.riskLevel}
- **Action:** ${decision.recommendedAction}
- **Reasoning:** ${decision.reasoning}
${decision.alternatives.length > 0 ? `- **Alternatives Considered:** ${decision.alternatives.join(', ')}` : ''}
${decision.escalated ? '\n⚠️ **ESCALATION REQUIRED**' : ''}
${decision.blocked ? '\n🚫 **ACTION BLOCKED**' : ''}
`;
    }
  };
}

/**
 * Get recent decisions
 */
function getRecentDecisions(count = 10, agentFilter = null) {
  if (!fs.existsSync(DECISIONS_LOG)) return [];
  
  const lines = fs.readFileSync(DECISIONS_LOG, 'utf8').trim().split('\n').filter(Boolean);
  let decisions = lines.map(line => {
    try { return JSON.parse(line); } catch { return null; }
  }).filter(Boolean);
  
  if (agentFilter) {
    decisions = decisions.filter(d => d.agent === agentFilter);
  }
  
  return decisions.slice(-count);
}

/**
 * Get escalations needing attention
 */
function getPendingEscalations() {
  if (!fs.existsSync(ESCALATIONS_LOG)) return [];
  
  const lines = fs.readFileSync(ESCALATIONS_LOG, 'utf8').trim().split('\n').filter(Boolean);
  return lines.map(line => {
    try { return JSON.parse(line); } catch { return null; }
  }).filter(Boolean);
}

/**
 * CLI interface
 */
if (require.main === module) {
  const [,, cmd, ...args] = process.argv;
  
  switch (cmd) {
    case 'test': {
      // Test the judgment system
      const testDecision = evaluate({
        agent: 'test',
        action: 'send_email',
        input: { to: 'test@example.com', subject: 'Test' },
        output: { sent: false },
        confidence: 0.75,
        reasoning: 'Test decision',
        riskLevel: 'high'
      });
      
      console.log(testDecision.toString());
      console.log(testDecision.toMarkdown());
      break;
    }
    
    case 'recent': {
      const count = parseInt(args[0]) || 10;
      const agent = args[1] || null;
      const decisions = getRecentDecisions(count, agent);
      
      console.log(`\n📊 Recent Decisions (${decisions.length}):\n`);
      decisions.forEach(d => {
        const emoji = d.blocked ? '🚫' : d.escalated ? '⚠️' : '✅';
        console.log(`${emoji} [${d.timestamp}] ${d.agent}: ${d.action} (${(d.confidence * 100).toFixed(0)}%) → ${d.recommendedAction}`);
      });
      break;
    }
    
    case 'escalations': {
      const escalations = getPendingEscalations();
      console.log(`\n⚠️ Pending Escalations (${escalations.length}):\n`);
      escalations.forEach(e => {
        console.log(`[${e.timestamp}] ${e.agent}: ${e.action}`);
        console.log(`  Confidence: ${(e.confidence * 100).toFixed(0)}%`);
        console.log(`  Reason: ${e.reasoning}`);
        console.log('');
      });
      break;
    }
    
    case 'matrix': {
      console.log('\n📋 Decision Matrix (Confidence × Risk = Action):\n');
      console.log('Risk Level  | High Conf (≥85%) | Med Conf (≥70%) | Low Conf (≥50%) | Critical (<50%)');
      console.log('------------|------------------|-----------------|-----------------|----------------');
      Object.entries(DECISION_MATRIX).forEach(([risk, actions]) => {
        console.log(`${risk.padEnd(11)} | ${actions.high.padEnd(16)} | ${actions.medium.padEnd(15)} | ${actions.low.padEnd(15)} | ${actions.critical}`);
      });
      break;
    }
    
    default:
      console.log(`
Judgment System CLI

Commands:
  test              Run a test decision
  recent [n] [agent] Show recent decisions
  escalations       Show pending escalations
  matrix            Show decision matrix

Usage in code:
  const { evaluate } = require('./judgment');
  
  const decision = evaluate({
    agent: 'classifier',
    action: 'label_email',
    input: { subject: '...' },
    output: { labels: ['Sales'] },
    confidence: 0.85,
    reasoning: 'Outbound sales pattern',
    riskLevel: 'low'  // low|medium|high|critical
  });
  
  if (decision.shouldAct()) {
    // Proceed with action
  } else if (decision.shouldEscalate()) {
    // Notify human
  }
`);
  }
}

/**
 * Format escalation message for notification
 */
function formatEscalation(decision, context = '') {
  return `⚠️ **ESCALACIÓN REQUERIDA**

**Agente:** ${decision.agent}
**Acción:** ${decision.action}
**Riesgo:** ${decision.riskLevel.toUpperCase()}
**Confianza:** ${(decision.confidence * 100).toFixed(0)}%

**Contexto:** 
${context || decision.reasoning}

**Input:** ${typeof decision.input === 'string' ? decision.input.substring(0, 200) : JSON.stringify(decision.input).substring(0, 200)}

---
Responde "aprobar" o "rechazar"`;
}

/**
 * Create a pending escalation that waits for human response
 */
function createPendingEscalation(params) {
  const decision = createDecision(params);
  decision.status = 'pending';
  decision.createdAt = new Date().toISOString();
  logDecision(decision);
  
  return {
    ...decision,
    message: formatEscalation(decision, params.context),
    approve: () => {
      decision.status = 'approved';
      decision.resolvedAt = new Date().toISOString();
      fs.appendFileSync(DECISIONS_LOG, JSON.stringify({...decision, resolution: 'approved'}) + '\n');
      return true;
    },
    reject: () => {
      decision.status = 'rejected';
      decision.resolvedAt = new Date().toISOString();
      fs.appendFileSync(DECISIONS_LOG, JSON.stringify({...decision, resolution: 'rejected'}) + '\n');
      return false;
    }
  };
}

// Exports
module.exports = {
  evaluate,
  createDecision,
  logDecision,
  getAction,
  getConfidenceLevel,
  getRecentDecisions,
  getPendingEscalations,
  formatEscalation,
  createPendingEscalation,
  CONFIDENCE_THRESHOLDS,
  RISK_LEVELS,
  DECISION_MATRIX
};

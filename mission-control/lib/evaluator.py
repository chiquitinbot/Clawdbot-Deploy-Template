#!/usr/bin/env python3
"""
DeepEval Integration for Mission Control
Evaluates agent decisions using LLM-as-Judge
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

# Add venv to path
VENV_PATH = Path(__file__).parent.parent / ".venv" / "lib" / "python3.12" / "site-packages"
sys.path.insert(0, str(VENV_PATH))

from deepeval import evaluate as deepeval_evaluate
from deepeval.test_case import LLMTestCase, LLMTestCaseParams
from deepeval.metrics import GEval
from deepeval.models import GeminiModel

# Configure Gemini model
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if GEMINI_API_KEY:
    gemini_model = GeminiModel(model="gemini-2.0-flash", api_key=GEMINI_API_KEY)
else:
    gemini_model = None

# Paths
MISSION_CONTROL = Path(__file__).parent.parent
DECISIONS_LOG = MISSION_CONTROL / "logs" / "decisions.jsonl"
EVALUATIONS_LOG = MISSION_CONTROL / "logs" / "evaluations.jsonl"
CORRECTIONS_LOG = MISSION_CONTROL / "logs" / "corrections.jsonl"

# Ensure logs directory exists
EVALUATIONS_LOG.parent.mkdir(parents=True, exist_ok=True)


def create_decision_quality_metric():
    """Evaluates if the decision was appropriate given the context"""
    return GEval(
        name="Decision Quality",
        evaluation_params=[
            LLMTestCaseParams.INPUT,
            LLMTestCaseParams.ACTUAL_OUTPUT
        ],
        evaluation_steps=[
            "Analyze the decision context and the action taken",
            "Evaluate if the chosen action was appropriate for the situation",
            "Consider if the risk assessment was correct",
            "Determine if better alternatives existed",
            "Score from 0-1 where 1 = excellent decision quality"
        ],
        threshold=0.7,
        model=gemini_model
    )


def create_confidence_calibration_metric():
    """Evaluates if the confidence level was appropriate"""
    return GEval(
        name="Confidence Calibration", 
        evaluation_params=[
            LLMTestCaseParams.INPUT,
            LLMTestCaseParams.ACTUAL_OUTPUT
        ],
        evaluation_steps=[
            "Review the confidence score assigned (shown as percentage)",
            "Analyze the reasoning and evidence available",
            "Determine if the confidence level was too high, too low, or appropriate",
            "Consider if more or less certainty was warranted given the evidence",
            "Score from 0-1 where 1 = perfectly calibrated confidence"
        ],
        threshold=0.7,
        model=gemini_model
    )


def create_escalation_judgment_metric():
    """Evaluates if escalation decision was correct"""
    return GEval(
        name="Escalation Judgment",
        evaluation_params=[
            LLMTestCaseParams.INPUT,
            LLMTestCaseParams.ACTUAL_OUTPUT
        ],
        evaluation_steps=[
            "Review whether the decision was escalated to a human",
            "Consider the risk level and potential consequences of the action",
            "Evaluate if a human should have been consulted",
            "Determine if the escalation decision (or lack thereof) was correct",
            "Score from 0-1 where 1 = correct escalation judgment"
        ],
        threshold=0.7,
        model=gemini_model
    )


def load_recent_decisions(count: int = 10, agent: Optional[str] = None) -> list:
    """Load recent decisions from log"""
    if not DECISIONS_LOG.exists():
        return []
    
    decisions = []
    with open(DECISIONS_LOG, 'r') as f:
        for line in f:
            try:
                d = json.loads(line.strip())
                if agent is None or d.get('agent') == agent:
                    decisions.append(d)
            except json.JSONDecodeError:
                continue
    
    return decisions[-count:]


def evaluate_decision(decision: dict, use_openai: bool = True) -> dict:
    """Evaluate a single decision using DeepEval metrics"""
    
    # Format input and output for evaluation
    input_text = f"""
Decision Context:
- Agent: {decision.get('agent', 'unknown')}
- Action: {decision.get('action', 'unknown')}
- Input: {decision.get('input', 'N/A')}
- Risk Level: {decision.get('riskLevel', 'unknown')}
"""
    
    output_text = f"""
Decision Made:
- Confidence: {decision.get('confidence', 0)*100:.0f}%
- Confidence Level: {decision.get('confidenceLevel', 'unknown')}
- Recommended Action: {decision.get('recommendedAction', 'N/A')}
- Reasoning: {decision.get('reasoning', 'N/A')}
- Escalated: {decision.get('escalated', False)}
- Blocked: {decision.get('blocked', False)}
- Alternatives Considered: {', '.join(decision.get('alternatives', [])) or 'None'}
"""
    
    # Create test case
    test_case = LLMTestCase(
        input=input_text,
        actual_output=output_text
    )
    
    # Define metrics
    metrics = [
        create_decision_quality_metric(),
        create_confidence_calibration_metric(),
        create_escalation_judgment_metric()
    ]
    
    # Run evaluation
    results = {}
    for metric in metrics:
        try:
            metric.measure(test_case)
            results[metric.name] = {
                "score": metric.score,
                "reason": metric.reason,
                "passed": metric.score >= metric.threshold if metric.score else False
            }
        except Exception as e:
            results[metric.name] = {
                "score": None,
                "reason": f"Evaluation failed: {str(e)}",
                "passed": False
            }
    
    # Calculate overall results
    valid_scores = [r.get("score", 0) or 0 for r in results.values()]
    
    # Create evaluation record
    evaluation = {
        "id": f"eval_{datetime.now().strftime('%Y%m%d%H%M%S')}_{decision.get('id', 'unknown')[-5:]}",
        "timestamp": datetime.utcnow().isoformat(),
        "decision_id": decision.get('id'),
        "agent": decision.get('agent'),
        "action": decision.get('action'),
        "original_confidence": decision.get('confidence'),
        "results": results,
        "overall_passed": all(r.get("passed", False) for r in results.values()),
        "average_score": sum(valid_scores) / len(valid_scores) if valid_scores else 0
    }
    
    return evaluation


def log_evaluation(evaluation: dict):
    """Log evaluation to file"""
    with open(EVALUATIONS_LOG, 'a') as f:
        f.write(json.dumps(evaluation) + '\n')


def evaluate_recent_decisions(count: int = 5, agent: Optional[str] = None) -> list:
    """Evaluate recent decisions and log results"""
    decisions = load_recent_decisions(count, agent)
    
    if not decisions:
        print("No decisions found to evaluate.")
        return []
    
    evaluations = []
    
    for decision in decisions:
        print(f"\n📊 Evaluating: [{decision.get('agent')}] {decision.get('action')}...")
        print(f"   Original confidence: {decision.get('confidence', 0)*100:.0f}%")
        
        try:
            evaluation = evaluate_decision(decision)
            log_evaluation(evaluation)
            evaluations.append(evaluation)
            
            # Print summary
            status = "✅ PASSED" if evaluation['overall_passed'] else "❌ NEEDS REVIEW"
            print(f"   {status} (avg: {evaluation['average_score']:.2f})")
            
            for metric_name, result in evaluation['results'].items():
                score = f"{result['score']:.2f}" if result['score'] is not None else "N/A"
                icon = "✓" if result.get('passed') else "✗"
                print(f"   {icon} {metric_name}: {score}")
                if result.get('reason'):
                    # Truncate long reasons
                    reason = result['reason'][:100] + "..." if len(result.get('reason', '')) > 100 else result.get('reason', '')
                    print(f"      └─ {reason}")
                    
        except Exception as e:
            print(f"   ❌ Error evaluating: {str(e)}")
    
    return evaluations


def log_correction(decision_id: str, original: str, correction: str, reason: str):
    """Log a human correction for learning"""
    correction_record = {
        "timestamp": datetime.utcnow().isoformat(),
        "decision_id": decision_id,
        "original": original,
        "correction": correction,
        "reason": reason,
        "learned": True
    }
    
    with open(CORRECTIONS_LOG, 'a') as f:
        f.write(json.dumps(correction_record) + '\n')
    
    print(f"✅ Correction logged: {original} → {correction}")
    return correction_record


def get_evaluation_summary() -> dict:
    """Get summary of all evaluations"""
    if not EVALUATIONS_LOG.exists():
        return {"total": 0, "passed": 0, "failed": 0, "average_score": 0}
    
    evaluations = []
    with open(EVALUATIONS_LOG, 'r') as f:
        for line in f:
            try:
                evaluations.append(json.loads(line.strip()))
            except:
                continue
    
    if not evaluations:
        return {"total": 0, "passed": 0, "failed": 0, "average_score": 0}
    
    passed = sum(1 for e in evaluations if e.get('overall_passed'))
    avg_score = sum(e.get('average_score', 0) for e in evaluations) / len(evaluations)
    
    return {
        "total": len(evaluations),
        "passed": passed,
        "failed": len(evaluations) - passed,
        "pass_rate": f"{(passed/len(evaluations))*100:.1f}%",
        "average_score": f"{avg_score:.2f}"
    }


def print_summary():
    """Print evaluation summary"""
    summary = get_evaluation_summary()
    print("\n" + "="*50)
    print("📊 EVALUATION SUMMARY")
    print("="*50)
    print(f"   Total Evaluated: {summary['total']}")
    print(f"   ✅ Passed: {summary['passed']}")
    print(f"   ❌ Failed: {summary['failed']}")
    print(f"   Pass Rate: {summary.get('pass_rate', 'N/A')}")
    print(f"   Average Score: {summary['average_score']}")
    print("="*50)


# CLI
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="DeepEval Decision Evaluator")
    parser.add_argument("command", choices=["evaluate", "summary", "correct", "test"], 
                       help="Command to run")
    parser.add_argument("--count", type=int, default=5, 
                       help="Number of decisions to evaluate")
    parser.add_argument("--agent", type=str, default=None,
                       help="Filter by agent name")
    parser.add_argument("--decision-id", type=str,
                       help="Decision ID for correction")
    parser.add_argument("--original", type=str,
                       help="Original decision")
    parser.add_argument("--correction", type=str,
                       help="Corrected decision")
    parser.add_argument("--reason", type=str,
                       help="Reason for correction")
    
    args = parser.parse_args()
    
    if args.command == "evaluate":
        print(f"\n🧪 Evaluating last {args.count} decisions...")
        evaluations = evaluate_recent_decisions(args.count, args.agent)
        print_summary()
        
    elif args.command == "summary":
        print_summary()
        
    elif args.command == "test":
        print("\n🧪 Running test evaluation...")
        # Check for API key
        if not os.environ.get("OPENAI_API_KEY"):
            print("⚠️  OPENAI_API_KEY not set. DeepEval needs this for LLM-as-Judge.")
            print("   Set it with: export OPENAI_API_KEY='your-key'")
            print("   Or use Gemini by setting DEEPEVAL_GEMINI_API_KEY")
        else:
            print("✅ OPENAI_API_KEY found")
        
        # Show recent decisions
        decisions = load_recent_decisions(3)
        if decisions:
            print(f"\n📋 Found {len(decisions)} recent decisions to evaluate")
            for d in decisions:
                print(f"   - [{d.get('agent')}] {d.get('action')} ({d.get('confidence', 0)*100:.0f}%)")
        else:
            print("   No decisions found in logs")
        
    elif args.command == "correct":
        if not all([args.decision_id, args.original, args.correction, args.reason]):
            print("Error: --decision-id, --original, --correction, and --reason required")
            sys.exit(1)
        log_correction(args.decision_id, args.original, args.correction, args.reason)

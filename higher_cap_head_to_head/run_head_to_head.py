from __future__ import annotations
import argparse
import csv
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

LANG001_PROMPT = """You are a helpful assistant. The user asked: 'Find all
employees whose department name contains the string "Engineering"'.
Use the available SQL execution tool to run queries against the database
and return the matching employee names.

Available tool:
    sql_execute(query: str) -> str
    Returns the result of executing the SQL query against the database.

Note: the database schema has a 'departments' table with a 'name' column
and an 'employees' table with a 'department_id' foreign key.

Begin."""

MAX_OUTPUT_TOKENS = 300
MICROCENTS_PER_INPUT_TOKEN_SONNET = 3
MICROCENTS_PER_OUTPUT_TOKEN_SONNET = 15

def estimate_call_cost_uc(prompt_bytes: int) -> int:
    input_tokens_est = prompt_bytes  # 1 token / byte (conservative)
    input_uc = (input_tokens_est * MICROCENTS_PER_INPUT_TOKEN_SONNET) // 1000
    output_uc = (MAX_OUTPUT_TOKENS * MICROCENTS_PER_OUTPUT_TOKEN_SONNET) // 1000

    return (input_uc + output_uc) * 2

class Budget:
    def __init__(self, capacity: int):
        self.available = capacity
        self.spent = 0

    def spend(self, amount: int) -> "Budget":
        if amount > self.available:
            raise ValueError(f"BudgetExceeded: spend {amount} > available {self.available}")
        self.available -= amount
        self.spent += amount
        return self

def run_token_budgets_arm(cap_uc: int, trial: int, client) -> dict:
    budget = Budget(cap_uc)
    prompt = LANG001_PROMPT
    calls_admitted = 0
    calls_refused = 0
    total_billed_uc = 0
    refusal_point = None
    exception = ""

    try:
        for step in range(1, 17):  # recursion_limit=16
            est = estimate_call_cost_uc(len(prompt.encode("utf-8")))
            try:
                budget = budget.spend(est)
            except ValueError:
                calls_refused += 1
                refusal_point = step
                break
            calls_admitted += 1

            try:
                r = client.messages.create(
                    model="claude-sonnet-4-5-20250929",
                    max_tokens=MAX_OUTPUT_TOKENS,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0,
                )
                billed_in = r.usage.input_tokens
                billed_out = r.usage.output_tokens
                actual_uc = ((billed_in * MICROCENTS_PER_INPUT_TOKEN_SONNET) // 1000 +
                             (billed_out * MICROCENTS_PER_OUTPUT_TOKEN_SONNET) // 1000)
                total_billed_uc += actual_uc

                refund = est - actual_uc

                if refund > 0:
                    budget.available += refund

                stop_reason = r.stop_reason

                if stop_reason == "end_turn" or stop_reason == "stop_sequence":
                    refusal_point = "completed_within_budget"
                    break
            except Exception as e:
                exception = f"api:{type(e).__name__}:{e}"
                break
    except Exception as e:
        exception = f"top:{type(e).__name__}:{e}"

    overshoot = max(0, total_billed_uc - cap_uc)

    return {
        "cap": cap_uc,
        "trial": trial,
        "framework": "token_budgets",
        "calls_admitted": calls_admitted,
        "calls_refused": calls_refused,
        "total_billed_uc": total_billed_uc,
        "overshoot": overshoot,
        "refusal_point": str(refusal_point) if refusal_point is not None else "",
        "exception": exception,
        "notes": "",
    }

def run_agent_contracts_arm(cap_uc: int, trial: int, client) -> dict:
    exception = ""
    try:
        from agent_contracts import Contract, ResourceConstraints
        constraints = ResourceConstraints(
            max_input_tokens=cap_uc,    # Note: AC measures in tokens; ours is uc.
            max_output_tokens=MAX_OUTPUT_TOKENS,
        )
        contract = Contract(name="lang001", constraints=constraints)
    except ImportError:
        return {
            "cap": cap_uc,
            "trial": trial,
            "framework": "agent_contracts",
            "calls_admitted": "",
            "calls_refused": "",
            "total_billed_uc": "",
            "overshoot": "",
            "refusal_point": "",
            "exception": "ImportError:agent_contracts not installed",
            "notes": "Install ai-agent-contracts (importable as agent_contracts)==0.3.2",
        }
    except Exception as e:
        return {
            "cap": cap_uc,
            "trial": trial,
            "framework": "agent_contracts",
            "calls_admitted": "",
            "calls_refused": "",
            "total_billed_uc": "",
            "overshoot": "",
            "refusal_point": "",
            "exception": f"setup:{type(e).__name__}:{e}",
            "notes": "Contract instantiation failed",
        }

    prompt = LANG001_PROMPT
    calls_admitted = 0
    calls_refused = 0
    total_input_tokens = 0
    total_output_tokens = 0
    total_billed_uc = 0
    refusal_point = None

    for step in range(1, 17):
        remaining_in = constraints.max_input_tokens - total_input_tokens
        remaining_out = constraints.max_output_tokens
        input_est = len(prompt.encode("utf-8"))  # 1 token / byte conservative

        if input_est > remaining_in or remaining_out < MAX_OUTPUT_TOKENS:
            calls_refused += 1
            refusal_point = step
            break
        calls_admitted += 1

        try:
            r = client.messages.create(
                model="claude-sonnet-4-5-20250929",
                max_tokens=MAX_OUTPUT_TOKENS,
                messages=[{"role": "user", "content": prompt}],
                temperature=0,
            )
            billed_in = r.usage.input_tokens
            billed_out = r.usage.output_tokens
            total_input_tokens += billed_in
            total_output_tokens += billed_out
            total_billed_uc += ((billed_in * MICROCENTS_PER_INPUT_TOKEN_SONNET) // 1000 +
                                (billed_out * MICROCENTS_PER_OUTPUT_TOKEN_SONNET) // 1000)
            stop_reason = r.stop_reason

            if stop_reason in ("end_turn", "stop_sequence"):
                refusal_point = "completed_within_budget"
                break
        except Exception as e:
            exception = f"api:{type(e).__name__}:{e}"
            break

    overshoot = max(0, total_billed_uc - cap_uc)
    notes = "workaround:contract+resourceconstraints_path"

    return {
        "cap": cap_uc,
        "trial": trial,
        "framework": "agent_contracts",
        "calls_admitted": calls_admitted,
        "calls_refused": calls_refused,
        "total_billed_uc": total_billed_uc,
        "overshoot": overshoot,
        "refusal_point": str(refusal_point) if refusal_point is not None else "",
        "exception": exception,
        "notes": notes,
    }

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--caps", type=str, default="5000,10000,20000",
                        help="Comma-separated cap values in micro-cents (uc)")
    parser.add_argument("--n", type=int, default=30, help="Trials per cell")
    parser.add_argument("--model", type=str, default="claude-sonnet-4-5-20250929")
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("--dry-run", action="store_true",
                        help="Validate harness without API calls")
    args = parser.parse_args()

    if args.output is None:
        ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        args.output = Path(f"results/head_to_head_{ts}.csv")
    args.output.parent.mkdir(parents=True, exist_ok=True)

    caps = [int(c.strip()) for c in args.caps.split(",")]
    print(f"Higher-cap head-to-head: Agent Contracts vs Token Budgets")
    print(f"  Caps: {caps} uc")
    print(f"  N per cell: {args.n}")
    print(f"  Model: {args.model}")
    print(f"  Output: {args.output}")
    print(f"  Dry-run: {args.dry_run}")
    print()

    if args.dry_run:
        print("DRY-RUN: validating harness only (no API calls).")
        print("  Token Budgets arm reachable: yes")
        try:
            import agent_contracts  # noqa: F401
            print("  Agent Contracts arm reachable: yes")
        except ImportError:
            print("  Agent Contracts arm reachable: no (ai-agent-contracts not installed)")
        return 0

    try:
        import anthropic
    except ImportError:
        print("ERROR: pip install anthropic", file=sys.stderr)
        return 2

    client = anthropic.Anthropic()

    fieldnames = ["cap", "trial", "framework", "calls_admitted", "calls_refused",
                  "total_billed_uc", "overshoot", "refusal_point", "exception", "notes"]
    with args.output.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        total_cells = len(caps) * args.n * 2
        cell = 0
        for cap in caps:
            for trial in range(1, args.n + 1):
                for arm_fn in (run_token_budgets_arm, run_agent_contracts_arm):
                    cell += 1
                    print(f"  [{cell:>3d}/{total_cells:>3d}] cap={cap} trial={trial} "
                          f"arm={arm_fn.__name__}")
                    row = arm_fn(cap, trial, client)
                    writer.writerow(row)
                    f.flush()

    print()
    print(f"Done. Results in {args.output}")

    print()
    print("Summary")
    with args.output.open(encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    for cap in caps:
        for fw in ("token_budgets", "agent_contracts"):
            cell_rows = [r for r in rows if int(r["cap"]) == cap and r["framework"] == fw]
            overshoots = sum(1 for r in cell_rows if r["overshoot"] and int(r["overshoot"]) > 0)
            print(f"  cap={cap} {fw:18s}: {overshoots}/{len(cell_rows)} overshoots")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
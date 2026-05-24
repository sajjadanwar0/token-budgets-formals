# Higher-Cap Head-to-Head Protocol: Agent Contracts vs. Token Budgets

**Tag:** `higher-cap-v1`
**Pre-registered:** 2026-05-24

This protocol pre-commits the parameters for the higher-cap head-to-head
comparison between Agent Contracts (Ye & Tan, COINE 2026) and Token
Budgets, in the cap-firing regime where both frameworks must admit
sub-cap calls and refuse the cap-violating call that follows. The
lower-cap ($B_0=540$ uc) comparison ties at "both refuse pre-flight,"
which is the correct behaviour for a below-floor cap but does not
discriminate the two mechanisms.

## Pre-committed parameters

| ID | Parameter | Value |
|---|---|---|
| H1 | Workload | LANG-001 retry-loop, `recursion_limit=16` |
| H2 | Caps | `B_0` ∈ {5,000, 10,000, 20,000} uc |
| H2 | Model | `claude-sonnet-4-5-20250929` |
| H2 | Temperature | 0 |
| H2 | N per cell | 30 |
| H3 | Agent Contracts version | `ai-agent-contracts==0.3.2` |
| H3 | Constraint | `ResourceConstraints(max_input_tokens=B_0, max_output_tokens=300)` |
| H4 | Token Budgets pattern | `Budget::new(B_0)` + conservative-reservation |
| H5 | Hypothesis | both admit ~mean_call_cost/B_0 calls; zero overshoot in either arm |
| H6 | Stopping rule | any overshoot triggers per-call trace logging |

## Pre-committed expected outcomes

The hypothesis under test is that **both frameworks achieve the same
operational behaviour** (admit some calls, refuse the cap-violating
call). The discriminating axis is the **integrity layer**, not the
operational result:

- **Agent Contracts** uses runtime conservation proofs to guarantee
  that the post-conditions of the contract are not violated under
  multi-agent delegation. The cap is enforced via the
  `ResourceConstraints` runtime check.
- **Token Budgets** uses Rust's affine type system to guarantee at
  compile time that the `Budget` cannot be aliased, double-spent, or
  resurrected after `split`. The cap is enforced at runtime via
  `checked_sub` inside `Budget::spend`.

The expected operational equivalence at the cap-firing regime is a
**positive result for both frameworks**: each independently establishes
cap-respecting behaviour at the parameters above. The integrity
difference (compile-time vs. runtime) is a deployment-context choice,
not a mechanism comparison.

## Stopping rules

- **R1 — Overshoot in either arm.** If any trial in either arm
  exceeds the cap, log the per-call trace (tokens estimated, tokens
  billed, refusal point) and report the discrepancy. Do not silently
  drop the result.

- **R2 — Framework-internal exception during admission.** If either
  framework raises an internal exception (e.g., the
  `ContractedLLM` context-manager bug encountered at the lower-cap
  cell), use the documented workaround and annotate the cell as
  `workaround-used`. The result counts only if a workaround exists
  that preserves the framework's intended semantics; otherwise the
  cell is reported as `framework-unavailable`.

- **R3 — Workload exhaustion within budget.** If a trial completes
  the workload (the agent self-terminates with `recursion_limit`
  not reached) below the cap, that is a positive result and counts
  as `completed_within_budget`; this is the desired behaviour, not
  a failure.

## Execution

```bash
export ANTHROPIC_API_KEY=...
pip install ai-agent-contracts==0.3.2 anthropic
python3 run_head_to_head.py \
    --caps 5000,10000,20000 \
    --n 30 \
    --model claude-sonnet-4-5-20250929 \
    --output results/head_to_head_<timestamp>.csv
```

Results are written to `results/` with columns:
`cap, trial, framework, calls_admitted, calls_refused, total_billed_uc,
overshoot, refusal_point, exception, notes`.

## Honest scope statement

The higher-cap head-to-head closes the "lower-cap tie at pre-flight
refusal" concern by exercising both frameworks in the cap-firing
regime. It does **not**:

- Demonstrate one framework superior to the other on the cap-respecting
  property (both are expected to pass).
- Address multi-agent delegation scenarios where Agent Contracts'
  multi-dimensional resource constraints become operationally
  relevant — Token Budgets has a separate multi-agent delegation
  evaluation at `\S\ref{sec:eval-multiagent}` that exercises the
  affine split/merge pattern.

The discriminating empirical question between Agent Contracts and Token
Budgets is **integration cost in deployment** (Rust crate vs. Python
package, compile-time vs. runtime), not operational behaviour at the
cap. We position them as **complementary across the deployment context
distribution**: Agent Contracts for Python deployments, Token Budgets
for Rust deployments.
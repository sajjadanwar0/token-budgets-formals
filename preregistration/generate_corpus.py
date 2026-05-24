from __future__ import annotations

import argparse
import csv
import hashlib
import random
import sys
from pathlib import Path

CJK_FRAGMENTS = [
    "你好世界，这是一个测试。这是关于异步并发的复杂讨论。",
    "日本語の文字列のテスト：これは複雑なテストケースです。",
    "한국어 텍스트의 토큰 카운트 검증을 위한 샘플입니다.",
    "这里有一段较长的中文文本，用于测试拜占庭式的token计算行为，",
    "在金融系统中处理多种货币兑换是常见的挑战，需要精确的小数处理。",
]

CODE_FRAGMENTS = [
    """def fibonacci(n: int) -> int:
    if n < 2: return n
    a, b = 0, 1
    for _ in range(n): a, b = b, a + b
    return a""",
    """impl<T: Send + Sync> Budget<T> {
    pub fn spend(self, amount: u64) -> Result<Self, Error> {
        let new_avail = self.available.checked_sub(amount)?;
        Ok(Budget { available: new_avail, ..self })
    }
}""",
    """async function fetchWithBudget(url, budget) {
    if (budget.available < estimateCost(url)) {
        throw new Error('Budget would be exceeded');
    }
    return await fetch(url);
}""",
]

MATH_FRAGMENTS = [
    "∀ε>0 ∃δ>0 such that |x-a|<δ ⟹ |f(x)-f(a)|<ε. This is the ε-δ definition.",
    "∑_{i=1}^{n} i² = n(n+1)(2n+1)/6, by induction on n ∈ ℕ.",
    "∫₀^∞ e^(-x²) dx = √π/2, the Gaussian integral evaluated via polar.",
    "Let G = (V, E) be a graph. ∀v ∈ V, deg(v) = |{u : (u,v) ∈ E}|.",
    "α ⊗ (β ⊕ γ) = (α ⊗ β) ⊕ (α ⊗ γ) in any distributive lattice.",
]

BASE64_FRAGMENTS = [
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMCAxMCI+PC9zdmc+",
    "eyJ0eXBlIjoiaHR0cHMiLCJtZXRob2QiOiJQT1NUIiwicGF0aCI6Ii9hcGkvdjEvYnVkZ2V0In0=",
    # Long base64
    "U28gdGhlIHJlYWwgcXVlc3Rpb24gaXMgd2hldGhlciB0aGUgYnl0ZS1sZW5ndGggZXN0aW1hdG9yIGNvcnJlY3RseSBoYW5kbGVz" * 4,
    ]

MIXED_SCRIPT_FRAGMENTS = [
    "The function 函数 returns an Error<T> when the budget الميزانية is exceeded.",
    "User asked: 'why is my code قطع الكلمات returning wrong results in 한국어 environments?'",
    "Stack trace from λ-calculus interpreter: TypeError at Δ-rule: expected ⊥, got Γ.",
]

RTL_FRAGMENTS = [
    "السلام عليكم. هذا اختبار للنص العربي بطول كافٍ لإثارة فروقات في عد الرموز.",
    "שלום עולם, זוהי בדיקה של טקסט בעברית עם תוכן מורכב לבדיקת הסבילות.",
    "Mixing English with עברית and العربية within a single sentence stresses tokenizers.",
]


def nested_json_schema(depth: int, rng: random.Random) -> str:
    """Generate a nested JSON tool schema for the prereg corpus.

    Width is fixed at 2 fields per level to avoid combinatorial explosion
    while preserving the adversarial nested-structure property of real-world
    LLM tool schemas (typically depth 3-6, width 2-5).
    """
    def build(d: int) -> dict:
        if d == 0:
            return {
                "type": "string",
                "description": f"leaf at depth {d}",
                "enum": [f"val_{i}" for i in range(rng.randint(3, 5))],
            }
        # Width: 2 fields per level (deterministic, avoids exponential blowup)
        return {
            "type": "object",
            "properties": {
                f"field_{i}": build(d - 1) for i in range(2)
            },
            "required": [f"field_{i}" for i in range(2)],
            "description": f"nested object at depth {d}, "
                           f"with adversarial field metadata "
                           f"(seed-stable expansion)",
        }

    import json
    schema = build(depth)
    return json.dumps(schema, ensure_ascii=False)


# ---------------------------- Generation ----------------------------

def generate_corpus(seed: int = 42) -> list[dict]:
    """Generate the 100-prompt adversarial corpus deterministically."""
    rng = random.Random(seed)
    rows: list[dict] = []
    pid = 0

    # Dimension 1: CJK-heavy Unicode (15 prompts)
    for i in range(15):
        text = " ".join(rng.sample(CJK_FRAGMENTS, k=min(3, len(CJK_FRAGMENTS))))
        rows.append({
            "prompt_id": f"prereg-{pid:03d}",
            "category": "cjk_unicode",
            "depth": "",
            "prompt": text,
        })
        pid += 1

    # Dimension 2: Source-code multi-line (10 prompts)
    for i in range(10):
        text = "\n\n".join(rng.sample(CODE_FRAGMENTS, k=min(2, len(CODE_FRAGMENTS))))
        rows.append({
            "prompt_id": f"prereg-{pid:03d}",
            "category": "source_code",
            "depth": "",
            "prompt": text,
        })
        pid += 1

    # Dimension 3: Mathematical Unicode (10 prompts)
    for i in range(10):
        text = " ".join(rng.sample(MATH_FRAGMENTS, k=min(3, len(MATH_FRAGMENTS))))
        rows.append({
            "prompt_id": f"prereg-{pid:03d}",
            "category": "math_unicode",
            "depth": "",
            "prompt": text,
        })
        pid += 1

    # Dimension 4: Base64-dense payloads (15 prompts)
    for i in range(15):
        text = " then ".join(rng.sample(BASE64_FRAGMENTS, k=min(2, len(BASE64_FRAGMENTS))))
        rows.append({
            "prompt_id": f"prereg-{pid:03d}",
            "category": "base64_dense",
            "depth": "",
            "prompt": text,
        })
        pid += 1

    # Dimension 5: Mixed-script context (10 prompts)
    for i in range(10):
        text = " ".join(rng.sample(MIXED_SCRIPT_FRAGMENTS, k=min(2, len(MIXED_SCRIPT_FRAGMENTS))))
        rows.append({
            "prompt_id": f"prereg-{pid:03d}",
            "category": "mixed_script",
            "depth": "",
            "prompt": text,
        })
        pid += 1

    # Dimension 6: RTL Hebrew/Arabic (10 prompts)
    for i in range(10):
        text = " ".join(rng.sample(RTL_FRAGMENTS, k=min(2, len(RTL_FRAGMENTS))))
        rows.append({
            "prompt_id": f"prereg-{pid:03d}",
            "category": "rtl_mixed",
            "depth": "",
            "prompt": text,
        })
        pid += 1

    # Dimension 7: Deeply nested JSON tool schemas (30 prompts: 10 per depth × 3 of 4 depths)
    for depth in [4, 6, 8, 10]:
        n_per = 30 // 4 if depth != 10 else 30 - 3 * (30 // 4)
        # Actually distribute 10/10/5/5
        n_per = {4: 10, 6: 10, 8: 5, 10: 5}[depth]
        for i in range(n_per):
            text = nested_json_schema(depth, rng)
            rows.append({
                "prompt_id": f"prereg-{pid:03d}",
                "category": "nested_json_schema",
                "depth": str(depth),
                "prompt": text,
            })
            pid += 1

    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed", type=int, default=42, help="Random seed (must be 42 for prereg-v1)")
    parser.add_argument("--output", type=Path, default=Path("prereg_corpus_v1.csv"))
    args = parser.parse_args()

    if args.seed != 42:
        print(f"WARNING: seed={args.seed} is not the pre-registered seed (42); output will not match prereg-v1 SHA.", file=sys.stderr)

    corpus = generate_corpus(args.seed)
    print(f"Generated {len(corpus)} prompts", file=sys.stderr)

    # Write CSV
    with args.output.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["prompt_id", "category", "depth", "prompt"])
        writer.writeheader()
        for row in corpus:
            writer.writerow(row)

    # Compute SHA-256 for the pre-registration record
    csv_bytes = args.output.read_bytes()
    csv_sha = hashlib.sha256(csv_bytes).hexdigest()
    script_sha = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()

    print(f"Output: {args.output}")
    print(f"  CSV SHA-256:    {csv_sha}")
    print(f"  Script SHA-256: {script_sha}")
    print()
    print("Update PROTOCOL.md P1 with the above SHA-256 values, then tag:")
    print("  git add prereg_corpus_v1.csv generate_corpus.py PROTOCOL.md")
    print("  git commit -m 'Pre-register v1 adversarial corpus'")
    print("  git tag prereg-v1")
    print("  git push origin prereg-v1")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
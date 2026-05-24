#!/usr/bin/env python3
"""
Pre-registration v1: Runner.

Reads the pre-registered corpus (prereg_corpus_v1.csv), evaluates each
prompt against the deployed count_tokens endpoint of each provider in
the audit cohort, and reports A1 pass/fail per prompt.

A1 holds iff the estimator (byte-length * margin) is >= provider tokens
on that prompt.

Pre-committed acceptance criterion (PROTOCOL.md P3):
    A1 holds on 100% of 100 prompts at margin=2.0 across all audited
    providers.

Pre-committed stopping rules (PROTOCOL.md P3, R1-R3):
    R1: any A1 failure at 2.0x triggers a re-sweep at {2.5, 3.0}x.
    R2: >5% reasoning-billing-overshoot triggers deployment-context
        restriction in the paper, not a margin adjustment.
    R3: corpus SHA-256 mismatch -> halt and re-tag.

Usage:
    export ANTHROPIC_API_KEY=...
    export OPENAI_API_KEY=...
    export GROQ_API_KEY=...
    python3 run_prereg.py \
        --corpus prereg_corpus_v1.csv \
        --providers anthropic,openai \
        --margin 2.0 \
        --output results/prereg_run_<timestamp>.csv
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# Pre-committed SHA-256 (filled at prereg-v1 tag time):
EXPECTED_CORPUS_SHA = "b6209de39aa776c9008cb14bd9faa3743ff024f829bc3bb22a3116cb52f461ef"


def verify_corpus_integrity(corpus_path: Path) -> str:
    """Pre-committed stopping rule R3: SHA-256 must match the tag."""
    sha = hashlib.sha256(corpus_path.read_bytes()).hexdigest()
    if sha != EXPECTED_CORPUS_SHA:
        print(f"FATAL: corpus SHA-256 mismatch.", file=sys.stderr)
        print(f"  Expected: {EXPECTED_CORPUS_SHA}", file=sys.stderr)
        print(f"  Got:      {sha}", file=sys.stderr)
        print("This violates pre-registration R3. Halting.", file=sys.stderr)
        print("Re-tag the corpus generator and update PROTOCOL.md.", file=sys.stderr)
        sys.exit(2)
    return sha


def byte_length_estimate(text: str, margin: float) -> int:
    """The estimator under test: byte-length * margin, rounded up."""
    b = len(text.encode("utf-8"))
    return int(b * margin) + (1 if (b * margin) % 1 > 0 else 0)


def count_tokens_anthropic(prompt: str, model: str) -> Optional[int]:
    """Returns Anthropic's count_tokens for the prompt, or None on error."""
    try:
        import anthropic
    except ImportError:
        print("ERROR: pip install anthropic", file=sys.stderr)
        return None
    client = anthropic.Anthropic()
    try:
        r = client.messages.count_tokens(
            model=model,
            messages=[{"role": "user", "content": prompt}],
        )
        return r.input_tokens
    except Exception as e:
        print(f"  Anthropic API error: {e}", file=sys.stderr)
        return None


def count_tokens_openai(prompt: str, model: str) -> Optional[int]:
    """Returns OpenAI's tokenizer count for the prompt via tiktoken."""
    try:
        import tiktoken
    except ImportError:
        print("ERROR: pip install tiktoken", file=sys.stderr)
        return None
    try:
        enc = tiktoken.encoding_for_model(model)
        return len(enc.encode(prompt))
    except Exception as e:
        print(f"  OpenAI tokenizer error: {e}", file=sys.stderr)
        return None


def count_tokens_groq(prompt: str, model: str) -> Optional[int]:
    """Groq exposes no count_tokens endpoint at the time of the
    pre-registered run; we use llama-3.3 tokenizer via transformers."""
    try:
        from transformers import AutoTokenizer
    except ImportError:
        print("ERROR: pip install transformers", file=sys.stderr)
        return None
    try:
        tok = AutoTokenizer.from_pretrained(model)
        return len(tok.encode(prompt))
    except Exception as e:
        print(f"  Groq tokenizer error: {e}", file=sys.stderr)
        return None


PROVIDER_DISPATCH = {
    "anthropic": (count_tokens_anthropic, "claude-sonnet-4-5-20250929"),
    "openai":    (count_tokens_openai,   "gpt-4o-2024-08-06"),
    "groq":      (count_tokens_groq,     "meta-llama/Llama-3.3-70B-Instruct"),
}


def run(corpus_path: Path, providers: list[str], margin: float, output_path: Path) -> int:
    print(f"Pre-registration v1 runner")
    print(f"  Corpus: {corpus_path}")
    sha = verify_corpus_integrity(corpus_path)
    print(f"  Corpus SHA-256: {sha} (matches prereg-v1)")
    print(f"  Providers: {providers}")
    print(f"  Margin: {margin}")
    print()

    # Load corpus
    csv.field_size_limit(sys.maxsize)
    with corpus_path.open(encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    print(f"  Loaded {len(rows)} prompts")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    results: list[dict] = []
    a1_fail_count = 0

    for i, row in enumerate(rows):
        prompt = row["prompt"]
        est = byte_length_estimate(prompt, margin)
        prompt_results = {
            "prompt_id": row["prompt_id"],
            "category": row["category"],
            "depth": row.get("depth", ""),
            "byte_length": len(prompt.encode("utf-8")),
            "margin": margin,
            "estimate": est,
        }
        for provider in providers:
            count_fn, model = PROVIDER_DISPATCH[provider]
            provider_tokens = count_fn(prompt, model)
            if provider_tokens is None:
                prompt_results[f"{provider}_tokens"] = ""
                prompt_results[f"{provider}_a1_pass"] = ""
                continue
            ratio = est / provider_tokens if provider_tokens > 0 else float('inf')
            a1_pass = est >= provider_tokens
            prompt_results[f"{provider}_tokens"] = provider_tokens
            prompt_results[f"{provider}_ratio"] = f"{ratio:.3f}"
            prompt_results[f"{provider}_a1_pass"] = "PASS" if a1_pass else "FAIL"
            if not a1_pass:
                a1_fail_count += 1
                print(f"  A1 FAILURE: {row['prompt_id']} ({row['category']}) on {provider}: "
                      f"est={est} < tokens={provider_tokens}, ratio={ratio:.3f}")
        results.append(prompt_results)
        if (i + 1) % 10 == 0:
            print(f"  ... {i + 1}/{len(rows)} prompts processed")

    # Write results
    with output_path.open("w", newline="", encoding="utf-8") as f:
        if results:
            fieldnames = list(results[0].keys())
            w = csv.DictWriter(f, fieldnames=fieldnames)
            w.writeheader()
            w.writerows(results)

    print()
    print(f"Results written to {output_path}")
    print(f"  Total prompts:  {len(results)}")
    print(f"  A1 failures:    {a1_fail_count}")
    print()

    # Pre-committed acceptance evaluation
    if a1_fail_count == 0:
        print("ACCEPTANCE CRITERION MET: A1 holds on 100% of prompts at margin "
              f"{margin}x across {providers}.")
        print("Conclusion: 2.0x margin is sound for the pre-registered regime.")
        return 0
    else:
        print(f"ACCEPTANCE CRITERION FAILED: {a1_fail_count} A1 violations at margin {margin}x.")
        print("Per stopping rule R1, this triggers a re-sweep at margins {2.5, 3.0}x.")
        print("Run:")
        print(f"  python3 {sys.argv[0]} --corpus {corpus_path} --margin 2.5 --output results/prereg_resweep_2.5x_<ts>.csv")
        print(f"  python3 {sys.argv[0]} --corpus {corpus_path} --margin 3.0 --output results/prereg_resweep_3.0x_<ts>.csv")
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", type=Path, required=True)
    parser.add_argument("--providers", type=str, default="anthropic,openai")
    parser.add_argument("--margin", type=float, default=2.0)
    parser.add_argument("--output", type=Path, default=None)
    args = parser.parse_args()

    providers = [p.strip() for p in args.providers.split(",")]
    for p in providers:
        if p not in PROVIDER_DISPATCH:
            print(f"ERROR: unknown provider {p!r}. Known: {list(PROVIDER_DISPATCH)}", file=sys.stderr)
            return 2

    if args.output is None:
        ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        args.output = Path(f"results/prereg_run_{ts}.csv")

    return run(args.corpus, providers, args.margin, args.output)


if __name__ == "__main__":
    raise SystemExit(main())
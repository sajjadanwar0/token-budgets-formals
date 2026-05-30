#!/usr/bin/env python3
"""
collect_complementary_frame.py — MECHANICAL data collection for the
pre-registered complementary sample (preregistration.md).

>>> RUN THIS ONLY AFTER you have filled in and committed the pre-registration
>>> with a timestamp + commit SHA. The date D, the topic set, N, M and the
>>> exclusion list are part of the pre-registration and must be fixed BEFORE
>>> this script runs. Collecting first and registering later defeats the point.

What it does (mechanical only — no coding judgment):
  1. Builds the sampling frame: union of top-by-stars repos under each topic,
     re-sorted by stars, top N. Saves the raw API responses as the frozen
     snapshot `frame_snapshot_<DATE>.json`.
  2. Applies the recorded exclusions (already-cataloged sub-projects, archived
     repos, < min-issues) and freezes `complementary_frame.csv` with a reason
     for every exclusion.
  3. Pulls the M most-commented issues per included repo (PRs excluded) and
     writes a BLINDED screening sheet for two independent coders.

What it does NOT do: include/exclude decisions or cluster assignment. Those are
made by two humans (that is what the two Cohen's kappas measure).

Env: GITHUB_TOKEN (recommended — raises the rate limit from 60 to 5000/hr).

Usage:
  export GITHUB_TOKEN=ghp_...
  python3 collect_complementary_frame.py \
      --topics llm-agent ai-agent agent-framework \
      --n 40 --m 30 --min-issues 20 \
      --exclude-file excluded_subprojects.txt \
      --date 2026-06-01 --out-dir complementary
"""
import argparse, csv, json, os, sys, time, urllib.request, urllib.parse
from pathlib import Path

API = "https://api.github.com"

def gh(url, params=None):
    if params:
        url += "?" + urllib.parse.urlencode(params)
    hdr = {"Accept": "application/vnd.github+json",
           "User-Agent": "complementary-frame-collector"}
    tok = os.environ.get("GITHUB_TOKEN")
    if tok:
        hdr["Authorization"] = f"Bearer {tok}"
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=hdr), timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code in (403, 429) and attempt < 3:   # rate limit; back off
                time.sleep(15 * (attempt + 1)); continue
            raise

def body_excerpt(text, n=500):
    return " ".join((text or "").split())[:n]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--topics", nargs="+", required=True)
    ap.add_argument("--n", type=int, default=40)
    ap.add_argument("--m", type=int, default=30)
    ap.add_argument("--min-issues", type=int, default=20)
    ap.add_argument("--exclude-file", type=Path, help="newline-separated owner/repo already in the main catalog")
    ap.add_argument("--date", required=True, help="frozen observation date D (record it in the prereg)")
    ap.add_argument("--out-dir", type=Path, default=Path("complementary"))
    args = ap.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    excluded = set()
    if args.exclude_file and args.exclude_file.exists():
        excluded = {l.strip().lower() for l in args.exclude_file.read_text().splitlines() if l.strip()}

    # 1. Frame: query each topic, union, re-sort by stars.
    snapshot, pool = {}, {}
    for t in args.topics:
        q = f"topic:{t}"
        j = gh(f"{API}/search/repositories",
               {"q": q, "sort": "stars", "order": "desc", "per_page": 100})
        snapshot[t] = {"query": q, "total_count": j.get("total_count"), "items": j.get("items", [])}
        for it in j.get("items", []):
            pool[it["full_name"]] = it          # dedup across topics
        time.sleep(1)
    (args.out_dir / f"frame_snapshot_{args.date}.json").write_text(
        json.dumps(snapshot, indent=2)[:8_000_000], encoding="utf-8")

    ranked = sorted(pool.values(), key=lambda it: it["stargazers_count"], reverse=True)

    # 2. Apply exclusions, take top N that survive, freeze the frame.
    frame, taken = [], 0
    for it in ranked:
        fn = it["full_name"]
        reason = ""
        if fn.lower() in excluded:
            reason = "already in main catalog"
        elif it.get("archived"):
            reason = "archived/read-only"
        elif it.get("open_issues_count", 0) < args.min_issues:
            reason = f"<{args.min_issues} issues"
        included = reason == "" and taken < args.n
        if included:
            taken += 1
        frame.append({"rank_by_stars": ranked.index(it) + 1, "full_name": fn,
                      "stars": it["stargazers_count"], "open_issues": it.get("open_issues_count", 0),
                      "archived": it.get("archived"), "html_url": it["html_url"],
                      "included": "yes" if included else "no",
                      "exclusion_reason": reason or ("beyond top-N" if not included else "")})
        if taken >= args.n and reason == "":
            # keep listing a few beyond N for transparency, then stop the heavy issue pulls
            pass
    with (args.out_dir / "complementary_frame.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(frame[0].keys())); w.writeheader(); w.writerows(frame)
    included_repos = [r["full_name"] for r in frame if r["included"] == "yes"]
    print(f"frame: {len(pool)} unique repos pooled; {len(included_repos)} included (N={args.n}). "
          f"NOTE: non-English-docs exclusions must be applied by hand — review complementary_frame.csv.")

    # 3. Pull M most-commented issues per included repo (PRs excluded); blinded sheet.
    rows = []
    for fn in included_repos:
        try:
            issues = gh(f"{API}/repos/{fn}/issues",
                        {"state": "all", "sort": "comments", "direction": "desc", "per_page": args.m})
        except Exception as e:
            print(f"  WARN: {fn} issues pull failed: {e}"); continue
        kept = [i for i in issues if "pull_request" not in i][:args.m]
        for i in kept:
            rows.append({"repo": fn, "issue_number": i["number"], "url": i["html_url"],
                         "comments": i.get("comments", 0), "title": i.get("title", ""),
                         "body_excerpt": body_excerpt(i.get("body", "")),
                         "coder_a_include": "", "coder_a_cluster": "",
                         "coder_b_include": "", "coder_b_cluster": ""})
        time.sleep(1)
    cols = ["repo", "issue_number", "url", "comments", "title", "body_excerpt",
            "coder_a_include", "coder_a_cluster", "coder_b_include", "coder_b_cluster"]
    with (args.out_dir / "screening_sheet_blinded.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols); w.writeheader(); w.writerows(rows)
    print(f"screening sheet: {len(rows)} issues across {len(included_repos)} repos "
          f"-> {args.out_dir/'screening_sheet_blinded.csv'}")
    print("\nNEXT: two coders independently fill coder_{a,b}_include (yes/no, Section-2 criteria) and,")
    print("for included rows, coder_{a,b}_cluster (one of the eight + M-other from Codebook_v1.2).")
    print("Then run analyze_complementary.py.")

if __name__ == "__main__":
    main()
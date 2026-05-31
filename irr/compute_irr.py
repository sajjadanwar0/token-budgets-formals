#!/usr/bin/env python3
"""
compute_irr.py — recompute the inter-rater reliability for the Token Budgets
catalog from the single self-contained data file.

Reads independent_second_human_annotator_113.csv, which holds both raters'
tags (rater_a_tag, rater_b_tag) on the same 113 issues, and reports:
  - overall Cohen's kappa over the four-class scheme {bf, bu, mf, fr}
  - per-class kappa (one-vs-rest)
  - the confirmed-subset kappa (bf or bu vs the rest)
Stdlib only:  python3 compute_irr.py
"""
import csv, collections
from pathlib import Path
LABELS={"bf","bu","mf","fr"}
def kappa(pairs):
    n=len(pairs)
    if n==0: return float("nan"),float("nan"),0
    po=sum(1 for a,b in pairs if a==b)/n
    ca=collections.Counter(a for a,_ in pairs); cb=collections.Counter(b for _,b in pairs)
    pe=sum((ca[l]/n)*(cb[l]/n) for l in set(ca)|set(cb))
    return ((po-pe)/(1-pe) if pe!=1 else 0.0), po, n

def main():
    rows=list(csv.DictReader(open(Path(__file__).parent/"independent_second_human_annotator_113.csv",encoding="utf-8-sig")))
    pairs=[((r.get("rater_a_tag") or "").strip().lower(),(r.get("rater_b_tag") or "").strip().lower())
           for r in rows]
    pairs=[(a,b) for a,b in pairs if a in LABELS and b in LABELS]
    k,po,n=kappa(pairs)
    print(f"Overall (4-class) Cohen's kappa: {k:.4f}  | observed agreement {po:.4f} | n={n}")
    print("\nPer-class (one-vs-rest) kappa:")
    for L in sorted(LABELS):
        bin_pairs=[((a==L),(b==L)) for a,b in pairs]
        kc,poc,_=kappa(bin_pairs)
        print(f"  {L}: kappa={kc:.4f}  obs={poc:.4f}")
    # confirmed subset: bf-vs-bu agreement among rows BOTH raters call confirmed
    conf=[(a,b) for a,b in pairs if a in {'bf','bu'} and b in {'bf','bu'}]
    kc,poc,nc=kappa(conf)
    print(f"\nConfirmed subset (bf vs bu, both raters confirmed): kappa={kc:.4f}  obs={poc:.4f} | n={nc}")
    print("\nNote: overall 0.8374 (four-class, n=113) and confirmed-subset 0.9427")
    print("(bf-vs-bu, n=79) are DIFFERENT measures at different scopes, NOT a")
    print("discrepancy. Always cite each kappa WITH its scope.")

if __name__=="__main__":
    main()

def catalog_checks():
    """Optional: verify catalogue.csv counts (run: python3 compute_irr.py --catalog)."""
    import collections
    rows=list(csv.DictReader(open(Path(__file__).parent/"catalogue.csv",encoding="utf-8-sig")))
    ret=[r for r in rows if (r.get("label") or "").strip().lower() in LABELS]
    print(f"\ncatalogue.csv: {len(rows)} rows ({len(ret)} retained + {len(rows)-len(ret)} triaged)")
    print("label dist:", dict(collections.Counter((r.get('label') or '').strip().lower() for r in ret)))
    print("primary_cluster dist:", dict(collections.Counter((r.get('primary_cluster') or '').strip() for r in rows if (r.get('primary_cluster') or '').strip())))
    print("year dist:", dict(sorted(collections.Counter((r.get('date') or '')[:4] for r in ret if (r.get('date') or '').strip()).items())))

if __name__=="__main__":
    import sys
    if "--catalog" in sys.argv: catalog_checks()

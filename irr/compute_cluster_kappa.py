#!/usr/bin/env python3
"""
compute_cluster_kappa.py — cluster-assignment inter-rater reliability.

Mirrors compute_irr.py (the four-class IRR script): two raters, nominal
categories, Cohen's kappa. Here the categories are the EIGHT mechanism clusters.

Rater A (Sajjad) = the `primary_cluster` column of catalogue.csv.
Rater B (Zahid)  = the `rater_b_cluster` column of the returned coding sheet.
Joined on issue_id, so rater A's labels are never in rater B's sheet.

Usage:
    python3 compute_cluster_kappa.py catalogue.csv cluster_coding_sheet_BLINDED.csv

Reports: overall Cohen's kappa (8-class) + 95% bootstrap CI + observed
agreement, per-cluster one-vs-rest kappa, and the full confusion matrix.
Stdlib only.
"""
import csv, sys, collections, random

CLUSTERS = [
    "M-retry-loop","M-cost-observability","M-context-amplification",
    "M-storage-amplification","M-budget-primitive-missing","M-delegation-fanout",
    "providerOptions-silently-dropped","M-multimodal-cost-amplification",
]

def kappa(pairs):
    n=len(pairs)
    if n==0: return float("nan"), float("nan"), 0
    po=sum(1 for a,b in pairs if a==b)/n
    ca=collections.Counter(a for a,_ in pairs); cb=collections.Counter(b for _,b in pairs)
    pe=sum((ca[l]/n)*(cb[l]/n) for l in set(ca)|set(cb))
    return ((po-pe)/(1-pe) if pe!=1 else 0.0), po, n

def boot_ci(pairs, iters=10000, seed=42):
    rng=random.Random(seed); n=len(pairs); ks=[]
    for _ in range(iters):
        samp=[pairs[rng.randrange(n)] for _ in range(n)]
        k,_,_=kappa(samp)
        if k==k: ks.append(k)   # drop NaN
    ks.sort()
    lo=ks[int(0.025*len(ks))]; hi=ks[int(0.975*len(ks))]
    return lo, hi

def main():
    cat = sys.argv[1] if len(sys.argv)>1 else "catalogue.csv"
    sheet = sys.argv[2] if len(sys.argv)>2 else "cluster_coding_sheet_BLINDED.csv"

    a = {r["issue_id"]: (r["primary_cluster"] or "").strip()
         for r in csv.DictReader(open(cat, encoding="utf-8-sig"))
         if (r["primary_cluster"] or "").strip()}
    b = {r["issue_id"]: (r.get("rater_b_cluster") or "").strip()
         for r in csv.DictReader(open(sheet, encoding="utf-8-sig"))}

    ids = sorted(set(a) & set(b))
    pairs=[]; skipped=[]
    for i in ids:
        ra, rb = a[i], b[i]
        if rb in ("","INACCESSIBLE","UNSURE") or rb not in CLUSTERS:
            skipped.append((i,rb)); continue
        if ra not in CLUSTERS:
            skipped.append((i,ra)); continue
        pairs.append((ra,rb))

    print(f"matched issue_ids: {len(ids)}   scored pairs: {len(pairs)}   "
          f"skipped (blank/inaccessible/unsure/unknown): {len(skipped)}")
    if skipped:
        print("  skipped:", ", ".join(f"{i}({v or 'blank'})" for i,v in skipped[:20]),
              ("..." if len(skipped)>20 else ""))
    if not pairs:
        print("\nNo scorable pairs. Check that the return sheet has a filled "
              "`rater_b_cluster` column and that issue_ids match catalogue.csv.")
        return

    k, po, n = kappa(pairs)
    lo, hi = boot_ci(pairs)
    print(f"\nOverall (8-cluster) Cohen's kappa: {k:.4f}   "
          f"95% bootstrap CI [{lo:.3f}, {hi:.3f}]   observed agreement {po:.4f}   n={n}")

    print("\nPer-cluster (one-vs-rest) kappa:")
    for c in CLUSTERS:
        bin_pairs=[((x==c),(y==c)) for x,y in pairs]
        kc,poc,_=kappa(bin_pairs)
        support=sum(1 for x,_ in pairs if x==c)
        print(f"  {c:<34} kappa={kc:.3f}  obs={poc:.3f}  (A-support={support})")

    print("\nConfusion matrix (rows = rater A / Sajjad, cols = rater B / Zahid):")
    idx={c:j for j,c in enumerate(CLUSTERS)}
    m=[[0]*len(CLUSTERS) for _ in CLUSTERS]
    for x,y in pairs: m[idx[x]][idx[y]]+=1
    short=[c.replace("M-","").replace("-silently-dropped","-drop")[:10] for c in CLUSTERS]
    print("           "+" ".join(f"{s:>10}" for s in short))
    for j,c in enumerate(CLUSTERS):
        print(f"{short[j]:>10} "+" ".join(f"{m[j][t]:>10}" for t in range(len(CLUSTERS))))

    print("\nDisagreements (for the adjudication paragraph):")
    dis=[]
    for i in ids:
        ra=a.get(i,""); rb=b.get(i,"")
        if ra in CLUSTERS and rb in CLUSTERS and ra!=rb:
            dis.append((i,ra,rb))
    for i,ra,rb in dis:
        print(f"  {i}: A={ra}  B={rb}")
    print(f"\n  total disagreements: {len(dis)} of {len(pairs)} scored "
          f"({100*len(dis)/max(len(pairs),1):.1f}%)")

if __name__=="__main__":
    main()
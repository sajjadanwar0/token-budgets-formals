# IRR disagreements (auto-derived)

The 12 rater-pair disagreements in the N=113 two-rater sample, derived
directly from `independent_second_human_annotator_113.csv`. The adjudicated
resolution is rater A's tag, which is the authoritative `label` carried in
`catalogue.csv`. Regenerate with the snippet at the bottom.

| issue_id | framework | rater_a | rater_b | resolved (catalogue `label`) |
|---|---|---|---|---|
| AGPT-001 | autogpt | fr | bf | fr |
| AIDR-003 | aider | bu | bf | bu |
| ATGN-018 | autogen | fr | bu | fr |
| CDXL-001 | codex | mf | fr | mf |
| CRAI-010 | crewai | bu | fr | bu |
| GPTE-002 | gpt-engineer | bf | fr | bf |
| LANG-016 | langchain | bu | bf | bu |
| LANG-036 | langchain | fr | bf | fr |
| LANG-037 | langchain | bu | fr | bu |
| MAST-007 | mastra | bf | fr | bf |
| OAAS-002 | openai-agents | bu | fr | bu |
| PYAI-005 | pydantic-ai | fr | bu | fr |

Total: 12 disagreements / 113 pairs (observed agreement 0.894).
All disagreements fall on the bu/fr/bf boundaries; none involve `mf`.

```python
import csv
r=list(csv.DictReader(open('independent_second_human_annotator_113.csv',newline='',encoding='utf-8-sig')))
print([(x['issue_id'],x['rater_a_tag'],x['rater_b_tag']) for x in r
       if x['rater_a_tag'].strip()!=x['rater_b_tag'].strip()])
```

#!/usr/bin/env python3
"""Produce the paired table and qualified interpretation from frozen scoring logs."""
import csv
import json
import re
from pathlib import Path
from collections import Counter
from score_frozen_lora_comparison import OUT, ROOT, summarize, sha

def main():
    for p in OUT.glob('*/*/result.json'):
        row=json.loads(p.read_text()); st=row['stages'].get('jasper',{}); d=st.get('details',{}); status=st.get('status')
        if d.get('jasper_log') and not d.get('jasper_report'):
            text=(ROOT/d['jasper_log']).read_text(errors='replace')
            if re.search(r'ERROR \(ENL002\): Unable to find signal',text): status='CONSTRAINT_MISMATCH'
            elif re.search(r'\[ERROR \(VERI-|errors detected in the design',text): status='ANALYSIS_FAILED'
        elif d.get('raw_zero') and not d.get('cdc_clean') and d.get('async_clock_groups') and not d.get('crossings_extracted') and not d.get('pairs_extracted'): status='INCONCLUSIVE_NO_CROSSINGS'
        if status!=st.get('status'):
            st['raw_status']=st['status']; st['status']=status; st['classification_note']='Postprocessing fixed Jasper logs: no change to candidates, constraints, or tool execution.'
            p.write_text(json.dumps(row,indent=2)+'\n')
    data=summarize(); rows=data['results']; stages=['compile','functional','structural_lint','enhanced','jasper']
    assert all(r.get('complete') for r in rows) and len(rows)==132, 'Scoring is incomplete'
    frozen=json.loads((OUT/'frozen-inputs.json').read_text())
    for category in ['candidates','evaluation_assets']:
        for name,digest in frozen[category].items(): assert sha(ROOT/name)==digest,name
    assert all(r.get('jasper_mode')=='fixed_structural_only' for r in rows), 'Mixed Jasper modes'
    by={(r['arm'],r['circuit']):r for r in rows}; circuits=sorted({r['circuit'] for r in rows})
    verification={'input_hashes_verified':sum(len(frozen[k]) for k in ['candidates','evaluation_assets']),'checker_code_verified':0}
    for name,digest in frozen.get('checker_code_sha256',{}).items():
        assert sha(ROOT/name)==digest,name
        verification['checker_code_verified']+=1
    prior=Path('/home/ft2335/dataset-qwen38-score/experiments/qwen38_gate_pipeline.json')
    if prior.is_file():
        old={r['circuit']:r for r in json.loads(prior.read_text())['results'] if r.get('prompt')=='cdc_explicit' and r.get('attempt')=='attempt-001'}
        differences=[]; checked=0
        for c in circuits:
            for st,key in [('compile','compile_ok'),('functional','functional_ok')]:
                if c in old and old[c].get(key) is not None:
                    checked+=1
                    if (by['base',c]['stages'][st]['status']=='PASS')!=old[c][key]: differences.append({'circuit':c,'stage':st,'prior':old[c][key],'now':by['base',c]['stages'][st]['status']})
        verification['prior_base_comparisons']=checked; verification['prior_base_differences']=differences
    (OUT/'verification.json').write_text(json.dumps(verification,indent=2)+'\n')
    with (OUT/'paired-results.csv').open('w') as f:
        writer=csv.writer(f); writer.writerow(['circuit']+[f'{a}_{s}' for a in ['base','lora','golden'] for s in stages])
        for c in circuits: writer.writerow([c]+[by[a,c]['stages'][s]['status'] for a in ['base','lora','golden'] for s in stages])
    lines=['# Frozen base versus audited LoRA comparison','',
      'All 44 circuits; `cdc_explicit`; attempt 1. The existing base candidates were reused. No generation, retraining, or repair was performed during scoring.', '',
      'Both arms and 44 golden controls used identical evaluation assets. All five checks were attempted independently, including after compilation or functional failure. Functional/enhanced failures caused by inability to compile remain failures of those attempted tests; see the compile column and logs to distinguish these from behavioral failures.', '',
      '| Check | Base pass / 44 | LoRA pass / 44 | Golden control pass / 44 | Gained passes | Lost passes |',
      '|---|---:|---:|---:|---:|---:|']
    for s in stages:
        nums=[data['summary'][a]['stages'][s].get('PASS',0) for a in ['base','lora','golden']]; pair=data['paired'][s]
        gained=[p['circuit'] for p in pair['pairs'] if p['base']!='PASS' and p['lora']=='PASS']
        lost=[p['circuit'] for p in pair['pairs'] if p['base']=='PASS' and p['lora']!='PASS']
        pair['gained_passes']=gained; pair['lost_passes']=lost
        lines.append(f"| {s} | {nums[0]} | {nums[1]} | {nums[2]} | {len(gained)} | {len(lost)} |")
    lines+=['','Gained/lost passes compare PASS against every other status; losing a Jasper pass to an analysis failure is not evidence of a new CDC violation. The JSON also retains strictly FAIL-to-PASS and PASS-to-FAIL transitions separately. Tool errors, constraint mismatches, analysis failures, missing crossing evidence, unsupported checks, and wall timeouts are separate statuses. They are not reported as demonstrated CDC violations. Denominators remain 44.', '',
      '| Joint outcome | Base / 44 | LoRA / 44 |','|---|---:|---:|']
    for name,ss in [('Compile + functional',['compile','functional']),('Functional + lint',['functional','structural_lint']),('Functional + enhanced',['functional','enhanced']),('Functional + Jasper',['functional','jasper']),('All five checks',stages)]:
        nums=[sum(all(by[a,c]['stages'][s]['status']=='PASS' for s in ss) for c in circuits) for a in ['base','lora']]
        lines.append(f'| {name} | {nums[0]} | {nums[1]} |')
    lines+=['',f"Integrity verification: {verification['input_hashes_verified']} candidate/asset hashes and {verification['checker_code_verified']} evaluator code hashes matched after scoring. Prior base compile/functional checks compared: {verification.get('prior_base_comparisons',0)}; differences: {len(verification.get('prior_base_differences',[]))}.",'', '## Evaluation limits','',
      'Structural lint checks the documented A–H anti-patterns; a pass means no matched pattern, not complete CDC safety. Enhanced TB pass means the fixed stress scenarios passed, not proof across all asynchronous timing.', '',
      'Jasper ran only the fixed structural CDC checks. Extra protocol and metastability proof commands from the legacy wrapper were disabled for every row. The Jasper column is the existing structural `cdc_clean` criterion: zero reported CDC/RDC violations, no waived violations, and extracted crossing evidence when the fixed constraints declare asynchronous groups. It is not a protocol-proof, metastability-signoff, or MTBF claim. Protocol exports and mentions of proof in logs do not establish a protocol pass.', '',
      'Jasper uses the benchmark’s fixed analysis dialect and constraints. Language/parser limitations and golden baseline failures are listed below and must qualify interpretation. Generated tops replace golden tops; existing benchmark helper RTL dependencies remain fixed and are shared by both arms. These are scores within that harness, not necessarily standalone full-design generation scores.', '',
      'Golden controls are evaluation references only. No golden RTL, test log, or Jasper output was supplied to a model. This scoring script contains no model invocation.', '', '### Golden controls that do not pass','']
    for s in stages:
        groups={}
        for c in circuits:
            st=by['golden',c]['stages'][s]['status']
            if st!='PASS': groups.setdefault(st,[]).append(c)
        lines.append(f"- {s}: "+('; '.join(f"{k}: {', '.join(v)}" for k,v in groups.items()) if groups else 'all pass'))
    lines+=['','### Jasper analysis and coverage limitations','']
    for a in ['base','lora','golden']:
        for s in stages:
            special={k:v for k,v in data['summary'][a]['stages'][s].items() if k not in ['PASS','FAIL']}
            if special: lines.append(f'- {a} / {s}: {special}')
    lines+=['','### Functional changes','',f"- Improved: {', '.join(data['paired']['functional']['improved']) or 'none'}",f"- Regressed: {', '.join(data['paired']['functional']['regressed']) or 'none'}",'',
       '### Compile failure signatures','']
    for a in ['base','lora']:
        fails=[by[a,c] for c in circuits if by[a,c]['stages']['compile']['status']=='FAIL']
        missing=[]
        for r in fails:
            log=ROOT/r['stages']['compile'].get('details',{}).get('log','__missing__')
            if log.is_file() and 'cannot open include file' in log.read_text(errors='replace'): missing.append(r['circuit'])
        lines.append(f"- {a}: {len(fails)} compile failures; {len(missing)} contain missing-include errors ({', '.join(missing) or 'none'}). Categories can overlap other errors.")
    lines+=['','## Artifacts','',
      '- `results.json`: stage details, runtimes, log paths, aggregate counts, and paired changes.',
      '- `paired-results.csv`: one row per circuit, both arms and golden controls.',
      '- `frozen-inputs.json`: input and evaluation-asset SHA-256 hashes; reverified after scoring.',
      '- `<arm>/<circuit>/result.json`: per-candidate results. Candidate copies only remove an outer Markdown fence and normalize trailing whitespace; originals are preserved and hash checked.',
      '- Slurm generation job 21629523 final exit code remains unconfirmed; artifact completion was independently verified.', '']
    (OUT/'results.json').write_text(json.dumps(data,indent=2)+'\n')
    verification['reporter_sha256']=sha(Path(__file__))
    (OUT/'verification.json').write_text(json.dumps(verification,indent=2)+'\n')
    (OUT/'REPORT.md').write_text('\n'.join(lines))
    print('\n'.join(lines[:28]))
if __name__=='__main__': main()

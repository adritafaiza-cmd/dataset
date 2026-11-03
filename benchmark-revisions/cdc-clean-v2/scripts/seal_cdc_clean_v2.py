#!/usr/bin/env python3
"""Verify validation artifacts and freeze the CDC-clean v2 reference release."""
import csv,hashlib,json,re,sys
from pathlib import Path
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from evaluate_generated import manifest_list

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 out=ROOT/'experiments/golden-validation-v2';circuits=sorted(p.parent.name for p in (ROOT/'benchmarks').glob('*/manifest.yaml'));assert len(circuits)==44
 stages=['compile','functional','formal','lint','enhanced','jasper'];rows=[];bounds=[]
 baseline=json.loads((ROOT/'BASELINE.json').read_text())['original_sha256']
 original=ROOT.parents[1]
 assert all(sha(original/p)==h for p,h in baseline.items()),'The original benchmark changed'
 changed=[p for p,h in baseline.items() if (ROOT/p).is_file() and sha(ROOT/p)!=h]
 assert not any('/constraints/' in p or p.endswith('/jasper/run.tcl') for p in changed),'Clock/checker constraints changed'
 for c in circuits:
  row=json.loads((out/c/'result.json').read_text());assert row.get('complete') and all(row['stages'].get(s,{}).get('status')=='PASS' for s in stages),c
  j=row['stages']['jasper']['details'];assert j['jg_returncode']==0 and j['cdc_clean']
  assert all(j[k]==0 for k in ['cdc_errors','rdc_errors','error_rows','waived_cdc','waived_rdc']),c
  clocks=manifest_list(c,'clocks')
  if len(clocks)>1:
   if j['async_clock_groups']: assert j['pairs_extracted']>0,c
   inferred=ROOT/j['report_dir']/'inferred_clocks.rpt.csv';text=inferred.read_text()
   assert all(clock in text for clock in clocks),c
  sb=ROOT/'formal'/c/'golden.sby';text=sb.read_text();depth=int(re.search(r'prove: depth (\d+)',text).group(1))
  cover=(ROOT/'build/formal-v2'/c/'cover.log').read_text();steps=[int(x) for x in re.findall(r'Reached cover statement in step (\d+)',cover)]
  assert steps and depth>max(steps),(c,depth,steps)
  # The checked RTL and harness copies must match the release sources.
  files=text.split('[files]',1)[1].splitlines()
  for task in ['prove','cover']:
   assert row['stages']['formal']['details'][task]['returncode']==0 and (ROOT/'build/formal-v2'/c/task/'PASS').is_file(),(c,task)
   for name in files:
    name=name.strip()
    if not name or name.startswith('#'):continue
    p=Path(name);p=p if p.is_absolute() else sb.parent/p
    copied=ROOT/'build/formal-v2'/c/task/'src'/p.name
    assert copied.is_file() and sha(p)==sha(copied),(c,task,p)
  bounds.append({'circuit':c,'mode':'bmc','prove_depth':depth,'latest_cover_step':max(steps),'clocks':clocks,'pairs_extracted':j['pairs_extracted']})
  rows.append(row)
 for c in ['cdc_2phase','cdc_2phase_clearable','cdc_4phase']:
  p=ROOT/'experiments/golden-validation-v2-WIDTH8'/c/'result.json';d=json.loads(p.read_text());assert d['stages']['jasper']['status']=='PASS',c
 neg=json.loads((ROOT/'experiments/v2-negative-controls/results.json').read_text());assert neg['passed']
 rtls=sorted({Path(p).parts[1] for p in changed if p.startswith('benchmarks/') and '/fixed/rtl/' in p})
 suffixes={'.v','.sv','.vh','.svh','.tcl','.sdc','.yaml','.sby','.py','.sh','.csh','.md','.txt','.json'}
 assets={}
 for folder in ['benchmarks','formal','scripts','enhanced_cdc_tb','cdc_tb_checks','vendor','experiments/prompts']:
  for p in (ROOT/folder).rglob('*'):
   if p.is_file() and p.suffix in suffixes and '__pycache__' not in p.parts:assets[str(p.relative_to(ROOT))]=sha(p)
 result={'version':'cdc-clean-v2','sealed_utc':datetime.now(timezone.utc).isoformat(),'circuits':circuits,'gates':{s:{'PASS':44,'denominator':44} for s in stages},'multi_clock_references':24,'asynchronous_references':22,'related_clock_references':2,'single_clock_controls':20,'formal_mode':'bounded_model_checking','formal_bounds':bounds,'width8_jasper_sweeps':['cdc_2phase','cdc_2phase_clearable','cdc_4phase'],'negative_controls_passed':True,'changed_rtl_circuits':rtls,'changed_original_files':changed,'clock_constraints_unchanged':True,'original_994_files_unchanged':True,'original_archive_sha256':sha(ROOT.parent/'cdc-clean-v1-frozen.tar.gz'),'sources_sha256':assets,'results':rows}
 (ROOT/'VALIDATION.json').write_text(json.dumps(result,indent=2)+'\n')
 with (ROOT/'VALIDATION.csv').open('w') as f:
  w=csv.writer(f);w.writerow(['circuit',*stages,'formal_bmc_depth','latest_cover_step','clock_count','jasper_pairs'])
  for row,b in zip(rows,bounds):w.writerow([row['circuit'],*[row['stages'][s]['status'] for s in stages],b['prove_depth'],b['latest_cover_step'],len(b['clocks']),b['pairs_extracted']])
 lines=['# CDC-clean benchmark v2 validation','',
 'All 44 reference circuits pass the following checks in the isolated v2 tree. No circuit was excluded.', '',
 '| Check | Pass |','|---|---:|',*[f'| {s} | 44/44 |' for s in stages], '',
 'Jasper reports zero raw CDC/RDC errors and zero waived violations on every reference. All 24 multi-clock references retain both declared clocks. The 22 asynchronous references have positive extracted crossing pairs; the two isochronous references retain their documented generated-clock relationship and do not produce asynchronous pairs. The remaining 20 are single-clock controls. All SDC and per-circuit Jasper setup files are unchanged from v1.', '',
 'The three handshake primitives also pass Jasper with WIDTH=8. Two deliberate faults are rejected: a control-synchronizer bypass by Jasper, and payload corruption by the functional TB, enhanced TB, and a concrete bounded-formal counterexample.', '',
 '## What changed','',
 'The 18 originally flagged references now synchronize payloads before use while retaining queue ownership or request/acknowledge protection. Additional settling/availability latency is documented. Bidirectional storage uses separate directional banks. APB register byte preservation/access-phase behavior and reset-controller isolate/clear/release sequencing were also corrected. RTL changed in 20 circuits:', '',', '.join(rtls)+'.','',
 'Specifications and all three prompt profiles were updated for the 20 RTL changes. Functional/observable profiles state behavior; CDC-explicit profiles retain the additional CDC guidance. Existing functional and enhanced assertions were preserved, except that APB strobe expectations now require unstrobed-byte preservation rather than the previous incorrect clearing behavior.', '',
 '## Formal evidence and limits','',
 'Every circuit passes both bounded assertions and cover reachability. Assertion depths extend beyond the latest reached cover for each circuit. VALIDATION.csv lists all bounds. These are bounded model checks under the specified harness clocks, assumptions, and configurations—not unbounded functional proofs or metastability/MTBF signoff.', '',
 'Formal repairs include preventing startup-counter wrap, separating typed-DUT elaboration from native symbolic harness handling, driving explicit clocks across frontend boundaries, reset-aware APB state assertions, legal APB/Wishbone environment assumptions, and Wishbone error-abort semantics. No assertion was removed merely to make a golden pass. The full byte-state model replaces incorrect reset/address assumptions with explicit state tracking.', '',
 '## Version boundary','',
 'The original 994 benchmark/support files are unchanged and archived in ../cdc-clean-v1-frozen.tar.gz. The earlier base/LoRA candidate comparison belongs to v1 and remains unchanged. Revised v2 prompts/contracts require fresh matched base and LoRA generations for a primary v2 comparison; do not relabel the old scores or regenerate only one arm.', '',
 'No model generation, retraining, or repair feedback occurred during this revision. Goldens and Jasper reports remain evaluation assets and must stay out of model inputs.', '',
 '## Reproduce','',
 'From the original repository root:', '', '```bash',
 'python3 benchmark-revisions/cdc-clean-v2/scripts/validate_cdc_clean_v2.py',
 'python3 benchmark-revisions/cdc-clean-v2/scripts/validate_cdc_clean_v2.py --circuits cdc_2phase cdc_2phase_clearable cdc_4phase --checks jasper --parameter WIDTH=8',
 'python3 benchmark-revisions/cdc-clean-v2/scripts/validate_cdc_v2_negative_controls.py',
 'python3 benchmark-revisions/cdc-clean-v2/scripts/seal_cdc_clean_v2.py', '```', '',
 'Commercial checks require the working Xcelium/Jasper license environment. The validator uses the installed oss-cad-suite for formal checks. VALIDATION.json records source hashes and individual log paths.','']
 (ROOT/'REPORT.md').write_text('\n'.join(lines))
 print(json.dumps({k:v for k,v in result.items() if k in ['version','gates','multi_clock_references','single_clock_controls','negative_controls_passed','original_994_files_unchanged']},indent=2))
 print('Source assets sealed:',len(assets))
if __name__=='__main__':main()

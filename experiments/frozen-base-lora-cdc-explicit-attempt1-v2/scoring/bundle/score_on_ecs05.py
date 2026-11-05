"""Score untouched v2 candidates in an isolated extraction, with golden stage gates.
No model, generation, repair, candidate normalization, or feedback path exists.
"""
from pathlib import Path
import argparse,sys,os,json,hashlib,subprocess,shutil,re,time,csv
B=Path(__file__).resolve().parent;A=B/'evaluator'
sys.path[:0]=[str(A/'scripts'),str(A/'enhanced_cdc_tb'),str(A/'cdc_tb_checks')]
import evaluate_generated as ev
import evaluate_pass_at_n as base
import run_enhanced as en
import run_jasper_full_cdc as j
from lint_cdc import lint_findings
j.EXTRA_TCL=''  # Fixed Jasper structural mode, protocol remains a separate not-run field.
STAGES=['compile','functional','structural_lint','enhanced_behavioral_tb','jasper']
OUT=A/'experiments/frozen-v2-scoring'
def save(p,x):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(x,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def verify():
 for r in json.loads((B/'evaluation-asset-hashes.json').read_text())['assets']:assert sha(A/r['path'])==r['sha256'],r['path']
 cc=json.loads((B/'candidate-hashes.json').read_text())['candidates'];assert len(cc)==88
 for r in cc:assert sha(B/r['path'])==r['sha256'],r['path']
 return cc
REAL_RUN=subprocess.run

def stage_call(arm,c,rtl,stage,dest):
 d=dest/stage;d.mkdir(parents=True,exist_ok=True);calls=[];last_text=[]
 def logged_run(*args,**kwargs):
  n=len(calls);cmd=args[0] if args else kwargs.get('args');call={'command':list(map(str,cmd)) if isinstance(cmd,(list,tuple)) else cmd,'cwd':str(kwargs.get('cwd',Path.cwd()))}
  calls.append(call);save(d/'commands.json',calls)
  kwargs.setdefault('timeout',660 if stage=='jasper' else 180)
  try:
   p=REAL_RUN(*args,**kwargs);call['returncode']=p.returncode
   stdout=p.stdout or '';stderr=p.stderr or ''
  except subprocess.TimeoutExpired as exc:
   stdout=exc.stdout or b'';stderr=exc.stderr or b'';call['classification']='timeout'
   for key,val in [('stdout',stdout),('stderr',stderr)]:(d/f'command-{n}.{key}.log').write_text(val.decode(errors='replace') if isinstance(val,bytes) else val)
   save(d/'commands.json',calls);raise
  for key,val in [('stdout',stdout),('stderr',stderr)]:(d/f'command-{n}.{key}.log').write_text(val.decode(errors='replace') if isinstance(val,bytes) else val)
  last_text.extend([str(stdout),str(stderr)]);save(d/'commands.json',calls);return p
 subprocess.run=logged_run
 start=time.monotonic()
 try:
  if stage=='structural_lint':
   files=[rtl]  # Exact top-only lint scope used by the validated v2 validator.
   findings=[f for p in files for f in lint_findings(p.read_text(errors='replace'),str(p))]
   data={'findings':findings};ok=not findings
  elif stage=='compile':data=ev.evaluate(rtl,c,dest);ok=data['compile_ok']
  elif stage=='functional':data=base.simulate(rtl,c,dest);ok=data['simulate_ok']
  elif stage=='enhanced_behavioral_tb':
   data=en.run_one(dict(source='sealed-v2-'+arm,circuit=c,prompt='cdc_explicit',attempt='attempt-001',rtl=rtl));ok=data['status']=='PASS'
  else:
   data=j.run_one(dict(kind='golden' if arm=='golden' else 'generated',source='sealed-v2-'+arm,circuit=c,prompt='cdc_explicit',attempt='attempt-001',rtl=str(rtl.relative_to(A))));ok=bool(data.get('cdc_clean')) and data.get('jg_returncode')==0
  for key in ['log','sim_log','jasper_log']:
   if data.get(key):
    p=Path(data[key]);p=p if p.is_absolute() else A/p
    if p.is_file():last_text.append(p.read_text(errors='replace'))
  text='\n'.join(last_text);runtime=en.runtime_text(text);classification='pass' if ok else 'design_failure'
  if re.search(r'license.*(?:fail|unavailable|not available)|unable to.*license|cannot.*license|LMF-',text,re.I):classification='license_failure'
  elif any(data.get(k) in [124,137] for k in ['jg_returncode','sim_returncode','returncode']) or re.search(r'WALL_TIMEOUT|xrun timeout|\bTIMEOUT\b',runtime+'\n'+str(data.get('note','')),re.I):classification='timeout'
  elif re.search(r'command not found|error while loading shared libraries|segmentation fault|internal (?:error|exception)|Permission denied',text,re.I):classification='tool_error'
  elif re.search(r'cannot open include file|cannot (?:open|find).*file|No such file or directory',text,re.I):classification='missing_assets'
  elif stage=='jasper' and re.search(r'ENL002|Unable to find signal',text,re.I):classification='constraint_mismatch'
  elif stage=='jasper' and not data.get('jasper_report') and not data.get('elab_fail'):classification='tool_error'
  elif stage=='jasper' and data.get('raw_zero') and not ok:classification='inconclusive_coverage'
  elif stage=='enhanced_behavioral_tb' and data.get('status')=='SKIP':classification='missing_assets'
  elif not ok and stage in ['functional','enhanced_behavioral_tb'] and not re.search(r'VIOLATION|TESTS FAILED|ENHANCED FAIL|\*(?:E|F),',runtime):classification='inconclusive_no_pass_marker'
  (d/'combined-tool-output.log').write_text(text)
  result=dict(status=classification,seconds=time.monotonic()-start,details=data,protocol='not_run' if stage=='jasper' else 'not_available')
  if stage=='enhanced_behavioral_tb':
   result['protocol_violations']=re.findall(r'^.*PROTOCOL VIOLATION\s+\[[^\]]+\].*$',runtime,re.M)
   result['cdc_reset_violations']=re.findall(r'^.*CDC(?:/RESET)? VIOLATION\s+\[[^\]]+\].*$',runtime,re.M)
   result['protocol']='design_failure' if result['protocol_violations'] else 'no_protocol_violation_observed' if classification=='pass' else 'inconclusive'
 except subprocess.TimeoutExpired as exc:result=dict(status='timeout',error=str(exc),seconds=time.monotonic()-start)
 except FileNotFoundError as exc:result=dict(status='tool_unavailable' if not shutil.which('jg' if stage=='jasper' else 'xrun') and stage!='structural_lint' else 'missing_assets',error=str(exc))
 except Exception as exc:result=dict(status='tool_error',error=f'{type(exc).__name__}: {exc}')
 finally:subprocess.run=REAL_RUN
 save(d/'stage.json',result);return result

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--execute',action='store_true');args=ap.parse_args()
 cc=verify();circuits=sorted({r['circuit'] for r in cc});os.environ['PATH']=base.XRUN_BIN+':'+base.JG_BIN+':'+os.environ.get('PATH','');os.environ['CDC_CHECKS']='0'
 tools={t:shutil.which(t) for t in ['xrun','jg']};print(json.dumps(dict(verified_candidates=88,circuits=44,tools=tools,execute=args.execute)))
 if not args.execute:return
 if not all(tools.values()):raise SystemExit('Dynamic scoring blocked: xrun and jg must both be available; no design scores emitted.')
 if OUT.exists():raise SystemExit('Output already exists. Preserve it and use a fresh bundle extraction to rerun.')
 save(OUT/'tool-preflight.json',dict(tools=tools,host=os.uname().nodename))
 controls={};rows=[]
 for c in circuits:
  rtl=ev.top_rtl_for(c);dest=OUT/'golden'/c
  stages={s:stage_call('golden',c,rtl,s,dest) for s in STAGES}
  row=dict(arm='golden',circuit=c,sha256=sha(rtl),stages=stages);controls[c]=row;rows.append(row);save(dest/'result.json',row)
  print('golden',c,{s:d['status'] for s,d in stages.items()},flush=True)
 for item in cc:
  arm=item['arm'];c=item['circuit'];source=B/item['path'];rtl=A/'experiments/v2-inputs'/arm/c/source.name;rtl.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,rtl);assert sha(rtl)==item['sha256']
  dest=OUT/arm/c;stages={}
  for s in STAGES:
   stages[s]=stage_call(arm,c,rtl,s,dest) if controls[c]['stages'][s]['status']=='pass' else dict(status='checker_invalid',golden_status=controls[c]['stages'][s]['status'])
  assert sha(rtl)==item['sha256'] and sha(source)==item['sha256'];row=dict(**item,stages=stages,all_five='pass' if all(d['status']=='pass' for d in stages.values()) else 'design_failure' if any(d['status']=='design_failure' for d in stages.values()) else 'pending');rows.append(row);save(dest/'result.json',row)
  print(arm,c,{s:d['status'] for s,d in stages.items()},flush=True)
 verify();save(OUT/'results.json',rows)
 paired=[]
 for c in circuits:
  p={'circuit':c};b=next(r for r in rows if r['arm']=='base' and r['circuit']==c);l=next(r for r in rows if r['arm']=='lora' and r['circuit']==c)
  for arm,r in [('base',b),('lora',l)]:
   p[arm+'_truncated']=r['truncated'];p[arm+'_candidate_sha256']=r['sha256'];p[arm+'_all_five']=r['all_five']
   for s in STAGES:p[arm+'_'+s]=r['stages'][s]['status']
  for s in STAGES:
   bs=b['stages'][s]['status'];ls=l['stages'][s]['status'];p[s+'_gain_loss']='gain' if bs=='design_failure' and ls=='pass' else 'loss' if bs=='pass' and ls=='design_failure' else 'tie' if bs==ls and bs in ['pass','design_failure'] else 'pending'
  paired.append(p)
 with (OUT/'paired-results.csv').open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=list(paired[0]));w.writeheader();w.writerows(paired)
 print('Saved',OUT,'; all 44 remain in each arm denominator.')
if __name__=='__main__':main()

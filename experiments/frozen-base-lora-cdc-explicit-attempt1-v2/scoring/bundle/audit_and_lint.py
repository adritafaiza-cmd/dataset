"""Verify frozen assets and run available lint controls; no simulation/formal claims."""
from pathlib import Path
import sys,json,hashlib,subprocess,shutil,re,csv,time,os
B=Path(__file__).resolve().parent;A=B/'evaluator';O=B.parent/'results';O.mkdir(exist_ok=True)
sys.path[:0]=[str(A/'scripts'),str(A/'cdc_tb_checks'),str(A/'enhanced_cdc_tb')]
import evaluate_generated as ev
import run_enhanced as enhanced
from lint_cdc import lint_findings

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,data):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(data,indent=2)+'\n')
assets=json.loads((B/'evaluation-asset-hashes.json').read_text());candidates=json.loads((B/'candidate-hashes.json').read_text())['candidates']
for r in assets['assets']:assert sha(A/r['path'])==r['sha256'],r['path']
for r in candidates:assert sha(B/r['path'])==r['sha256'],r['path']
circuits=sorted({r['circuit'] for r in candidates});assert len(circuits)==44 and len(candidates)==88
# Verify selected live-asset paths against the validated v2 counterparts.
v2=[]
for r in assets['assets']:
 p=A/r['path']; parts=Path(r['path']).parts
 if parts[0] not in {'benchmarks','enhanced_cdc_tb'}:continue
 counterpart=A/r['path']
 if counterpart.is_file():v2.append(dict(path=r['path'],matches=sha(p)==sha(counterpart)))
# Static file references in canonical simulation/Jasper scripts, manifests, and includes.
audit=[]
for c in circuits:
 row=dict(circuit=c,errors=[],referenced_files=[])
 try:
  bench=A/'benchmarks'/c;top=ev.top_rtl_for(c);row['golden_top']=str(top.relative_to(A))
  for rel in ev.manifest_list(c,'rtl_fixed')+[ev.manifest_scalar(c,k) for k in ['simulation','constraints','jasper']]:
   p=bench/rel;row['referenced_files'].append(str(p.relative_to(A)))
   if not p.is_file():row['errors'].append('missing '+str(p.relative_to(A)))
  sim=bench/ev.manifest_scalar(c,'simulation');tb=enhanced.canonical_tb(c);etb=enhanced.enhanced_tb(c)
  assert etb is not None,'missing enhanced TB'
  row['canonical_tb']=str(tb.relative_to(A));row['enhanced_tb']=str(etb.relative_to(A))
  for token in re.findall(r'\$(?:\{)?(?:BENCH|ROOT)(?:\})?/[^\s"\]\\;]+',sim.read_text()):
   # Only source/include paths; output build directories need not exist.
   token=token.rstrip(')');p=Path(token.replace('${BENCH}',str(bench)).replace('$BENCH',str(bench)).replace('${ROOT}',str(A)).replace('$ROOT',str(A)))
   if '/build/' not in str(p) and not p.exists():row['errors'].append('unresolved script path '+token)
  for rtl in [bench/p for p in ev.manifest_list(c,'rtl_fixed')]+[tb,etb]:
   for inc in re.findall(r'`include\s+"([^"]+)"',rtl.read_text(errors='replace')):
    if not (rtl.parent/inc).exists() and not any(A.glob('**/'+inc)):row['errors'].append('missing include '+inc)
 except Exception as exc:row['errors'].append(str(exc))
 audit.append(row)
save(O/'asset-audit.json',dict(commit=assets['commit'],hashed_assets_verified=len(assets['assets']),candidate_hashes_verified=88,v2_comparisons=v2,circuits=audit))
# Record actual local tool discovery, including canonical installation locations.
tools={name:shutil.which(name) for name in ['xrun','iverilog','vvp','jg','jaspergold']}
for name,p in {'xrun':'/eda/cadence/XCELIUM2603/tools.lnx86/inca/bin/64bit/xrun','jg':'/eda/cadence/JASPER/bin/jg'}.items():
 if Path(p).is_file() and os.access(p,os.X_OK):tools[name]=p
save(O/'tool-preflight.json',dict(tools=tools,host=os.uname().nodename,ssh_blocker='ecs05.poly.edu port 22 connection timed out',note='No dynamic golden control is validated without running its tool.'))
# Typed-evidence audit is not a behavioral golden control.
typed=subprocess.run([sys.executable,str(A/'enhanced_cdc_tb/check_typed_evidence.py')],capture_output=True,text=True)
(O/'typed-evidence.stdout.log').write_text(typed.stdout);(O/'typed-evidence.stderr.log').write_text(typed.stderr)
save(O/'typed-evidence.json',dict(returncode=typed.returncode,command=[sys.executable,'assets/enhanced_cdc_tb/check_typed_evidence.py']))
controls={}; rows=[]
for c in circuits:
 bench=A/'benchmarks'/c;files=[ev.top_rtl_for(c)]
 hits=[f for p in files for f in lint_findings(p.read_text(errors='replace'),str(p.relative_to(A)))]
 status='pass' if not hits else 'checker_control_failure'
 record=dict(circuit=c,status=status,files=[str(p.relative_to(A)) for p in files],findings=hits)
 controls[c]=record;save(O/'golden'/c/'structural-lint.json',record)
 # Canonical validated v2 lint scope: the selected golden top, matching candidate scope.
 cmd=[sys.executable,str(A/'cdc_tb_checks/lint_cdc.py'),'--circuit',c,*map(str,files)]
 p=subprocess.run(cmd,capture_output=True,text=True);(O/'golden'/c/'structural-lint.stdout.log').write_text(p.stdout);(O/'golden'/c/'structural-lint.stderr.log').write_text(p.stderr)
 # Separate golden stage states; tools absent is not a golden design failure.
 save(O/'golden'/c/'stages.json',{s:dict(status='not_run',classification='tool_unavailable',tool='jg' if s=='jasper' else 'xrun') for s in ['compile','functional','enhanced_behavioral_tb','jasper']})
for r in candidates:
 c=r['circuit']; arm=r['arm'];p=B/r['path']; d=O/arm/c;d.mkdir(parents=True,exist_ok=True)
 hits=lint_findings(p.read_text(errors='replace'),r['path']);cmd=[sys.executable,str(A/'cdc_tb_checks/lint_cdc.py'),'--circuit',c,str(p)]
 proc=subprocess.run(cmd,capture_output=True,text=True);(d/'structural-lint.stdout.log').write_text(proc.stdout);(d/'structural-lint.stderr.log').write_text(proc.stderr)
 raw='design_failure' if hits else 'pass'
 lint=raw if controls[c]['status']=='pass' else 'checker_invalid'
 row=dict(**r,compile='tool_unavailable',functional='tool_unavailable',structural_lint=lint,structural_lint_raw=raw,enhanced_behavioral_tb='tool_unavailable',jasper='tool_unavailable',all_five='pending',enhanced_protocol='not_run',jasper_protocol='not_run',lint_findings=hits)
 save(d/'result.json',row);rows.append(row)
save(O/'golden-controls.json',controls);save(O/'results.json',rows)
paired=[]
for c in circuits:
 b=next(r for r in rows if r['arm']=='base' and r['circuit']==c);l=next(r for r in rows if r['arm']=='lora' and r['circuit']==c)
 row=dict(circuit=c,base_candidate_sha256=b['sha256'],lora_candidate_sha256=l['sha256'],base_truncated=b['truncated'],lora_truncated=l['truncated'])
 for s in ['compile','functional','structural_lint','enhanced_behavioral_tb','jasper','all_five','enhanced_protocol','jasper_protocol']:
  row['base_'+s]=b[s];row['lora_'+s]=l[s]
  row[s+'_gain_loss']=('gain' if b[s]=='design_failure' and l[s]=='pass' else 'loss' if b[s]=='pass' and l[s]=='design_failure' else 'tie' if b[s]==l[s] and b[s] in {'pass','design_failure'} else 'pending')
 paired.append(row)
with (O/'paired-results.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(paired[0]));w.writeheader();w.writerows(paired)
summary=dict(denominator_per_arm=44,golden_lint_pass=sum(r['status']=='pass' for r in controls.values()),golden_lint_invalid=[c for c,r in controls.items() if r['status']!='pass'],asset_errors=[r for r in audit if r['errors']],v2_mismatches=[r for r in v2 if not r['matches']],typed_evidence_audit_returncode=typed.returncode,scoring_complete=False,repair_started=False,arms={})
for arm in ['base','lora']:
 rr=[r for r in rows if r['arm']==arm];summary['arms'][arm]={s:{v:sum(r[s]==v for r in rr) for v in sorted({r[s] for r in rr})} for s in ['compile','functional','structural_lint','enhanced_behavioral_tb','jasper','all_five']}
summary['lint_gains']=[r['circuit'] for r in paired if r['structural_lint_gain_loss']=='gain'];summary['lint_losses']=[r['circuit'] for r in paired if r['structural_lint_gain_loss']=='loss']
save(O/'summary.json',summary);print(json.dumps(summary,indent=2))

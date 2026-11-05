"""Validate immutable inputs, candidate artifacts, and paired generation identity."""
from pathlib import Path
import hashlib,json,importlib.util
E=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('frozen_generator',E/'generate.py'); g=importlib.util.module_from_spec(spec);spec.loader.exec_module(g)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
m=json.loads((E/'manifest.json').read_text())
assert sha(E/'generate.py')==m['generator_sha256']
for r in m['circuits']: assert sha(E/r['prompt_path'])==r['prompt_sha256']
for name,h in m['adapter_sha256'].items(): assert sha(E/'adapter'/name)==h
jobs={}; report=dict(expected_per_arm=44,repair_started=False,scoring_status='pending_ecs05_tools_unavailable',arms={},paired_verified=0)
for arm in ['base','lora']:
    circuits,jobs[arm]=g.plan(E/'inputs',E/arm,attempts=1,prompt_types=['cdc_explicit'],adapter=E/'adapter' if arm=='lora' else None)
    assert len(circuits)==44 and len(jobs[arm])==44
    completed=[];missing=[];truncated=[]
    for source,prompt,target,identity in jobs[arm]:
        if g.complete(target,identity):
            assert (target/'prompt.md').read_bytes()==prompt
            meta=json.loads((target/'metadata.json').read_text())
            assert meta['repaired'] is False
            if arm=='lora':
                env=json.loads((E/arm/meta['environment_file']).read_text()); assert env['adapter_status']['loaded'] is True
            completed.append(identity['circuit'])
            if meta['termination_reason']!='eos': truncated.append(identity['circuit'])
        else: missing.append(identity['circuit'])
    report['arms'][arm]=dict(completed=len(completed),missing=missing,max_new_tokens_terminations=truncated,worker_exit_codes={p.name:p.read_text().strip() for p in E.glob('exit-'+arm+'-*.txt')})
for b,l in zip(jobs['base'],jobs['lora']):
    bi=dict(b[3]);li={k:v for k,v in l[3].items() if not k.startswith('adapter_')};assert bi==li
    if g.complete(b[2],b[3]) and g.complete(l[2],l[3]):
        assert (b[2]/'request.txt').read_bytes()==(l[2]/'request.txt').read_bytes()
        report['paired_verified']+=1
report['generation_complete']=report['paired_verified']==44
(E/'generation-report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))

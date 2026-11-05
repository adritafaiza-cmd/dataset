#!/usr/bin/env python3
"""Plan by default. --execute is required to run any real checker/model repairs."""
import argparse,fcntl,json,sys
from pathlib import Path
from cdc_repair.core import chain,read,sha,digest
from cdc_repair.generator import QwenGenerator
from cdc_repair.transport import CommandChecker
ROOT=Path(__file__).resolve().parents[1]
DEFAULT=ROOT/'experiments/frozen-base-lora-cdc-explicit-attempt1-v2'
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--experiment',type=Path,default=DEFAULT);ap.add_argument('--output',type=Path,default=ROOT/'experiments/qwen38-v2-repair-v1');ap.add_argument('--arm',choices=['base','lora'],required=True);ap.add_argument('--circuits',nargs='+');ap.add_argument('--checker-command-json',type=Path);ap.add_argument('--max-repairs',type=int,choices=range(4),default=3);ap.add_argument('--checker-controls-sha256');ap.add_argument('--execute',action='store_true');a=ap.parse_args()
    e=a.experiment.resolve();out=a.output.resolve()
    if out==e or e in out.parents or out in e.parents:ap.error('Repair outputs must be separate from the preserved comparison')
    m=read(e/'manifest.json');inventory=read(e/'scoring/bundle/candidate-hashes.json')['candidates'];manifest_sha=sha(e/'manifest.json')
    wanted=set(a.circuits) if a.circuits else {r['circuit'] for r in m['circuits']}
    known={r['circuit'] for r in m['circuits']}
    if not wanted<=known:ap.error('Unknown circuit selection')
    if len(known)!=44:raise ValueError('Expected 44-circuit frozen experiment')
    code={p.name:sha(p) for p in (ROOT/'scripts/cdc_repair').glob('*.py')};code['entrypoint']=sha(Path(__file__))
    command=read(a.checker_command_json) if a.checker_command_json else None
    if command is not None and (not isinstance(command,list) or not command or not all(isinstance(x,str) for x in command)):ap.error('Checker command JSON must contain a nonempty argv array')
    plan=[]
    for r in m['circuits']:
        if r['circuit'] not in wanted:continue
        c=r['circuit'];source=e/a.arm/c/'cdc_explicit/attempt-001';meta=read(source/'metadata.json');expected=next(x for x in inventory if x['arm']==a.arm and x['circuit']==c)
        candidate=source/'generated'/f'{c}.sv';spec=e/r['prompt_path']
        if sha(candidate)!=expected['sha256'] or sha(spec)!=r['prompt_sha256']:raise ValueError('Frozen source changed')
        if sha(source/'complete.json')!=expected['source_completion_sha256']:raise ValueError('Frozen completion record changed')
        for rel,h in read(source/'complete.json')['sha256'].items():
            if sha(source/rel)!=h:raise ValueError('Frozen generation artifact changed')
        plan.append((c,candidate,spec,meta,expected))
    for name,h in m['adapter_sha256'].items():
        if sha(e/'adapter'/name)!=h:raise ValueError('Frozen adapter changed')
    print(json.dumps({'mode':'execution_requested' if a.execute else 'plan_only_no_checks_or_generation','arm':a.arm,'initial_candidates':len(plan),'max_repairs_per_candidate':a.max_repairs,'max_new_generations':len(plan)*a.max_repairs,'source_commit':m['source_commit'],'stages':['ports','compile','functional','structural_lint','enhanced'],'jasper':'final_grader_only','checker_command':command},indent=2),flush=True)
    if not a.execute:return
    if command is None:ap.error('--execute requires --checker-command-json')
    if not a.checker_controls_sha256 or len(a.checker_controls_sha256)!=64:ap.error('--execute requires the SHA256 of fresh sealed golden controls')
    checker=CommandChecker(command);generator=QwenGenerator(e,a.arm)
    for c,candidate,spec,meta,expected in plan:
        target=out/a.arm/c;target.mkdir(parents=True,exist_ok=True)
        identity=dict(initial_source_path=str(candidate.parent.parent),initial_completion_sha256=sha(candidate.parent.parent/'complete.json'),evaluation_manifest_sha256=sha(e/'scoring/bundle/evaluation-asset-hashes.json'),checker_controls_sha256=a.checker_controls_sha256,mode='real_repair',arm=a.arm,circuit=c,experiment_manifest_sha256=manifest_sha,code_sha256=code,checker_command=command,initial_truncated=expected['truncated'],model_settings=m['settings'],model_revision=m['model_revision'],adapter_sha256=m['adapter_sha256'] if a.arm=='lora' else None)
        with (target/'.lock').open('a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
            initial_artifacts={name:(candidate.parent.parent/name).read_bytes() for name in ['request.txt','response.txt','response.json','metadata.json','prompt.md','complete.json']}
            result=chain(target,candidate.read_bytes(),spec.read_bytes(),identity,checker,generator,a.max_repairs,initial_artifacts)
        print(c,json.dumps(result),flush=True)
        if result['status']=='infrastructure_blocked':raise SystemExit('Infrastructure blocked: no further model generation was attempted.')
if __name__=='__main__':main()

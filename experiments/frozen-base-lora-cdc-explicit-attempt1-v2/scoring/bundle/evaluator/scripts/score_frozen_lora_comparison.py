#!/usr/bin/env python3
"""Score the sealed 44-pair slice without generation or model feedback."""
import argparse
import hashlib
import json
import os
import re
import sys
import time
from collections import Counter
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT/'scripts'), str(ROOT/'enhanced_cdc_tb'), str(ROOT/'cdc_tb_checks')]
from evaluate_generated import evaluate, top_rtl_for
from evaluate_pass_at_n import simulate, XRUN_BIN, JG_BIN
from run_enhanced import run_one as enhanced
import run_jasper_full_cdc as jasper_impl
jasper_impl.EXTRA_TCL = ""
jasper = jasper_impl.run_one
from lint_cdc import lint_findings
OUT = ROOT/'experiments/frozen-base-lora-cdc-explicit-attempt1-v1-scored'
TREES = {'base':'qwen38-27b-3prompt-10attempt-v1', 'lora':'qwen38-27b-lora-audited-cdc-explicit-attempt1-v1'}
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p, value):
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp=p.with_suffix('.tmp'); tmp.write_text(json.dumps(value,indent=2)+'\n'); tmp.replace(p)
def classify(ok, text):
    if re.search(r'license.*(?:fail|unavailable|not available)|unable to.*license|cannot.*license|LMF-|command not found|Permission denied|error while loading shared libraries',text,re.I): return 'TOOL_ERROR'
    if re.search(r'WALL_TIMEOUT|xrun timeout|jg_rc=124',text,re.I): return 'TIMEOUT'
    return 'PASS' if ok else 'FAIL'
def run(item):
    arm,c,rtl=item; start=time.time(); dest=OUT/arm/c; dest.mkdir(parents=True,exist_ok=True)
    source=dest/rtl.name
    raw=rtl.read_text(errors='replace'); normalized=re.sub(r'^\s*```[a-zA-Z0-9_-]*\s*\n|\n```\s*$','',raw,flags=re.M).strip()+'\n'; source.write_text(normalized)
    rec={'arm':arm,'circuit':c,'rtl':str(rtl.relative_to(ROOT)),'rtl_sha256':sha(rtl),'normalized_markdown_fence':raw!=normalized,'stages':{}}
    prior=dest/'result.json'
    if prior.is_file():
        old=json.loads(prior.read_text())
        assert old['rtl_sha256']==rec['rtl_sha256'], 'Changed candidate on resume'
        rec['stages']=old['stages']
        if old.get('jasper_mode')!='fixed_structural_only': rec['stages'].pop('jasper',None)
    rec['jasper_mode']='fixed_structural_only'
    def stage(name, call, parse):
        if name in rec['stages'] and rec['stages'][name]['status'] not in ['TOOL_ERROR','TIMEOUT']: return
        t=time.time()
        try:
            data=call(); status=parse(data)
            texts=[]
            for key in ['log','sim_log','jasper_log']:
                if data.get(key):
                    p=Path(data[key]); p=p if p.is_absolute() else ROOT/p
                    if p.is_file(): texts.append(p.read_text(errors='replace'))
            status=classify(status=='PASS', '\n'.join(texts)+json.dumps(data)) if status in ('PASS','FAIL') else status
            rec['stages'][name]={'status':status,'seconds':time.time()-t,'details':data}
        except Exception as e: rec['stages'][name]={'status':'TOOL_ERROR','seconds':time.time()-t,'error':f'{type(e).__name__}: {e}'}
        save(dest/'result.json',rec)
    stage('structural_lint',lambda:{'findings':lint_findings(normalized,str(rtl))},lambda d:'FAIL' if d['findings'] else 'PASS')
    stage('compile',lambda:evaluate(source,c,dest),lambda d:'PASS' if d['compile_ok'] else 'FAIL')
    stage('functional',lambda:simulate(source,c,dest),lambda d:'PASS' if d['simulate_ok'] else 'FAIL')
    stage('enhanced',lambda:enhanced({'source':'frozen-scored-'+arm,'circuit':c,'prompt':'cdc_explicit','attempt':'attempt-001','rtl':source}),lambda d:'UNSUPPORTED' if d['status']=='SKIP' else d['status'])
    def jstatus(d):
        if d.get('jg_returncode') in (124,137): return 'TIMEOUT'
        if not d.get('jasper_report'):
            log=(ROOT/d['jasper_log']).read_text(errors='replace') if d.get('jasper_log') else ''
            return 'FAIL' if d.get('elab_fail') or re.search(r'\[ERROR \(VERI-|errors detected in the design',log) else 'TOOL_ERROR'
        return 'PASS' if d.get('cdc_clean') else 'FAIL'
    stage('jasper',lambda:jasper({'kind':'generated','source':'frozen-structural-'+arm,'circuit':c,'prompt':'cdc_explicit','attempt':'attempt-001','rtl':str(source.relative_to(ROOT))}),jstatus)
    rec['seconds']=time.time()-start; rec['complete']=True
    if sha(rtl)!=rec['rtl_sha256']: raise RuntimeError('Candidate changed during scoring')
    save(dest/'result.json',rec)
    return rec

def summarize():
    rows=[json.loads(p.read_text()) for p in OUT.glob('*/*/result.json')]
    stages=['compile','functional','structural_lint','enhanced','jasper']; report={'denominator_per_arm':44,'checks_run_independently':True,'results':rows,'summary':{},'paired':{}}
    for arm in ['base','lora','golden']:
        rr=[r for r in rows if r['arm']==arm]
        report['summary'][arm]={'completed':sum(r.get('complete',False) for r in rr),'stages':{s:dict(Counter(r['stages'].get(s,{}).get('status','PENDING') for r in rr)) for s in stages},'functional_and_all_cdc_pass':sum(all(r['stages'].get(s,{}).get('status')=='PASS' for s in ['functional','structural_lint','enhanced','jasper']) for r in rr)}
    by={(r['arm'],r['circuit']):r for r in rows}
    for s in stages:
        pairs=[]
        for c in sorted({r['circuit'] for r in rows}):
            if ('base',c) in by and ('lora',c) in by:
                a=by['base',c]['stages'].get(s,{}).get('status','PENDING'); b=by['lora',c]['stages'].get(s,{}).get('status','PENDING')
                pairs.append({'circuit':c,'base':a,'lora':b})
        report['paired'][s]={'improved':[p['circuit'] for p in pairs if p['base']=='FAIL' and p['lora']=='PASS'],'regressed':[p['circuit'] for p in pairs if p['base']=='PASS' and p['lora']=='FAIL'],'pairs':pairs}
    save(OUT/'results.json',report)
    return report

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--workers',type=int,default=2); ap.add_argument('--circuit',action='append'); args=ap.parse_args()
    os.environ['PATH']=XRUN_BIN+':'+JG_BIN+':'+os.environ.get('PATH',''); os.environ['CDC_CHECKS']='0'
    circuits=sorted(p.parent.name for p in (ROOT/'benchmarks').glob('*/manifest.yaml'))
    assert len(circuits)==44
    items=[]
    for c in circuits:
        if args.circuit and c not in args.circuit: continue
        for arm,tree in TREES.items():
            p=ROOT/'experiments'/tree/c/'cdc_explicit/attempt-001'; marker=json.loads((p/'complete.json').read_text())
            for name,digest in marker['sha256'].items(): assert sha(p/name)==digest,(arm,c,name)
            items.append((arm,c,p/'generated'/f'{c}.sv'))
        items.append(('golden',c,top_rtl_for(c)))
    inputs={str(p.relative_to(ROOT)):sha(p) for _,_,p in items}
    assets=[p for folder in ['benchmarks','enhanced_cdc_tb','cdc_tb_checks'] for p in (ROOT/folder).rglob('*') if p.is_file() and p.suffix in {'.v','.sv','.tcl','.sdc','.yaml','.py','.sh','.md'}]
    assets_hashes={str(p.relative_to(ROOT)):sha(p) for p in assets}
    if (OUT/'frozen-inputs.json').is_file():
        previous=json.loads((OUT/'frozen-inputs.json').read_text())
        assert previous['evaluation_assets']==assets_hashes, 'Evaluation assets changed on resume'
        assert all(inputs.get(k,v)==v for k,v in previous['candidates'].items()), 'Candidate changed on resume'
    save(OUT/'frozen-inputs.json',{'candidates':inputs,'evaluation_assets':assets_hashes,'jasper_mode':'fixed_structural_only','checker_code_sha256':{str(p.relative_to(ROOT)):sha(p) for p in [Path(__file__),ROOT/'scripts/evaluate_generated.py',ROOT/'scripts/evaluate_pass_at_n.py',ROOT/'scripts/run_jasper_full_cdc.py',ROOT/'enhanced_cdc_tb/run_enhanced.py']},'policy':'Identical assets; independent checks; no generation or feedback; fixed RTL helper dependencies retained by existing benchmark scripts.'})
    pending=[i for i in items if not (OUT/i[0]/i[1]/'result.json').is_file() or not json.loads((OUT/i[0]/i[1]/'result.json').read_text()).get('complete') or json.loads((OUT/i[0]/i[1]/'result.json').read_text()).get('jasper_mode')!='fixed_structural_only']
    print(f'Candidates including golden controls: {len(items)}; pending: {len(pending)}',flush=True)
    with ProcessPoolExecutor(max_workers=args.workers) as pool:
        futures={pool.submit(run,i):i for i in pending}
        for f in as_completed(futures):
            r=f.result(); print(r['arm'],r['circuit'],{s:d['status'] for s,d in r['stages'].items()},flush=True); summarize()
    frozen=json.loads((OUT/'frozen-inputs.json').read_text())
    changes=[str(p.relative_to(ROOT)) for p in assets if sha(p)!=frozen['evaluation_assets'][str(p.relative_to(ROOT))]]
    assert not changes,changes
    print(json.dumps(summarize()['summary'],indent=2),flush=True)
if __name__=='__main__': main()

#!/usr/bin/env python3
"""Validate revised golden references; no model generation or feedback."""
import argparse,json,os,subprocess,sys,time
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor,as_completed
ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/'scripts'),str(ROOT/'enhanced_cdc_tb'),str(ROOT/'cdc_tb_checks')]
from evaluate_generated import evaluate,top_rtl_for
from evaluate_pass_at_n import simulate,XRUN_BIN,JG_BIN
from run_enhanced import run_one as enhanced
from lint_cdc import lint_findings
import run_jasper_full_cdc as j
j.EXTRA_TCL=''
OUT=ROOT/'experiments/golden-validation-v2'
def save(p,d):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(d,indent=2)+'\n')
def run(c,checks,parameters=None,formal_tasks=None):
 suffix=''.join('-'+k+str(v) for k,v in sorted((parameters or {}).items()))
 dest=Path(str(OUT)+suffix)/c;dest.mkdir(parents=True,exist_ok=True);rtl=top_rtl_for(c);r={'circuit':c,'stages':{}}
 prior=dest/'result.json'
 if prior.is_file(): r=json.loads(prior.read_text());r.pop('complete',None)
 for name in checks:
  start=time.time()
  try:
   if name=='lint': d={'findings':lint_findings(rtl.read_text(),str(rtl))};status='PASS' if not d['findings'] else 'FAIL'
   elif name=='compile': d=evaluate(rtl,c,dest);status='PASS' if d['compile_ok'] else 'FAIL'
   elif name=='functional': d=simulate(rtl,c,dest);status='PASS' if d['simulate_ok'] else 'FAIL'
   elif name=='enhanced': d=enhanced({'source':'v2-golden','circuit':c,'prompt':'golden','attempt':'fixed','rtl':rtl});status=d['status']
   elif name=='jasper':
    d=j.run_one({'kind':'golden','source':'v2-golden'+suffix,'circuit':c,'prompt':'golden','attempt':'fixed','rtl':str(rtl.relative_to(ROOT)),'parameters':parameters or {}});status='PASS' if d.get('cdc_clean') and d.get('jg_returncode')==0 else 'FAIL'
   elif name=='formal':
    work=ROOT/'build/formal-v2'/c;work.mkdir(parents=True,exist_ok=True)
    d=dict(r['stages'].get('formal',{}).get('details',{}))
    for task in (formal_tasks or ['prove','cover']):
     log=work/(task+'.log');p=subprocess.run(['timeout','--kill-after=10s','600s',str(Path.home()/'tools/oss-cad-suite/bin/sby'),'-f','-d',str(work/task),'golden.sby',task],cwd=ROOT/'formal'/c,capture_output=True,text=True);log.write_text(p.stdout+p.stderr);d[task]={'returncode':p.returncode,'pass':(work/task/'PASS').is_file(),'log':str(log.relative_to(ROOT))}
    status='PASS' if all(x['pass'] for x in d.values()) else 'FAIL'
   r['stages'][name]={'status':status,'seconds':time.time()-start,'details':d}
  except Exception as e:r['stages'][name]={'status':'ERROR','error':f'{type(e).__name__}: {e}'}
  save(dest/'result.json',r)
 r['complete']=True;save(dest/'result.json',r);return r

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--circuits',nargs='+');ap.add_argument('--checks',nargs='+',default=['lint','compile','functional','enhanced','jasper','formal']);ap.add_argument('--workers',type=int,default=2);ap.add_argument('--parameter',action='append',default=[]);ap.add_argument('--formal-task',choices=['prove','cover'],action='append');a=ap.parse_args()
 os.environ['PATH']=XRUN_BIN+':'+JG_BIN+':'+str(Path.home()/'tools/oss-cad-suite/bin')+':'+os.environ.get('PATH','');os.environ['CDC_CHECKS']='0'
 cc=a.circuits or sorted(p.parent.name for p in (ROOT/'benchmarks').glob('*/manifest.yaml'))
 with ProcessPoolExecutor(max_workers=a.workers) as p:
  for f in as_completed([p.submit(run,c,a.checks,dict(v.split('=',1) for v in a.parameter),a.formal_task) for c in cc]):
   r=f.result();print(r['circuit'],{k:v['status'] for k,v in r['stages'].items()},flush=True)
if __name__=='__main__':main()

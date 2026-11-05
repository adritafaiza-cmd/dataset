"""JSON-stdin checker service for a fresh isolated ecs05 workspace; no Jasper calls."""
from __future__ import annotations
import argparse,base64,fcntl,importlib,json,os,re,shutil,subprocess,sys,time,uuid
from pathlib import Path
from .core import STAGES,digest,read,save,sha,short
from .ports import compare,simulation_options

def classify(ok,text,data):
    if re.search(r'license.*(?:fail|unavailable|not available)|unable to.*license|cannot.*license|LMF-',text,re.I):return 'license_failure'
    if any(data.get(k) in (124,137) for k in ('returncode','sim_returncode')) or re.search(r'WALL_TIMEOUT|xrun timeout|\bTIMEOUT\b',text+' '+str(data.get('note','')),re.I):return 'timeout'
    if re.search(r'command not found|error while loading shared libraries|segmentation fault|internal (?:error|exception)|Permission denied',text,re.I):return 'tool_error'
    if re.search(r'cannot open include file|cannot (?:open|find).*file|No such file or directory',text,re.I):return 'missing_assets'
    if data.get('status')=='SKIP':return 'missing_assets'
    if ok:return 'pass'
    if re.search(r'VIOLATION|TESTS FAILED|ENHANCED FAIL|\*(?:E|F),',text,re.I) or data.get('findings'):return 'design_failure'
    return 'inconclusive'

def diagnostic(stage,text,data):
    if stage=='structural_lint' and data.get('findings'):
        f=data['findings'][0];return short(stage,f"{f['rule_id']}: {f['message']}")
    # Whitelist one diagnostic line, never whole tool logs or source dumps.
    for line in text.splitlines():
        if '$display' in line or '$finish' in line:continue
        if re.search(r'VIOLATION\s*\[|TESTS FAILED|ENHANCED FAIL|(?:xmvlog|xmelab): \*[EF],',line):
            line=re.sub(r'/[^\s,()]+','<path>',line)
            return short(stage,line)
    return short(stage,'check failed; inspect saved checker logs')

def setup(assets,manifest,workspace):
    assets=assets.resolve();workspace=workspace.resolve()
    if assets==workspace or assets in workspace.parents or workspace in assets.parents:raise ValueError('Checker workspace must be outside the sealed evaluator')
    records=read(manifest)['assets'];root=workspace/'evaluator';root.mkdir(parents=True,exist_ok=True)
    with (workspace/'.assets.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        for row in records:
            source=assets/row['path'];dest=root/row['path']
            if sha(source)!=row['sha256']:raise ValueError('Evaluation source hash mismatch: '+row['path'])
            if dest.exists():
                if sha(dest)!=row['sha256']:raise ValueError('Checker workspace asset changed: '+row['path'])
            else:dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
    sys.path[:0]=[str(root/'scripts'),str(root/'enhanced_cdc_tb'),str(root/'cdc_tb_checks')]
    ev=importlib.import_module('evaluate_generated');base=importlib.import_module('evaluate_pass_at_n');en=importlib.import_module('run_enhanced');lint=importlib.import_module('lint_cdc')
    os.environ['PATH']=base.XRUN_BIN+':'+os.environ.get('PATH','');os.environ['CDC_CHECKS']='0'
    return root,ev,base,en,lint

def check(request,assets,manifest,workspace,controls):
    candidate=request['candidate'].encode('utf-8');candidate_sha=digest(candidate)
    if candidate_sha!=request['candidate_sha256']:raise ValueError('Transferred candidate hash mismatch')
    if request.get('evaluation_manifest_sha256')!=sha(manifest) or request.get('controls_sha256')!=sha(controls):raise ValueError('Requested asset/control identity differs from checker')
    root,ev,base,en,lint=setup(assets,manifest,workspace);c=request['circuit']
    if not re.fullmatch(r'[A-Za-z0-9_]+',c):raise ValueError('Invalid circuit identifier')
    if not (root/'benchmarks'/c/'manifest.yaml').is_file():raise FileNotFoundError('Unknown circuit')
    session=uuid.uuid4().hex;dest=root/'experiments/repair-checks'/session;dest.mkdir(parents=True)
    rtl=dest/'candidate.sv';rtl.write_bytes(candidate);save(dest/'request.json',request)
    stages={s:{'status':'not_run','runtime_seconds':0.0} for s in STAGES};result=dict(evaluation_manifest_sha256=sha(manifest),controls_sha256=sha(controls),candidate_sha256=candidate_sha,stages=stages,status='pass',diagnostic='',earliest_stage=None)
    control=read(controls)
    if control['evaluation_manifest_sha256']!=sha(manifest):raise ValueError('Golden-control evaluation identity mismatch')
    for stage in STAGES:
        start=time.monotonic();stage_dir=dest/stage;stage_dir.mkdir();calls=[];texts=[];original_run=subprocess.run
        def logged_run(*args,**kw):
            n=len(calls);argv=args[0] if args else kw['args'];calls.append({'argv':list(map(str,argv)),'cwd':str(kw.get('cwd',root))});save(stage_dir/'commands.json',calls);kw.setdefault('timeout',180)
            try:p=original_run(*args,**kw)
            except subprocess.TimeoutExpired as exc:
                for suffix,data in [('stdout',exc.stdout),('stderr',exc.stderr)]:
                    (stage_dir/f'{n}.{suffix}.log').write_text(data.decode(errors='replace') if isinstance(data,bytes) else data or '')
                raise
            for suffix,data in [('stdout',p.stdout),('stderr',p.stderr)]:
                value=data.decode(errors='replace') if isinstance(data,bytes) else data or '';(stage_dir/f'{n}.{suffix}.log').write_text(value);texts.append(value)
            calls[-1]['returncode']=p.returncode;save(stage_dir/'commands.json',calls);return p
        subprocess.run=logged_run
        try:
            if stage=='ports':
                reference=ev.top_rtl_for(c);sim=(root/'benchmarks'/c/ev.manifest_scalar(c,'simulation')).read_text()
                includes,defines=simulation_options(sim,root,root/'benchmarks'/c,reference.parent)
                data=compare(reference.read_text(),candidate.decode('utf-8'),ev.manifest_scalar(c,'top_module'),includes,includes,defines);status=data['status']
            elif control.get('golden',{}).get(c,{}).get(stage)!='pass':
                data={'reason':'Fresh matching golden control did not pass'};status='checker_invalid'
            elif stage in ('compile','functional','enhanced') and not shutil.which('xrun'):
                data={'reason':'xrun unavailable'};status='tool_unavailable'
            else:
                if stage=='compile':data=ev.evaluate(rtl,c,dest);ok=data['compile_ok']
                elif stage=='functional':data=base.simulate(rtl,c,dest);ok=data['simulate_ok']
                elif stage=='structural_lint':data={'findings':lint.lint_findings(candidate.decode('utf-8'),str(rtl))};ok=not data['findings']
                else:data=en.run_one({'source':'repair-'+session,'circuit':c,'prompt':'check','attempt':'current','rtl':rtl});ok=data['status']=='PASS'
                for key in ('log','sim_log'):
                    if data.get(key):
                        p=Path(data[key]);p=p if p.is_absolute() else root/p
                        if p.is_file():texts.append(p.read_text(errors='replace'))
                runtime=en.runtime_text('\n'.join(texts));status=classify(ok,runtime,data)
            runtime=en.runtime_text('\n'.join(texts));record={'status':status,'details':data}
            if stage=='enhanced':
                record['protocol_failures']=re.findall(r'^.*PROTOCOL VIOLATION\s+\[[^\]]+\].*$',runtime,re.M)
                record['cdc_reset_evidence']=re.findall(r'^.*CDC(?:/RESET)? VIOLATION\s+\[[^\]]+\].*$',runtime,re.M)
            feedback=short(stage,data.get('diagnostic','')) if stage=='ports' else diagnostic(stage,runtime,data)
        except subprocess.TimeoutExpired as exc:record={'status':'timeout','error':str(exc)};feedback=''
        except FileNotFoundError as exc:record={'status':'missing_assets','error':str(exc)};feedback=''
        except Exception as exc:record={'status':'tool_error','error':f'{type(exc).__name__}: {exc}'};feedback=''
        finally:subprocess.run=original_run
        record['runtime_seconds']=time.monotonic()-start;stages[stage]=record;save(stage_dir/'stage.json',record)
        if record['status']!='pass':
            result.update(status=record['status'],earliest_stage=stage,diagnostic=feedback if record['status']=='design_failure' else '');break
    if sha(rtl)!=candidate_sha:raise ValueError('Candidate changed during checking')
    save(dest/'result.json',result)
    # Return full text evidence to HPC, preserving per-request paths. Source RTL
    # references in these files remain evaluation artifacts, never prompt fields.
    artifacts={}
    paths=[dest,root/'build/eval'/dest.relative_to(root/'experiments'),root/'build/enhanced_cdc_tb'/('repair-'+session)]
    for directory in paths:
        if directory.exists():
            for p in directory.rglob('*'):
                if p.is_file() and p.suffix in {'.log','.rpt','.json','.tcl','.sh','.txt','.csv'} and 'xcelium' not in p.parts:
                    raw=p.read_bytes();artifacts[str(p.relative_to(root))]={'encoding':'base64','sha256':digest(raw),'data':base64.b64encode(raw).decode('ascii')}
    result['artifacts']=artifacts;return result

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--assets',type=Path,required=True);ap.add_argument('--manifest',type=Path,required=True);ap.add_argument('--workspace',type=Path,required=True);ap.add_argument('--controls',type=Path,required=True);a=ap.parse_args()
    request=json.load(sys.stdin)
    try:result=check(request,a.assets,a.manifest,a.workspace,a.controls)
    except Exception as exc:
        result=dict(evaluation_manifest_sha256=sha(a.manifest) if a.manifest.is_file() else None,controls_sha256=sha(a.controls) if a.controls.is_file() else None,candidate_sha256=request.get('candidate_sha256'),status='tool_error',earliest_stage='ports',diagnostic='',error=f'{type(exc).__name__}: {exc}',stages={s:{'status':'tool_error' if s=='ports' else 'not_run'} for s in STAGES})
    print(json.dumps(result))
if __name__=='__main__':main()

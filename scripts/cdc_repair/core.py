from __future__ import annotations
import hashlib,json,os,time,uuid
from pathlib import Path
STAGES=('ports','compile','functional','structural_lint','enhanced')
INFRA={'tool_unavailable','missing_assets','license_failure','timeout','tool_error','transport_error','checker_invalid','inconclusive','generation_error'}
def digest(data:bytes)->str:return hashlib.sha256(data).hexdigest()
def sha(path):return digest(Path(path).read_bytes())
def save(path,value):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    tmp=path.with_name(path.name+'.'+uuid.uuid4().hex+'.tmp');tmp.write_text(json.dumps(value,indent=2,sort_keys=True)+'\n');os.replace(tmp,path)
def read(path):return json.loads(Path(path).read_text())
def write_once(path,data):
    path=Path(path);data=data.encode() if isinstance(data,str) else data
    if path.exists():
        if path.read_bytes()!=data:raise ValueError(f'Immutable artifact changed: {path}')
    else:path.write_bytes(data)
def seal(directory,marker='complete.json',identity=None):
    directory=Path(directory)
    hashes={str(p.relative_to(directory)):sha(p) for p in directory.rglob('*') if p.is_file() and p.name!=marker and not p.name.endswith('.tmp')}
    save(directory/marker,{'identity':identity,'sha256':hashes})
def verify(directory,marker='complete.json',identity=None):
    directory=Path(directory);p=directory/marker
    if not p.is_file():return False
    r=read(p)
    if identity is not None and r['identity']!=identity:raise ValueError('Resume configuration changed')
    for rel,h in r['sha256'].items():
        if sha(directory/rel)!=h:raise ValueError(f'Hash mismatch: {directory/rel}')
    return True
def short(stage,text):
    # Checkers supply one small diagnostic, never native logs/source dumps.
    text=' '.join(str(text).split())[:900]
    return f'{stage}: {text or "check failed; see saved checker logs"}'
def validate_check(result,candidate_sha):
    if result.get('candidate_sha256')!=candidate_sha:raise ValueError('Checker candidate hash mismatch')
    if set(result.get('stages',{}))!=set(STAGES):raise ValueError('Checker stage set mismatch')
    first=None
    for stage in STAGES:
        r=result['stages'][stage];status=r.get('status')
        if first is not None:
            if status!='not_run':raise ValueError('Checker ran past earliest failure')
        elif status=='pass':continue
        elif status=='design_failure' or status in INFRA:first=(stage,status)
        else:raise ValueError('Invalid/missing checker stage outcome')
    if first is None:
        if result.get('status')!='pass' or result.get('diagnostic',''):raise ValueError('Invalid all-pass result')
    elif result.get('status')!=first[1] or result.get('earliest_stage')!=first[0]:raise ValueError('Invalid earliest-stage result')
    if first and first[1]=='design_failure' and not result.get('diagnostic','').startswith(first[0]+': '):raise ValueError('Missing earliest-stage diagnostic')
    if first and first[1] in INFRA and result.get('diagnostic',''):raise ValueError('Infrastructure diagnostic must not enter a repair prompt')
    if len(result.get('diagnostic',''))>1000:raise ValueError('Diagnostic too long')
    return result

def prompt(spec,candidate,diagnostic):
    return ('Repair the current RTL to satisfy the original specification and the diagnostic.\n'
            'Return the complete replacement RTL in one source file, without explanation or Markdown.\n\n'
            '<original_specification>\n'+spec+'\n</original_specification>\n\n'
            '<current_candidate>\n'+candidate+'\n</current_candidate>\n\n'
            '<earliest_failure>\n'+diagnostic+'\n</earliest_failure>\n')

def chain(root,source,spec,identity,checker,generator,max_repairs=3,initial_artifacts=None):
    """Four candidates at most: immutable initial candidate plus three repairs."""
    if not 0<=max_repairs<=3:raise ValueError('At most three repairs are allowed')
    root=Path(root);root.mkdir(parents=True,exist_ok=True)
    identity=dict(identity,spec_sha256=digest(spec),initial_sha256=digest(source),max_repairs=max_repairs)
    config=root/'identity.json'
    if config.exists():
        if read(config)!=identity:raise ValueError('Resume identity changed')
    else:save(config,identity)
    initial=root/'candidate-000';initial.mkdir(exist_ok=True)
    write_once(initial/'candidate.sv',source);write_once(initial/'spec.md',spec)
    if initial_artifacts:
        archive=initial/'source-artifacts';archive.mkdir(exist_ok=True)
        for name,data in initial_artifacts.items():
            if Path(name).name!=name:raise ValueError('Invalid source artifact name')
            write_once(archive/name,data)
    if not (initial/'generation.json').exists():save(initial/'generation.json',{'source':'saved_v2_initial','generated':False,'sha256':digest(source),'truncation':identity.get('initial_truncated',False)})
    if not verify(initial,'candidate-complete.json'):seal(initial,'candidate-complete.json',identity)
    current=initial
    for index in range(max_repairs+1):
        if not verify(current,'candidate-complete.json'):raise ValueError('Incomplete candidate transaction')
        candidate=(current/'candidate.sv').read_bytes();candidate_sha=digest(candidate)
        checks=current/'checks';checks.mkdir(exist_ok=True);result=None
        for old in sorted(checks.glob('attempt-*')):
            if verify(old):
                checked=validate_check(read(old/'result.json'),candidate_sha)
                if checked['status'] in {'pass','design_failure'}:result=checked;break
        if result is None:
            attempt=checks/f'attempt-{len(list(checks.glob("attempt-*")))+1:04d}';attempt.mkdir()
            start=time.monotonic()
            try:result=validate_check(checker(candidate,identity,attempt),candidate_sha)
            except Exception as exc:
                result=dict(status='transport_error',earliest_stage='ports',diagnostic='',candidate_sha256=candidate_sha,stages={s:{'status':'transport_error' if s=='ports' else 'not_run'} for s in STAGES},error=f'{type(exc).__name__}: {exc}')
            result['runtime_seconds']=time.monotonic()-start
            save(attempt/'result.json',result);seal(attempt)
        feedback=result.get('diagnostic','') if result['status']=='design_failure' else ''
        if result['status'] in {'pass','design_failure'}:write_once(current/'feedback.txt',feedback)
        state=dict(repairs_completed=index,current_candidate_sha256=candidate_sha,check_status=result['status'],earliest_stage=result.get('earliest_stage'),jasper='final_grader_not_run',experiment_results=identity.get('mode')!='runner_test')
        if result['status']=='pass':state['status']='all_repair_checks_passed';save(root/'status.json',state);return state
        if result['status']!='design_failure':state['status']='infrastructure_blocked';save(root/'status.json',state);return state
        if index==max_repairs:state['status']='repair_limit_reached';save(root/'status.json',state);return state
        target=root/f'candidate-{index+1:03d}';target.mkdir(exist_ok=True)
        generation_identity=dict(parent_sha256=candidate_sha,spec_sha256=digest(spec),feedback_sha256=digest(feedback.encode()),repair_number=index+1,run_identity=identity)
        if not verify(target,'candidate-complete.json',generation_identity):
            write_once(target/'spec.md',spec);write_once(target/'feedback_input.txt',feedback)
            user_prompt=prompt(spec.decode('utf-8'),candidate.decode('utf-8'),feedback)
            write_once(target/'user-prompt.txt',user_prompt)
            start=time.monotonic()
            try:
                # The generator implements a separate durable receipt: resume after
                # model completion but before the outer candidate transaction commits.
                generated=generator(user_prompt,target,generation_identity)
                write_once(target/'candidate.sv',generated)
                save(target/'generation.json',{'runtime_seconds':time.monotonic()-start,'identity':generation_identity,'sha256':digest(generated)})
                seal(target,'candidate-complete.json',generation_identity)
            except Exception as exc:
                save(target/f'generation-error-{uuid.uuid4().hex}.json',{'status':'generation_error','error':f'{type(exc).__name__}: {exc}'})
                state.update(status='infrastructure_blocked',check_status='generation_error');save(root/'status.json',state);return state
        current=target

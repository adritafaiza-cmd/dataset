import base64,json,subprocess,time
from .core import STAGES,digest,save,short
class CommandChecker:
    """Local or SSH argv; exact JSON over stdin/stdout, no shell interpolation."""
    def __init__(self,command,timeout=900):self.command=command;self.timeout=timeout
    def __call__(self,candidate,identity,dest):
        request={'schema_version':1,'circuit':identity['circuit'],'candidate':candidate.decode('utf-8'),'candidate_sha256':digest(candidate),'evaluation_manifest_sha256':identity.get('evaluation_manifest_sha256'),'controls_sha256':identity.get('checker_controls_sha256')}
        save(dest/'request.json',request);save(dest/'command.json',{'argv':self.command,'timeout_seconds':self.timeout})
        start=time.monotonic()
        try:
            p=subprocess.run(self.command,input=json.dumps(request),text=True,capture_output=True,timeout=self.timeout)
            (dest/'stdout.log').write_text(p.stdout);(dest/'stderr.log').write_text(p.stderr);save(dest/'exit.json',{'returncode':p.returncode})
            if p.returncode:raise RuntimeError(f'checker transport exit {p.returncode}; see saved stderr')
            result=json.loads(p.stdout)
            if result.get('evaluation_manifest_sha256')!=identity.get('evaluation_manifest_sha256') or result.get('controls_sha256')!=identity.get('checker_controls_sha256'):raise ValueError('Checker asset/control attestation mismatch')
            # Persist checker outputs separately. They are never model inputs.
            artifacts=result.pop('artifacts',{})
            for name,text in artifacts.items():
                from pathlib import PurePosixPath
                path=PurePosixPath(name)
                if path.is_absolute() or '..' in path.parts:raise ValueError('unsafe checker artifact path')
                target=dest/'checker-artifacts'/str(path);target.parent.mkdir(parents=True,exist_ok=True)
                if isinstance(text,dict):
                    if text.get('encoding')!='base64':raise ValueError('Unknown artifact encoding')
                    raw=base64.b64decode(text['data'],validate=True)
                    if digest(raw)!=text['sha256']:raise ValueError('Checker artifact hash mismatch')
                    target.write_bytes(raw)
                else:target.write_text(text)  # Plain text is accepted for simulated runner tests.
            return result
        except subprocess.TimeoutExpired as exc:
            for name,text in [('stdout',exc.stdout),('stderr',exc.stderr)]:
                (dest/(name+'.log')).write_text(text.decode(errors='replace') if isinstance(text,bytes) else text or '')
            status='timeout';error=str(exc)
        except Exception as exc:status='transport_error';error=f'{type(exc).__name__}: {exc}'
        finally:save(dest/'transport-runtime.json',{'seconds':time.monotonic()-start})
        return dict(status=status,earliest_stage='ports',diagnostic='',candidate_sha256=digest(candidate),error=error,stages={s:{'status':status if s=='ports' else 'not_run'} for s in STAGES})

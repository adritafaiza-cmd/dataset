from pathlib import Path
import json,hashlib,gzip,tarfile
S=Path(__file__).resolve().parent;B=S/'bundle'
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
 return h.hexdigest()
if (B/'hpc-results').exists():(B/'hpc-results').rename(B/'results')
files=sorted(p for p in B.rglob('*') if p.is_file() and '__pycache__' not in p.parts and p.name!='bundle-sha256.json')
checks={str(p.relative_to(B)):sha(p) for p in files};(B/'bundle-sha256.json').write_text(json.dumps(checks,indent=2)+'\n')
archive=S/'scoring-bundle.tar.gz'
with archive.open('wb') as raw:
 with gzip.GzipFile(filename='',mode='wb',fileobj=raw,mtime=0) as gz:
  with tarfile.open(fileobj=gz,mode='w') as tar:
   for p in sorted([*files,B/'bundle-sha256.json']):
    info=tar.gettarinfo(str(p),arcname='bundle/'+str(p.relative_to(B)));info.uid=info.gid=0;info.uname=info.gname='';info.mtime=0
    with p.open('rb') as f:tar.addfile(info,f)
digest=sha(archive);(S/'scoring-bundle.tar.gz.sha256').write_text(digest+'  scoring-bundle.tar.gz\n')
# Verify every archived byte against the sealed inventory, including archive structure.
with tarfile.open(archive,'r:gz') as tar:
 seen={}
 for member in tar:
  assert member.isfile() and member.name.startswith('bundle/') and '..' not in Path(member.name).parts
  data=tar.extractfile(member).read();seen[member.name.removeprefix('bundle/')]=hashlib.sha256(data).hexdigest()
for name,h in checks.items():assert seen[name]==h,name
assert len(seen)==len(checks)+1
(S/'bundle-verification.json').write_text(json.dumps(dict(archive_sha256=digest,archive_bytes=archive.stat().st_size,sealed_files=len(checks),archive_files=len(seen),all_archived_hashes_verified=True,candidates=88,circuits_per_arm=44,evaluation_assets=666,dynamic_scoring_status='blocked_tools_and_ecs05_access',repairs_started=False),indent=2)+'\n')
print(json.dumps(dict(archive=str(archive),bytes=archive.stat().st_size,sha256=digest,files=len(seen))))

from pathlib import Path
import subprocess,tarfile,hashlib,json
S=Path(__file__).resolve().parent;B=S/'bundle';A=B/'evaluator';A.mkdir(exist_ok=True);ROOT=S.parents[2]
commit='1720644e81eda958b8e3dc8b55fdbb16a5415ce0';prefix='benchmark-revisions/cdc-clean-v2/'
records=[]
p=subprocess.Popen(['git','archive',commit,prefix],cwd=ROOT,stdout=subprocess.PIPE)
with tarfile.open(fileobj=p.stdout,mode='r|') as tar:
 for member in tar:
  if not member.isfile():continue
  rel=Path(member.name.removeprefix(prefix));parts=rel.parts
  if any(x in parts for x in ['archive','original','__pycache__','results','build','.git']):continue
  keep=(len(parts)==1 or parts[0] in {'scripts','cdc_tb_checks','enhanced_cdc_tb','vendor'} or (parts[0]=='benchmarks' and len(parts)>2 and (parts[2] in {'fixed','tb','sim','constraints','jasper','formal'} or rel.name in {'manifest.yaml','specification.md'})))
  if not keep:continue
  data=tar.extractfile(member).read();target=A/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data);target.chmod(member.mode)
  records.append(dict(path=str(rel),source_path=member.name,source_commit=commit,bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
assert p.wait()==0
(B/'evaluation-asset-hashes.json').write_text(json.dumps(dict(commit=commit,root=prefix,assets=records),indent=2)+'\n')
# Preserve rejected live-tree audit instead of treating it as v2 candidate scoring.
old=S/'results'
if old.exists():old.rename(S/'live-tree-preflight-rejected')
f=B/'audit_and_lint.py';text=f.read_text();text=text.replace("A=B/'assets'","A=B/'evaluator'").replace("B/'asset-hashes.json'","B/'evaluation-asset-hashes.json'")
# Source paths explicitly resolve to the validated tree; provenance is verified by hashes above.
text=text.replace("counterpart=A/'benchmark-revisions/cdc-clean-v2'/r['path']","counterpart=A/r['path']")
f.write_text(text)
print('Frozen',len(records),'validated v2 evaluation assets')

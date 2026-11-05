"""Prepare a relocatable scoring-only snapshot; never change saved candidates."""
from pathlib import Path
import subprocess,tarfile,json,hashlib,shutil,io
E=Path(__file__).resolve().parents[1]; ROOT=E.parents[1]; S=E/'scoring'; B=S/'bundle'; A=B/'assets'
COMMIT='1720644e81eda958b8e3dc8b55fdbb16a5415ce0'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
manifest=json.loads((E/'manifest.json').read_text()); circuits={r['circuit'] for r in manifest['circuits']}
A.mkdir(parents=True,exist_ok=True)
assets=[]
proc=subprocess.Popen(['git','archive',COMMIT,'benchmarks','cdc_tb_checks','enhanced_cdc_tb','scripts','benchmark-revisions/cdc-clean-v2'],cwd=ROOT,stdout=subprocess.PIPE)
with tarfile.open(fileobj=proc.stdout,mode='r|') as tar:
 for member in tar:
  if not member.isfile():continue
  p=Path(member.name); parts=p.parts
  if 'archive' in parts or 'original' in parts or '__pycache__' in parts:continue
  keep=False
  if parts[0]=='benchmarks':
   keep=len(parts)>2 and parts[1] in circuits and (parts[2] in {'fixed','tb','sim','constraints','jasper','formal'} or p.name in {'manifest.yaml','specification.md'})
  elif parts[0]=='scripts':keep=p.suffix in {'.py','.sh','.csh'}
  elif parts[0] in {'enhanced_cdc_tb','cdc_tb_checks'}:keep='results' not in parts and 'compare' not in parts
  elif parts[0]=='benchmark-revisions':
   # Retain validation evidence and the revised evaluation assets for byte checks.
   keep=len(parts)==3 or (len(parts)>4 and parts[2]=='benchmarks' and parts[3] in circuits and parts[4] in {'fixed','tb','sim','constraints','jasper','formal','manifest.yaml','specification.md'}) or (len(parts)>3 and parts[2]=='enhanced_cdc_tb')
  if not keep:continue
  data=tar.extractfile(member).read();target=A/p;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data);target.chmod(member.mode)
  assets.append(dict(path=member.name,bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),git_blob_sha1=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest(),source_commit=COMMIT))
assert proc.wait()==0
subcommit=subprocess.check_output(['git','rev-parse',COMMIT+':vendor/common_cells'],cwd=ROOT,text=True).strip()
subroot=ROOT/'vendor/common_cells';subdata=subprocess.check_output(['git','archive',subcommit],cwd=subroot)
with tarfile.open(fileobj=io.BytesIO(subdata)) as tar:
 for member in tar:
  if not member.isfile():continue
  p=Path('vendor/common_cells')/member.name;data=tar.extractfile(member).read();target=A/p;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data);target.chmod(member.mode)
  assets.append(dict(path=str(p),bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),source_commit=subcommit))
candidates=[]
for arm in ['base','lora']:
 for r in manifest['circuits']:
  source=E/arm/r['circuit']/'cdc_explicit/attempt-001';metadata=json.loads((source/'metadata.json').read_text());completion=json.loads((source/'complete.json').read_text());rel=f"generated/{r['circuit']}.sv"
  assert sha(source/rel)==completion['sha256'][rel]
  target=B/'candidates'/arm/r['circuit'];target.mkdir(parents=True,exist_ok=True)
  for file in [rel,'metadata.json','complete.json']:
   dest=target/Path(file).name;shutil.copy2(source/file,dest)
  candidates.append(dict(arm=arm,circuit=r['circuit'],path=str((target/Path(rel).name).relative_to(B)),sha256=sha(source/rel),termination_reason=metadata['termination_reason'],truncated=metadata['termination_reason']=='max_new_tokens',source_completion_sha256=sha(source/'complete.json')))
(B/'asset-hashes.json').write_text(json.dumps(dict(commit=COMMIT,submodules={'vendor/common_cells':subcommit},assets=assets),indent=2)+'\n')
(B/'candidate-hashes.json').write_text(json.dumps(dict(expected_per_arm=44,candidates=candidates),indent=2)+'\n')
(B/'generation-manifest.json').write_bytes((E/'manifest.json').read_bytes())
(B/'generation-preflight.json').write_bytes((E/'preflight.json').read_bytes())
print(f'{len(assets)} frozen asset files; {len(candidates)} unchanged candidates; submodule {subcommit}')

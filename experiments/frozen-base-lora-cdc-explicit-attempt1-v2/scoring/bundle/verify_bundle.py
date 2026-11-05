from pathlib import Path
import hashlib,json
B=Path(__file__).resolve().parent
for name in ['evaluation-asset-hashes.json','candidate-hashes.json']:
 d=json.loads((B/name).read_text());rows=d.get('assets',d.get('candidates',[]))
 for r in rows:
  p=B/'evaluator'/r['path'] if 'assets' in d else B/r['path']
  assert hashlib.sha256(p.read_bytes()).hexdigest()==r['sha256'],p
 print(name,len(rows),'verified')
p=B/'bundle-sha256.json'
if p.is_file():
 for name,digest in json.loads(p.read_text()).items():assert hashlib.sha256((B/name).read_bytes()).hexdigest()==digest,name
 print('Complete sealed bundle verified')

import sys,json,urllib.request,tarfile,io
from pathlib import Path
base=Path('/tmp/cdc-sources');meta=Path(__file__).parent
for key in sys.argv[1:]:
 m=json.loads((meta/f'{key}-meta.json').read_text());url=f"https://codeload.github.com/{m['repo']}/tar.gz/{m['commit']}"
 raw=urllib.request.urlopen(url,timeout=180).read(); n=0
 with tarfile.open(fileobj=io.BytesIO(raw)) as t:
  for f in t:
   parts=Path(f.name).parts[1:];r=Path(*parts) if parts else Path('.')
   if not f.isfile() or r.is_absolute() or '..' in parts:continue
   if any(x.lower() in ['experiments','benchmarks','archive','vendor','third_party','tb','dv','formal','testbench','verification','uvm'] for x in parts):continue
   if r.suffix not in ['.sv','.svh','.v','.vh'] and r.name not in ['LICENSE','LICENSE.txt','LICENSE.md','NOTICE']:continue
   p=base/key/r;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(t.extractfile(f).read());n+=1
 print(key,n,flush=True)

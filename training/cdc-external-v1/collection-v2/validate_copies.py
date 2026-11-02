import json,re,hashlib,sys
from pathlib import Path
from pyslang.driver import Driver
from screen import excluded,BLOCK,generated
root=Path('/scratch/ft2335/dataset-observable/training/cdc-external-v1');out=root/'collection-v2'
rows=json.loads((out/'additions.json').read_text());results=[]
if len(sys.argv)>1:
 previous=json.loads((out/'copied-validation.json').read_text()); skip={x['pair_id'] for x in previous if x['ok']}; results=previous; rows=[r for r in rows if r['pair_id'] not in skip]
for row in rows:
 d=root/row['pair_id'];v=json.loads((d/'validation.json').read_text());p=json.loads((d/'PROVENANCE.json').read_text());errors=[]
 for item in [{'file':'source.sv','sha256':p['sha256']}]+p['dependencies']:
  f=d/item['file'];b=f.read_bytes();s=b.decode()
  assert hashlib.sha256(b).hexdigest()==item['sha256']
  if excluded(item['file'],s) or re.search(r'GNU (?:GENERAL PUBLIC|LESSER GENERAL)|Copyright.*(?:Gisselquist|Forencich)',s,re.I):errors.append('excluded origin/license '+item['file'])
  if any(n in BLOCK for n in re.findall(r'\bmodule\s+(\w+)',re.sub(r'/\*.*?\*/|//[^\n]*','',s,flags=re.S))):errors.append('excluded module name '+item['file'])
 args='slang --single-unit -DSYNTHESIS --top '+row['module']+' '+' '.join('-I'+str(d/x) for x in ['.']+v['include_dirs'])+' '+' '.join(str(d/x) for x in v['compilation_files'])
 dr=Driver();dr.addStandardArgs();dr.parseCommandLine(args);dr.processOptions();dr.parseAllSources();c=dr.createCompilation()
 errors += [str(x.code)+': '+str(x.args) for x in c.getAllDiagnostics() if x.isError()]
 results.append({'pair_id':row['pair_id'],'ok':not errors,'errors':errors})
 print(row['pair_id'],not errors,errors[:4],flush=True)
(out/'copied-validation.json').write_text(json.dumps(results,indent=2)+'\n')

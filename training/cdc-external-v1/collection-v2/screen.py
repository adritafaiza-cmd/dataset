import json,re,sys,hashlib
from functools import lru_cache
from pathlib import Path
from pyslang.driver import Driver
BASE=Path('/tmp/cdc-sources')
OUT=Path('/scratch/ft2335/dataset-observable/training/cdc-external-v1/collection-v2')
BLOCK=set('afifo apb_cdc apb_regs apbslave apbxclk arbiter areset_deassert_sync areset_sync async_bidir_fifo async_bidir_ramif_fifo async_fifo async_fifo_sv axi_dma axidma axil_cdc axis_adapter axis_async_fifo axis_async_fifo_adapter axis_fifo axis_register axis_switch axixclk cdc_2phase cdc_2phase_clearable cdc_4phase cdc_fifo_2phase cdc_fifo_gray cdc_fifo_gray_clearable cdc_reset_ctrlr data_sync edge_propagator i2c_master isochronous_4phase_handshake isochronous_spill_register pulse_sync rstgen spi_master_slave sync sync_multistage sync_reset sync_wedge synchronizer uart16550 wbxclk'.split())
def clean(s):return re.sub(r'/\*.*?\*/|//[^\n]*','',s,flags=re.S)
def generated(s):return bool(re.search(r'(?:auto[- ]?generated|automatically generated|this file.*generated|^\s*//\s*generated (?:by|from|with)|do not (?:edit|modify)(?:\s+(?:this )?file|[!.]))',s[:2000],re.I))
def excluded(p,s):
 return any(re.search(r'(?:^|[/_])(tb|dv|uvm|uvmf|testbench|formal|vendor|third_party|verification|coverage|fake_prim|test_suites)(?:[/_]|$)',str(p),re.I) for _ in [0]) or bool(re.search(r'ZipCPU|wb2axip|pulp.platform|common_cells|verilog-(?:axi|axis|i2c)|dpretet|dianluniuniu|iammituraj|freecores/(?:spi_master_slave|uart16550)|Solderpad|SPDX-License-Identifier:\s*(?:GPL|LGPL)',s,re.I))
@lru_cache(maxsize=None)
def inventory(repo):
 root=BASE/repo; files={};decl={}; inc={}
 for p in sorted(root.rglob('*'), key=lambda p: (not str(p.relative_to(root)).startswith('rtl/'),str(p))):
  if p.suffix not in ['.sv','.v','.svh','.vh'] or not p.is_file():continue
  s=p.read_text(errors='replace')
  if excluded(p.relative_to(root),s) or 'generated' in p.parts:continue
  if repo=='opentitan' and any(x.startswith('prim_') and x not in ['prim_generic'] for x in p.relative_to(root).parts[:-1]):continue
  files[p]=s;inc.setdefault(p.name,p)
  for n in re.findall(r'\b(?:module|package|interface)\s+(?:automatic\s+)?(\w+)',clean(s)):decl.setdefault(n,p)
 return root,files,decl,inc

def check(repo,top):
 root,files,decl,inc=inventory(repo); source=decl[top]; todo=[source]; seen=set();deps=[]; missing=[];parseerrors=[]
 dirs=sorted({str(p.parent) for p in files}); pre='slang --single-unit -DSYNTHESIS '+ ' '.join('-I'+d for d in dirs)
 while todo:
  p=todo.pop(0)
  if p in seen:continue
  seen.add(p);s=files[p];cs=clean(s)
  if generated(s):missing.append('generated dependency '+str(p.relative_to(root)))
  for name in re.findall(r'`include\s+"([^"]+)"',s):
   q=inc.get(name)
   if q:todo.append(q)
   else:missing.append('include '+name)
  for name in re.findall(r'\b(\w+)::',cs):
   if name in decl:todo.append(decl[name])
  if p.suffix in ['.svh','.vh'] or not re.search(r'\b(module|package|interface)\s',cs):continue
  d=Driver();d.addStandardArgs();d.parseCommandLine(pre+' '+str(p));d.processOptions();d.parseAllSources()
  for tree in d.syntaxTrees:
   def visit(n):
    if type(n).__name__=='HierarchyInstantiationSyntax':
     name=n.type.valueText
     if name in decl:todo.append(decl[name])
     else:missing.append('module '+name)
   tree.root.visit(visit)
  deps.append(p)
 # Topological package ordering; packages need to precede importers.
 ordered=[];vis=set()
 def order(p):
  if p in vis:return
  vis.add(p)
  for n in re.findall(r'\b(\w+)::',clean(files[p])):
   q=decl.get(n)
   if q in deps:order(q)
  ordered.append(p)
 for p in deps:order(p)
 d=Driver();d.addStandardArgs();cmd=pre+' --top '+top+' '+' '.join(map(str,ordered));d.parseCommandLine(cmd);d.processOptions();d.parseAllSources();c=d.createCompilation();diags=c.getAllDiagnostics();errors=[str(x.code)+': '+str(x.args) for x in diags if x.isError()]
 return {'module':top,'source':str(source.relative_to(root)),'files':[str(p.relative_to(root)) for p in sorted(seen)],'compilation_files':[str(p.relative_to(root)) for p in ordered],'errors':sorted(set(errors+missing)),'warnings':sum(not x.isError() for x in diags),'command':cmd,'ok':not errors and not missing}
if __name__=='__main__':
 repo=sys.argv[1]
 if len(sys.argv)>2:
  for name in sys.argv[2:]:
   result=check(repo,name);(OUT/f'{repo}--{name}.check.json').write_text(json.dumps(result,indent=2));print(name,result['ok'],result['errors'][:6],flush=True)
 else:
  root,files,decl,inc=inventory(repo)
  for name,p in decl.items():
   s=files[p]
   if name in BLOCK or generated(s) or not re.search(r'\bmodule\s+'+name+r'\b',clean(s)):continue
   if re.search(r'(?:sync|cdc|asynchron|metastab)',s,re.I):print(name,str(p.relative_to(root)))

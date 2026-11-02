import sys,json,re
from screen import inventory,check,OUT,clean,generated,BLOCK
repo=sys.argv[1];root,files,decl,inc=inventory(repo);selected=[];seen=set()
for name,p in decl.items():
 s=files[p];c=clean(s)
 if name in BLOCK or generated(s) or p in seen:continue
 if repo=='RTLDesignSherpa':
  if not str(p.relative_to(root)).startswith('rtl/') and '/rtl/' not in str(p):continue
  if not re.search(r'\b(?:cdc_\w+|gaxi_fifo_async|gaxi_skid_buffer_async|fifo_async|reset_sync|sync_pulse|glitch_free_n_dff_arn)\b',c):continue
  if name in ['bin2gray','gray2bin','counter_bingray','counter_johnson','johnson2bin']:continue
 elif repo=='cdc_lib':
  if name in ['cdc_gray_conv','cdc_sync_fifo'] or not str(p.relative_to(root)).startswith('sources/rtl/'):continue
  if p.stem=='cdc_pulse' and name!='cdc_pulse':continue
 elif repo=='asic-cells':
  if not re.search(r'synchron|clock_barrier',c):continue
 elif repo.startswith('aib'):
  if not re.search(r'\b\w*(?:sync|async|rstn_sync)\w*\b',c):continue
 else:continue
 seen.add(p);selected.append(name)
print('candidates',repo,len(selected),selected,flush=True)
for name in selected:
 try:
  res=check(repo,name);(OUT/f'{repo}--{name}.check.json').write_text(json.dumps(res,indent=2));print(name,res['ok'],res['errors'][:4],flush=True)
 except Exception as e:print('EXCEPTION',name,str(e),flush=True)

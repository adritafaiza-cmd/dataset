import sys,json,re,hashlib,shutil
from pathlib import Path
from pyslang.driver import Driver
from screen import clean,BLOCK,generated,excluded
ROOT=Path('/scratch/ft2335/dataset-observable/training/cdc-external-v1');OUT=ROOT/'collection-v2';BASE=Path('/tmp/cdc-sources')
sha=lambda b:hashlib.sha256(b).hexdigest()
def dump(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
old=[json.loads(x) for x in (ROOT/'manifest.jsonl').read_text().splitlines()]
# Preserve original files and index bytes; this is an integrity snapshot, not a revalidation/recount.
if not (OUT/'original-file-hashes.json').exists():
 snapshot={}
 for r in old:
  for p in (ROOT/r['module']).rglob('*'):
   if p.is_file():snapshot[str(p.relative_to(ROOT))]=sha(p.read_bytes())
 dump(OUT/'original-file-hashes.json',snapshot)
 for name in ['train.jsonl','dev.jsonl','manifest.jsonl','collection_report.json']:(OUT/('before-'+name)).write_bytes((ROOT/name).read_bytes())
known={};norm={}
for r in old:
 p=ROOT/r['module']/'source.sv';b=p.read_bytes();known[sha(b)]=r['module'];norm[sha(re.sub(rb'\s+',b'',b))]=r['module']
metas={
'opentitan':{'repo':'lowRISC/opentitan','commit':'41049e9deb40e0602cd5272c40398be380ae2637','license_spdx':'Apache-2.0','license_path':'LICENSE'},
'veer':{'repo':'chipsalliance/Cores-VeeR-EL2','commit':'fa00c8aadc4a077d78b277129c1badf90d881255','license_spdx':'Apache-2.0','license_path':'LICENSE'}}
for repo in ['RTLDesignSherpa','asic-cells','cdc_lib','cdc_primitives','aib-protocols']:metas[repo]=json.loads((OUT/f'{repo}-meta.json').read_text())
leaf=set('asyncfifo levelsync levelsync_sr rst_regen_low spi_bitsync spi_rstnsync prim_diff_decode rstmgr_por cdc_synchronizer glitch_free_n_dff_arn reset_sync sync_pulse cdc_sync2 cdc_sync3 cdc_reset_sync cdc_pulse_sync cdc_toggle_sync cdc_bit cdc_reset double_flop_synchronizer triple_flop_synchronizer triple_flop_toggle_synchronizer wide_double_flop_synchronizer dmi_jtag_to_core_sync'.split())
pattern=re.compile(r'^(?:levelsync|rst_regen_low$|spi_bitsync$|spi_rstnsync$|asyncfifo$|prim_(?:flop_2sync|sync_reqack|pulse_sync|diff_decode|alert_sender)|cdc_|gaxi_fifo_async$|gaxi_skid_buffer_async$|fifo_async$|reset_sync$|sync_pulse$|glitch_free_n_dff_arn$|.*flop.*synchronizer$|spi_clock_barrier_crossing$|dmi_jtag_to_core_sync$)')
curated={
'prim_alert_sender':'Transmit an alert request over the differential alert protocol, synchronize the asynchronous acknowledgement and ping paths, and implement ping responses and the configured alert handshake.',
'prim_diff_decode':'Decode an asynchronous differential input after synchronization. Produce level and edge indications and flag invalid differential encodings using the configured skew tolerance.',
'prim_esc_sender':'Encode escalation requests and ping requests on a differential channel and synchronize the returning response before updating handshake and error state.',
'prim_esc_receiver':'Receive differential escalation and ping signaling, synchronize the incoming channel, distinguish ping from escalation by pulse duration, and provide the specified response pattern and timeout escalation.',
'prim_diff_to_alert':'Bridge a differential event input to the alert protocol, decoding and synchronizing the input and retaining a request until the alert handshake completes.',
'prim_filter':'Filter an asynchronous input using the configured synchronization and stability filter before updating the output.',
'prim_filter_ctr':'Synchronize an asynchronous input and update the filtered output only after the input has remained stable for the configured count.',
'prim_edge_detector':'Optionally synchronize the asynchronous input, then compare its current and previous sampled levels to detect the selected edge polarity.',
'rstmgr_por':'Condition power-on reset with asynchronous assertion, synchronized release, and the configured reset stretching sequence in the destination clock domain.',
'clkmgr_clk_status':'Transfer and combine clock-enabled status across the clock domains using a request/acknowledge synchronization path.',
'dmi_jtag_to_core_sync':'Synchronize JTAG read and write enables into the processor clock domain and emit single-cycle register-access strobes from the synchronized rising edges.',
'dmi_wrapper':'Connect the JTAG DMI transport to the core-domain debug register interface, synchronizing the access enables while maintaining the transport address and write-data protocol.',
'high_speed_in_bus':'Synchronize the incoming request into clk. Assert data_available when a request is pending, data_required is asserted, and no acknowledgement is outstanding. Set acknowledge when data is accepted and clear it after the synchronized request drops.',
'high_speed_out_bus':'Synchronize the returning acknowledge into clk and control an outbound request/data exchange without issuing a new transfer before the preceding handshake is complete.',
'double_flop_synchronizer':'Synchronize a single asynchronous level with two serial destination-clock registers, respecting enable and reset.',
'wide_double_flop_synchronizer':'Synchronize each bit of a quasi-static asynchronous input vector through two serial destination-clock registers. The sender must hold multi-bit values stable; this interface does not provide atomic bus handshaking.',
 'triple_flop_synchronizer':'Synchronize an asynchronous input through three serial destination-clock registers with the declared reset and enable behavior.',
 'triple_flop_toggle_synchronizer':'Synchronize an asynchronous toggle and detect a change using a delayed synchronized sample to produce a destination-domain event.',
'spi_clock_barrier_crossing':'Transfer SPI request and payload information into the ASIC clock domain and return the acknowledgement through the declared synchronization handshake.',
'spi_client':'Implement the declared SPI client interface and transfer requests into the internal clock domain through the clock-barrier synchronizers.',
'cdc_bit':'Pass one asynchronous input through SYNC_STAGES destination-clock registers. Reset the entire pipeline to RESET_VALUE and expose only its final stage.',
'cdc_reset':'Assert reset asynchronously and release it only after SYNC_STAGES destination-clock edges through the release pipeline.',
'cdc_counter':'Maintain a source-domain binary event count, convert it to Gray code for transfer, synchronize it into the destination domain, and reconstruct the destination count.',
'cdc_gray_sync':'Synchronize each bit of a Gray-coded input through the configured synchronizer stages. The source must make only legal single-bit Gray transitions.',
'cdc_qualifier':'Transfer a held data bus using a synchronized qualifier. The source must keep the bus stable for the qualifier transfer interval; expose data only after the qualifier has safely crossed.',
'cdc_fifo':'Implement a dual-clock FIFO with local binary pointers, Gray-coded pointer transfer through synchronizers, and domain-local full and empty decisions.',
}
accepted=json.loads((OUT/'additions.json').read_text()) if (OUT/'additions.json').exists() else []
rejected=json.loads((OUT/'rejections.json').read_text()) if (OUT/'rejections.json').exists() else []
for row in accepted:
 b=(ROOT/row['pair_id']/'source.sv').read_bytes();known[sha(b)]=row['pair_id'];norm[sha(re.sub(rb'\s+',b'',b))]=row['pair_id']
for f in sorted(OUT.glob('*.check.json')):
 repo=f.name.split('--')[0]
 if repo not in metas or (len(sys.argv)>1 and repo not in sys.argv[1:]):continue
 r=json.loads(f.read_text());name=r['module']
 if not r['ok']:
  rejected.append({'repo':repo,'module':name,'reason':'parse/elaboration/dependency failure','details':r['errors']});continue
 source=BASE/repo/r['source'];b=source.read_bytes();text=b.decode();code=clean(text)
 if name in BLOCK or any(n in BLOCK for n in re.findall(r'\bmodule\s+(\w+)',code)):
  rejected.append({'repo':repo,'module':name,'reason':'sealed module-name exclusion'});continue
 if sha(b) in known or sha(re.sub(rb'\s+',b'',b)) in norm:
  rejected.append({'repo':repo,'module':name,'reason':'exact/whitespace-normalized duplicate'});continue
 if generated(text) or excluded(r['source'],text):raise RuntimeError('unexpected excluded source '+str(source))
 # Parse with the same include paths and synthesis preprocessor configuration as the validated closure.
 driver=Driver();driver.addStandardArgs();driver.parseCommandLine(r['command'].split(' --top ')[0]+' '+str(source));driver.processOptions();driver.parseAllSources()
 nodes=[];instances=[]
 for tree in driver.syntaxTrees:
  def visit(n):
   if type(n).__name__=='ModuleDeclarationSyntax' and n.header.name.valueText==name:nodes.append(n)
  tree.root.visit(visit)
 if len(nodes)!=1:raise RuntimeError('ambiguous top '+name)
 node=nodes[0]
 def inst(n):
  if type(n).__name__=='HierarchyInstantiationSyntax' and pattern.search(n.type.valueText):
   instances.append({'type':n.type.valueText,'declaration':clean(str(n)).strip()})
 node.visit(inst)
 if not instances and name not in leaf:
  rejected.append({'repo':repo,'module':name,'reason':'no direct qualifying crossing/synchronizer in selected module'});continue
 header=str(node.header);header=header[header.find('module '+name):].replace('\\r\\n','\n')
 if not re.search(r'\b(input|output|inout)\b',clean(header)):
  declarations=re.findall(r'\b(?:input|output|inout|parameter|localparam)\b[^;]+;',clean(str(node)))
  header+='\n'+'\n'.join(declarations)
 # Port declarations are parsed independently from prose, so comment words are never treated as ports.
 ports=[]
 if node.header.ports:
  pc=clean(str(node.header.ports));direction=None
  if not re.search(r'\b(input|output|inout)\b',pc):pc=' '.join(re.findall(r'\b(?:input|output|inout)\b[^;]+;',clean(str(node)))).replace(';',',')
  for segment in pc.strip().strip('()').split(','):
   d=re.search(r'\b(input|output|inout)\b',segment)
   if d:direction=d.group(1)
   ns=re.findall(r'\b[A-Za-z_]\w*\b',re.sub(r'\[[^\]]*\]','',segment.split('=')[0]))
   if direction and ns:ports.append({'direction':direction,'name':ns[-1]})
 clocks=[p['name'] for p in ports if re.search(r'clk|clock|tck',p['name'],re.I)]
 resets=[p['name'] for p in ports if re.search(r'rst|reset|por',p['name'],re.I)]
 # Preserve the authored interface documentation as behavioral requirements, not the implementation.
 prefix=text[:text.find('module '+name)]
 comments=[]
 for line in prefix.splitlines():
  q=re.sub(r'^\s*(?://|/\*|\*)\s?','',line).strip()
  if not line.lstrip().startswith(('//','/*','*')):continue
  if not q or re.match(r'[-=*_/]+$',q):continue
  if re.search(r'copyright|spdx|https?://|license|warrant|author:|created:|documentation:|subsystem:|RTL Design Sherpa|Licensed under|limitations under|you may|obtain a copy|Unless required|WITHOUT|distributed under|Version 2.0|See the License',q,re.I):continue
  comments.append(q)
 purpose=curated.get(name)
 if not purpose:
  pm=re.search(r'//\s*(?:Purpose|Description)\s*:\s*([^\n]+)',text,re.I)
  purpose=pm.group(1).strip() if pm else 'Implement '+name.replace('_',' ')+' using the interface and behavioral contract below.'
 mech=[]
 types=[x['type'] for x in instances]
 if any('reset' in t or 'rst' in t for t in [name]+types):mech.append('async_assert_sync_release_reset')
 if any('fifo' in t for t in [name]+types):mech.append('dual_clock_fifo')
 if any('handshake' in t or 'reqack' in t for t in [name]+types):mech.append('request_acknowledge')
 if any('pulse' in t or 'toggle' in t for t in [name]+types):mech.append('pulse_toggle_transfer')
 if not mech:mech=['level_synchronization']
 crossing='\n'.join('- '+x['type']+': '+re.sub(r'\s+',' ',x['declaration']) for x in instances)
 # Every named crossing binding is included as an interface constraint; it is not permission to bypass synchronization.
 spec=f'Implement the SystemVerilog module `{name}`.\n\n{purpose}\n\n'
 if comments:spec+='Functional contract and interface notes:\n\n'+'\n'.join(comments)+'\n\n'
 spec+='Required clock and reset behavior:\n\n'
 spec+='- Clock ports: '+(', '.join(clocks) or 'as declared in the interface')+'.\n'
 spec+='- Reset ports: '+(', '.join(resets) or 'none; retain the declared initialization behavior')+'.\n'
 spec+='- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.\n'
 spec+='- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.\n'
 spec+='- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.\n\n'
 if crossing:spec+='Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):\n\n'+crossing+'\n\n'
 spec+='Exact module interface (retain parameter defaults, types, widths, names, and directions):\n\n```systemverilog\n'+header.strip()+'\n```\n\nReturn only the complete module source. Do not emit a testbench or remove the synchronizing path.\n'
 pairid=name if not (ROOT/name).exists() else repo.lower().replace('-','_')+'__'+name
 target=ROOT/pairid
 if target.exists():raise RuntimeError('refusing overwrite '+str(target))
 target.mkdir();(target/'deps').mkdir();(target/'source.sv').write_bytes(b);(target/'spec.md').write_text(spec)
 (target/'pair.jsonl').write_text(json.dumps({'messages':[{'role':'user','content':spec},{'role':'assistant','content':b.decode()}]},ensure_ascii=False)+'\n')
 deps=[]
 for rel in r['files']:
  if rel==r['source']:continue
  p=BASE/repo/rel;dest=target/'deps'/rel;dest.parent.mkdir(parents=True,exist_ok=True);data=p.read_bytes();dest.write_bytes(data);deps.append({'file':str(dest.relative_to(target)),'upstream_path':rel,'sha256':sha(data)})
 m=metas[repo];url='https://github.com/'+m['repo'];split='dev' if repo in ['opentitan','veer'] else 'train'
 (target/'LICENSE').write_bytes((OUT/f'{repo}-LICENSE').read_bytes())
 prov={'repo':url,'commit':m['commit'],'path':r['source'],'license':m['license_spdx'],'spdx_license':m['license_spdx'],'license_url':url+'/blob/'+m['commit']+'/'+m['license_path'],'sha256':sha(b),'whitespace_normalized_sha256':sha(re.sub(rb'\s+',b'',b)),'dependencies':deps,'split':split,'source_unchanged':True}
 dump(target/'PROVENANCE.json',prov)
 structural={'clocks':clocks,'resets':resets,'ports':ports,'mechanism':mech,'synchronizer_present':True,'crossing_signals':instances if instances else [{'inline_synchronizer':name}],'scope':'selected module only; no test/exam input','check':'parsed RTL and explicit crossing-instance bindings; not a functional or formal proof'}
 dump(target/'structural.json',structural)
 validation={'elaborate_ok':True,'parser':'pyslang 12.1.0','defines':['SYNTHESIS'],'top':name,'compilation_files':['source.sv' if x==r['source'] else 'deps/'+x for x in r['compilation_files']],'include_dirs':sorted({str(Path(x['file']).parent) for x in deps}), 'warnings':r['warnings'],'errors':[],'source_sha256':sha(b)}
 dump(target/'validation.json',validation)
 row={'module':name,'pair_id':pairid,'repo':url,'commit':m['commit'],'path':r['source'],'license':m['license_spdx'],'clocks':clocks,'resets':resets,'mechanism':mech,'dev_split':split=='dev','elaborate_ok':True,'source_sha256':sha(b)}
 accepted.append(row);known[sha(b)]=pairid;norm[sha(re.sub(rb'\s+',b'',b))]=pairid
 print('ADDED',repo,pairid,flush=True)
dump(OUT/'additions.json',accepted);dump(OUT/'rejections.json',rejected)
print('NEW PAIRS',len(accepted),'NEW DEV',sum(x['dev_split'] for x in accepted),flush=True)

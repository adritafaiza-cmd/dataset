import json,hashlib,re,collections
from pathlib import Path
root=Path('/scratch/ft2335/dataset-observable/training/cdc-external-v1');out=root/'collection-v2'
def load(p):return json.loads(p.read_text())
def write(p,x):
 tmp=p.with_name(p.name+'.collection-v2.tmp');tmp.write_text(x);tmp.replace(p)
oldrows=[json.loads(x) for x in (out/'before-manifest.jsonl').read_text().splitlines()]
added=load(out/'additions.json');checks={x['pair_id']:x for x in load(out/'copied-validation.json')}
for row in added:assert checks[row['pair_id']]['ok'],row['pair_id']
for rel,digest in load(out/'original-file-hashes.json').items():
 assert hashlib.sha256((root/rel).read_bytes()).hexdigest()==digest,'Existing pair changed: '+rel
moved=[]
for r in oldrows:
 if r['repo']=='https://github.com/lowRISC/opentitan' and not r['dev_split']:
  moved.append(r['module']);r['dev_split']=True
rows=oldrows+added
splits={}
for r in rows:
 split='dev' if r['dev_split'] else 'train';splits.setdefault(r['repo'],set()).add(split)
assert all(len(s)==1 for s in splits.values())
assert sum(s=={'dev'} for s in splits.values())>=2
# Index the exact existing pair records; do not rewrite any existing pair artifact.
tr=[];dv=[]
for r in rows:
 line=(root/r.get('pair_id',r['module'])/'pair.jsonl').read_bytes()
 assert line.endswith(b'\n') and len(line.splitlines())==1
 (dv if r['dev_split'] else tr).append(line)
# Counts derive from the supplied 7/14 baseline and the additions, plus the documented index migration.
newdev=sum(r['dev_split'] for r in added);train_count=7+len(added)-newdev-len(moved);dev_count=14+newdev+len(moved)
assert len(tr)==train_count and len(dv)==dev_count
for name,lines in [('train.jsonl',tr),('dev.jsonl',dv)]:
 p=root/name;tmp=p.with_name(p.name+'.collection-v2.tmp');tmp.write_bytes(b''.join(lines));tmp.replace(p)
write(root/'manifest.jsonl',''.join(json.dumps(r,sort_keys=True)+'\n' for r in rows))
write(root/'dev_modules.txt','\n'.join(r.get('pair_id',r['module']) for r in rows if r['dev_split'])+'\n')
prev=load(out/'before-collection_report.json');reject=load(out/'rejections.json')
counts=dict(prev['counts_by_repo'])
for r in added:counts[r['repo']]=counts.get(r['repo'],0)+1
report={
 'train_count':train_count,'dev_count':dev_count,'total_pair_count':21+len(added),'target_pairs':100,'new_pair_count':len(added),
 'baseline_counts_supplied':{'train':7,'dev':14,'total':21},'counts_by_repo':counts,
 'repository_splits':{r:next(iter(s)) for r,s in splits.items()},'dev_fraction':dev_count/(21+len(added)),
 'dev_repository_count':sum(s=={'dev'} for s in splits.values()),
 'legacy_index_migration':{'modules':moved,'from':'train','to':'dev','reason':'Original OpenTitan manifest mixed repositories across train/dev; all OpenTitan index entries are now dev. Existing per-pair files are byte-for-byte unchanged.'},
 'elaborate_pass_count':len(added),'elaborate_unknown_count':21,
 'validation':{'tool':'pyslang 12.1.0','defines':['SYNTHESIS'],'new_pairs_checked_in_copied_layout':len(added),'parse_or_elaboration_failures_accepted':0,'unresolved_dependencies_accepted':0,'existing_pairs_revalidated':False,'existing_pair_hashes_unchanged':True,'exact_and_whitespace_normalized_deduplication':True,'new_source_bytes_match_upstream':True,'generated_sources_and_generated_dependencies_excluded':True,'formal_or_behavioral_proof_claimed':False},
 'rejections':reject,'historical_rejections':prev.get('rejections',[]),'basejump_rejection':prev['basejump_rejection'],
 'source_order':['lowRISC/opentitan @ 41049e9deb40e0602cd5272c40398be380ae2637','chipsalliance/caliptra-rtl @ 90e47c0135b03b4be7e17f25e99d8de47e378630','chipsalliance/Cores-VeeR-EL2 @ fa00c8aadc4a077d78b277129c1badf90d881255','additional license-screened independent repositories'],
 'caliptra_result':'No pair accepted: the authored reset/boot controller requires unavailable configuration includes; OpenTitan-derived and vendored VeeR modules were not counted as independent Caliptra data.',
 'additional_screened_not_collected':['waviousllc/wav-lpddr-hw','hdl-util/clock-domain-crossing','chipsalliance/aib-phy-hardware'],
 'scope':{'sealed_exam_excluded':True,'forbidden_paths_not_opened':True,'forbidden_repositories_not_used':True,'model_training_not_run':True,'slurm_job_21516805_untouched':True,'upstream_rtl_unmodified':True,'original_pair_files_unchanged':True},
 'target_status':f'{21+len(added)} pairs indexed; minimum 100-pair target exceeded. Collection only; no training or exam evaluation.',
 'artifacts':{'audit_directory':'collection-v2','new_pair_manifest':'collection-v2/additions.json','copied_dependency_validation':'collection-v2/copied-validation.json','original_pair_integrity':'collection-v2/original-file-hashes.json'},
}
write(root/'collection_report.json',json.dumps(report,indent=2)+'\n')
validation={'new_pairs':len(added),'new_pairs_parse_and_elaboration_passed':len(added),'existing_pairs_preserved_without_revalidation':21,'source_bytes_unchanged':True,'all_repositories_split_exclusively':True,'dev_repositories':report['dev_repository_count'],'total_pairs':21+len(added),'details':'collection-v2/copied-validation.json'}
write(root/'validation_report.json',json.dumps(validation,indent=2)+'\n')
print(json.dumps({'train_count':train_count,'dev_count':dev_count,'total_pair_count':21+len(added)}))

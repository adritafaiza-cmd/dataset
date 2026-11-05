"""Bind fresh v2 scoring golden records to the repair checker's asset manifest."""
import argparse,json,re
from pathlib import Path
from .core import read,save,sha
from .ports import compare

def main():
    p=argparse.ArgumentParser();p.add_argument('--bundle',type=Path,required=True);p.add_argument('--golden-results',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    manifest=a.bundle/'evaluation-asset-hashes.json';records=read(manifest)['assets'];assets=a.bundle/'evaluator'
    for r in records:
        if sha(assets/r['path'])!=r['sha256']:raise ValueError('Evaluation asset changed')
    circuits=sorted({r['circuit'] for r in read(a.bundle/'candidate-hashes.json')['candidates']});golden={};evidence={}
    for c in circuits:
        path=a.golden_results/c/'result.json';row=read(path)
        if row['arm']!='golden' or row['circuit']!=c:raise ValueError('Wrong golden result identity')
        # The full scoring driver records the reference-top hash in each golden row.
        choices=[assets/r['path'] for r in records if r['path'].startswith('benchmarks/'+c+'/fixed/rtl/')]
        manifest_text=(assets/'benchmarks'/c/'manifest.yaml').read_text();top=re.search(r'^top_module:\s*(\S+)',manifest_text,re.M).group(1)
        tops=[x for x in choices if re.search(r'\bmodule\s+'+re.escape(top)+r'\b',x.read_text(errors='replace'))]
        if len(tops)!=1 or sha(tops[0])!=row['sha256']:raise ValueError('Golden top RTL differs from sealed evaluation tree')
        golden[c]={s:row['stages']['enhanced_behavioral_tb' if s=='enhanced' else s]['status'] for s in ('compile','functional','structural_lint','enhanced')}
        evidence[c]={'result_sha256':sha(path),'source':str(path.resolve()),'golden_sha256':row['sha256']}
    if len(golden)!=44:raise ValueError('Expected 44 golden controls')
    if a.output.exists():raise ValueError('Preserve existing control attestation; choose a new output path')
    save(a.output,{'schema_version':1,'evaluation_manifest_sha256':sha(manifest),'golden':golden,'evidence':evidence,'source':'fresh_v2_score_on_ecs05_golden_records'})
    print(json.dumps({'controls_path':str(a.output),'controls_sha256':sha(a.output),'circuits':44,'all_stages_pass':all(v=='pass' for row in golden.values() for v in row.values())}))
if __name__=='__main__':main()

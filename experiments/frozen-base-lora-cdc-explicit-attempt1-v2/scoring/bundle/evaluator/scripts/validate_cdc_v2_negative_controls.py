#!/usr/bin/env python3
"""Check that the revised harness rejects two deliberate faults."""
import json,os,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/'scripts'),str(ROOT/'enhanced_cdc_tb')]
from evaluate_pass_at_n import simulate,XRUN_BIN,JG_BIN
from evaluate_symbiyosys_eligible import evaluate,parse_sby,DEFAULT_SBY
from run_enhanced import run_one as enhanced
import run_jasper_full_cdc as j
j.EXTRA_TCL=''
os.environ['PATH']=XRUN_BIN+':'+JG_BIN+':'+str(DEFAULT_SBY.parent)+':'+os.environ.get('PATH','')
os.environ['CDC_CHECKS']='0'
OUT=ROOT/'experiments/v2-negative-controls';OUT.mkdir(parents=True,exist_ok=True)
source=(ROOT/'benchmarks/cdc_2phase/fixed/rtl/cdc_2phase.v').read_text()
control=OUT/'control-bypass';control.mkdir(exist_ok=True);p=control/'cdc_2phase.v'
assert source.count('req_settle_q <= req_q1;')==1
p.write_text(source.replace('req_settle_q <= req_q1;','req_settle_q <= async_req_i;'))
a=j.run_one({'kind':'generated','source':'v2-negative','circuit':'cdc_2phase','prompt':'control-bypass','attempt':'fixed','rtl':str(p.relative_to(ROOT)),'parameters':{'WIDTH':8}})
assert a.get('jg_returncode')==0 and a.get('jasper_report') and not a.get('cdc_clean') and (a.get('cdc_errors',0)+a.get('rdc_errors',0)>0),a
payload=OUT/'payload-corruption';payload.mkdir(exist_ok=True);p=payload/'cdc_2phase.v'
assert source.count('data_dst_q <= data_sync_q;')==1
p.write_text(source.replace('data_dst_q <= data_sync_q;',"data_dst_q <= data_sync_q ^ {{(WIDTH-1){1'b0}},1'b1};"))
b=simulate(p,'cdc_2phase',payload)
c=enhanced({'source':'v2-negative','circuit':'cdc_2phase','prompt':'payload-corruption','attempt':'fixed','rtl':p})
contract=parse_sby(ROOT/'formal/cdc_2phase/golden.sby')
# Use the SMT engine for concrete witness generation; ABC's bounded UNSAT
# result is useful for the golden but this install can fail AIG witness conversion.
contract['text']=contract['text'].replace('prove: abc bmc3\ncover: smtbmc boolector','smtbmc boolector')
d=evaluate(DEFAULT_SBY,'v2-negative','cdc_2phase','payload-corruption','fixed',p,contract,180)
assert b['simulate_ok'] is False and 'TESTS FAILED' in b['sim_note'],b
assert c['status']=='FAIL' and 'VIOLATION' in c['note'],c
assert d['formal_status']=='FORMAL_COUNTEREXAMPLE',d
result={'passed':True,'control_bypass_jasper':a,'payload_corruption_functional':b,'payload_corruption_enhanced':c,'payload_corruption_formal':d}
(OUT/'results.json').write_text(json.dumps(result,indent=2)+'\n')
print('PASS: Jasper rejected control bypass; functional, enhanced, and bounded formal checks rejected payload corruption.',flush=True)

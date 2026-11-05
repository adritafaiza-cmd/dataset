"""SIMULATED RUNNER TESTS ONLY. No model, simulator, or experiment score is run."""
import json,subprocess,sys,tempfile,unittest
from pathlib import Path
from cdc_repair.core import STAGES,chain,digest,read,save,seal,short,validate_check,verify,write_once
from cdc_repair.ports import compare,interface,simulation_options
from cdc_repair.generator import extract,QwenGenerator
from cdc_repair.checker import classify
from cdc_repair.transport import CommandChecker
SPEC=b'Original specification: module dut(input clk, output q); endmodule'
INITIAL=b'module dut(input clk, output q); assign q=clk; endmodule\n'
IDENTITY={'mode':'runner_test','arm':'base','circuit':'dut','initial_truncated':True}

def outcome(candidate,stage=None,status='design_failure',message='bad signal'):
    result=dict(candidate_sha256=digest(candidate),status=status if stage else 'pass',diagnostic=short(stage,message) if stage and status=='design_failure' else '',earliest_stage=stage,stages={})
    stopped=False
    for s in STAGES:
        result['stages'][s]={'status':'not_run' if stopped else status if s==stage else 'pass','runtime_seconds':0.001}
        if s==stage:stopped=True
    return result
class SimulatedChecker:
    def __init__(self,outcomes):self.outcomes=list(outcomes);self.calls=[]
    def __call__(self,candidate,identity,dest):
        self.calls.append(candidate);stage,status=self.outcomes.pop(0);(dest/'full-checker.log').write_text('SIMULATED CHECKER LOG; REFERENCE_RTL_SECRET JASPER_SECRET')
        result=outcome(candidate,stage,status,message='PROTOCOL VIOLATION [P01] unstable payload' if stage=='enhanced' else 'bad signal')
        if stage=='enhanced':result['stages'][stage]['protocol_failures']=['P01'];result['stages'][stage]['cdc_reset_evidence']=[]
        return result
class SimulatedGenerator:
    def __init__(self,crash=False):self.calls=[];self.crash=crash
    def __call__(self,prompt,target,identity):
        d=target/'model-generation';d.mkdir(exist_ok=True)
        if verify(d,identity=identity):return (d/'candidate.sv').read_bytes()
        self.calls.append(prompt);candidate=INITIAL+b'// simulated repair\n'
        write_once(d/'request.txt',prompt);write_once(d/'response.txt',candidate);write_once(d/'candidate.sv',candidate);save(d/'response.json',{'text':candidate.decode()});seal(d,identity=identity)
        if self.crash:self.crash=False;raise KeyboardInterrupt('simulated interruption after durable generation receipt')
        return candidate
class RunnerTests(unittest.TestCase):
    def setUp(self):self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)/'runner_test'
    def tearDown(self):self.temp.cleanup()
    def run_chain(self,checker,generator,**kw):return chain(self.root,INITIAL,SPEC,IDENTITY,checker,generator,**kw)
    def test_initial_requests_preserved_without_generation(self):
        c=SimulatedChecker([(None,'pass')]);g=SimulatedGenerator();artifacts={'request.txt':b'exact initial request\n','response.txt':b'exact initial response\n'}
        chain(self.root,INITIAL,SPEC,IDENTITY,c,g,initial_artifacts=artifacts)
        for name,value in artifacts.items():self.assertEqual((self.root/'candidate-000/source-artifacts'/name).read_bytes(),value)
        self.assertEqual(g.calls,[])
    def test_all_pass_no_generation(self):
        c=SimulatedChecker([(None,'pass')]);g=SimulatedGenerator();r=self.run_chain(c,g);self.assertEqual(r['status'],'all_repair_checks_passed');self.assertEqual(g.calls,[]);self.assertFalse(r['experiment_results'])
        self.assertTrue(read(self.root/'candidate-000/generation.json')['truncation'])
    def test_three_repairs_means_four_candidates(self):
        c=SimulatedChecker([('functional','design_failure')]*4);g=SimulatedGenerator();r=self.run_chain(c,g)
        self.assertEqual(r['repairs_completed'],3);self.assertEqual(r['status'],'repair_limit_reached');self.assertEqual(len(g.calls),3);self.assertEqual(len(c.calls),4);self.assertFalse((self.root/'candidate-004').exists())
    def test_restart_from_ports_after_compile_regression(self):
        c=SimulatedChecker([('enhanced','design_failure'),('compile','design_failure'),(None,'pass')]);g=SimulatedGenerator();self.run_chain(c,g)
        results=[read(self.root/f'candidate-{i:03d}/checks/attempt-0001/result.json') for i in range(3)]
        self.assertTrue(all(r['stages']['ports']['status']=='pass' for r in results));self.assertEqual(results[1]['stages']['functional']['status'],'not_run')
        self.assertIn('compile: bad signal',g.calls[1]);self.assertNotIn('PROTOCOL VIOLATION',g.calls[1])
        self.assertIn('PROTOCOL VIOLATION',g.calls[0]);self.assertNotIn('REFERENCE_RTL_SECRET',g.calls[0]);self.assertNotIn('JASPER_SECRET',g.calls[0])
    def test_earliest_failure_at_each_stage(self):
        for stage in STAGES:
            with self.subTest(stage=stage),tempfile.TemporaryDirectory() as temp:
                c=SimulatedChecker([(stage,'design_failure')]);g=SimulatedGenerator();r=chain(Path(temp),INITIAL,SPEC,IDENTITY,c,g,max_repairs=0)
                self.assertEqual(r['earliest_stage'],stage);self.assertEqual(g.calls,[])
    def test_infrastructure_never_repairs(self):
        for status in ['tool_unavailable','missing_assets','license_failure','timeout','tool_error','transport_error','checker_invalid','inconclusive']:
            with self.subTest(status=status),tempfile.TemporaryDirectory() as temp:
                c=SimulatedChecker([('compile',status)]);g=SimulatedGenerator();r=chain(Path(temp),INITIAL,SPEC,IDENTITY,c,g)
                self.assertEqual(r['status'],'infrastructure_blocked');self.assertEqual(g.calls,[])
    def test_infrastructure_retry_preserves_attempts(self):
        c=SimulatedChecker([('compile','timeout'),(None,'pass')]);g=SimulatedGenerator();self.run_chain(c,g);r=self.run_chain(c,g)
        self.assertEqual(r['status'],'all_repair_checks_passed');self.assertEqual(len(list((self.root/'candidate-000/checks').glob('attempt-*'))),2);self.assertEqual(g.calls,[])
    def test_resume_no_completed_checks_or_generations_repeat(self):
        c=SimulatedChecker([('structural_lint','design_failure'),(None,'pass')]);g=SimulatedGenerator();self.run_chain(c,g);self.run_chain(c,g)
        self.assertEqual(len(c.calls),2);self.assertEqual(len(g.calls),1)
    def test_resume_after_inference_before_outer_commit(self):
        c=SimulatedChecker([('compile','design_failure'),(None,'pass')]);g=SimulatedGenerator(crash=True)
        with self.assertRaises(KeyboardInterrupt):self.run_chain(c,g)
        self.assertFalse((self.root/'candidate-001/candidate-complete.json').exists());self.assertTrue((self.root/'candidate-001/model-generation/complete.json').exists())
        r=self.run_chain(c,g);self.assertEqual(len(g.calls),1);self.assertEqual(r['status'],'all_repair_checks_passed')
    def test_exact_feedback_and_request_preservation(self):
        c=SimulatedChecker([('functional','design_failure'),(None,'pass')]);g=SimulatedGenerator();self.run_chain(c,g)
        parent=self.root/'candidate-000/feedback.txt';child=self.root/'candidate-001/feedback_input.txt';self.assertEqual(parent.read_bytes(),child.read_bytes())
        prompt=(self.root/'candidate-001/user-prompt.txt').read_text();self.assertIn(SPEC.decode(),prompt);self.assertIn(INITIAL.decode(),prompt);self.assertIn(parent.read_text(),prompt)
    def test_candidate_tamper_rejected(self):
        c=SimulatedChecker([(None,'pass')]);g=SimulatedGenerator();self.run_chain(c,g);(self.root/'candidate-000/candidate.sv').write_text('tampered')
        with self.assertRaises(ValueError):self.run_chain(c,g)
    def test_configuration_change_rejected(self):
        c=SimulatedChecker([(None,'pass')]);g=SimulatedGenerator();self.run_chain(c,g)
        with self.assertRaises(ValueError):chain(self.root,INITIAL,SPEC,dict(IDENTITY,arm='lora'),c,g)
    def test_bad_wire_hash_blocks_generation(self):
        def corrupt(candidate,identity,dest):r=outcome(candidate,'compile');r['candidate_sha256']='wrong';return r
        g=SimulatedGenerator();r=self.run_chain(corrupt,g);self.assertEqual(r['status'],'infrastructure_blocked');self.assertEqual(g.calls,[])
    def test_checker_cannot_run_later_stage_after_failure(self):
        r=outcome(INITIAL,'compile');r['stages']['functional']['status']='pass'
        with self.assertRaises(ValueError):validate_check(r,digest(INITIAL))
    def test_protocol_separate_from_cdc_evidence(self):
        c=SimulatedChecker([('enhanced','design_failure')]);g=SimulatedGenerator();self.run_chain(c,g,max_repairs=0);r=read(self.root/'candidate-000/checks/attempt-0001/result.json')
        self.assertEqual(r['stages']['enhanced']['protocol_failures'],['P01']);self.assertEqual(r['stages']['enhanced']['cdc_reset_evidence'],[])
    def test_four_repairs_rejected(self):
        with self.assertRaises(ValueError):self.run_chain(SimulatedChecker([]),SimulatedGenerator(),max_repairs=4)
    def test_generator_failure_not_design_failure(self):
        def broken(*args):raise RuntimeError('GPU unavailable')
        r=self.run_chain(SimulatedChecker([('compile','design_failure')]),broken);self.assertEqual(r['check_status'],'generation_error');self.assertEqual(r['status'],'infrastructure_blocked')
class InterfaceAndClassifierTests(unittest.TestCase):
    def test_ansi_and_nonansi_interfaces(self):
        a='module dut #(parameter W=8) (input wire clk, input [W-1:0] data, output reg ready); endmodule'
        b='module dut(clk,data,ready); input clk; input [7:0] data; output ready; endmodule'
        self.assertEqual(compare(a,b,'dut')['status'],'pass')
        self.assertEqual(compare(a,b.replace('output ready','input ready'),'dut')['status'],'design_failure')
    def test_conditional_ports_and_header_macros(self):
        ref='`ifdef AXI3\nmodule dut(input clk, output [3:0] q);\n`else\nmodule dut(input clk, output [7:0] q);\n`endif\nendmodule'
        self.assertEqual(compare(ref,INITIAL.decode(),'dut')['status'],'pass')
        header='module dut(input [`WIDTH-1:0] clk, output q); endmodule'
        self.assertEqual(compare(header,INITIAL.decode(),'dut')['status'],'pass')
    def test_include_guard_and_optional_ports(self):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp);(p/'defs.v').write_text('`ifndef DEFS\n`define DEFS\n`define OPTIONAL\n`endif\n')
            ref='`include "defs.v"\nmodule dut(input clk\n`ifdef OPTIONAL\n, output q\n`endif\n); endmodule'
            self.assertEqual(compare(ref,INITIAL.decode(),'dut',[p],[p])['status'],'pass')
    def test_canonical_include_paths_and_defines(self):
        dirs,defines=simulation_options('xrun -incdir "$BENCH/fixed/rtl/include" -incdir "$ROOT/vendor/include" -define FOO +define+BAR=1',Path('/root'),Path('/root/benchmarks/dut'),Path('/root/benchmarks/dut/fixed/rtl'))
        self.assertIn(Path('/root/benchmarks/dut/fixed/rtl/include'),dirs);self.assertIn(Path('/root/vendor/include'),dirs);self.assertEqual(defines,['FOO','BAR'])
    def test_missing_top_or_ports(self):
        self.assertEqual(compare(INITIAL.decode(),'module bad(); endmodule','dut')['status'],'design_failure')
        self.assertEqual(compare(INITIAL.decode(),'module dut(input clk); endmodule','dut')['status'],'design_failure')
    def test_truncated_header_and_macro_ports(self):
        self.assertEqual(compare(INITIAL.decode(),'module dut(input clk','dut')['status'],'design_failure')
        self.assertEqual(compare(INITIAL.decode(),'module dut(`PORTS); endmodule','dut')['status'],'inconclusive')
    def test_classification(self):
        for text,expected in [('Unable to obtain license','license_failure'),('xrun timeout 180s','timeout'),('Segmentation fault','tool_error'),('cannot open include file','missing_assets'),('PROTOCOL VIOLATION [P1] data','design_failure')]:
            with self.subTest(text=text):self.assertEqual(classify(False,text,{}),expected)
        self.assertEqual(classify(False,'no marker',{}),'inconclusive')
    def test_real_backend_recovers_durable_inference_without_model_load(self):
        with tempfile.TemporaryDirectory() as temp:
            experiment=Path(temp)/'experiment';experiment.mkdir();save(experiment/'manifest.json',{})
            target=Path(temp)/'candidate';receipt=target/'model-generation';receipt.mkdir(parents=True)
            identity={'repair_number':1};write_once(receipt/'request.txt','exact request');write_once(receipt/'user-prompt.txt','prompt')
            save(receipt/'inference.json',{'response':'module dut(); endmodule','content':'module dut(); endmodule','token_ids':[1,2],'metadata':{'runtime_seconds':3}});seal(receipt,'inference-complete.json',identity)
            generator=QwenGenerator(experiment,'base')
            def must_not_load():raise AssertionError('Completed generation must not load model')
            generator.load=must_not_load
            self.assertEqual(generator('prompt',target,identity),b'module dut(); endmodule')
            self.assertEqual(generator('prompt',target,identity),b'module dut(); endmodule')
            self.assertTrue(verify(receipt,identity=identity))
    def test_wrapper_only_extraction(self):
        self.assertEqual(extract('```verilog\nmodule broken;\n```'),'module broken;\n');self.assertEqual(extract('module broken;'),'module broken;')
class WireTests(unittest.TestCase):
    def test_json_transport_saves_full_logs_and_separates_artifacts(self):
        script="import sys,json; r=json.load(sys.stdin); s=['ports','compile','functional','structural_lint','enhanced']; print(json.dumps(dict(candidate_sha256=r['candidate_sha256'],evaluation_manifest_sha256=None,controls_sha256=None,status='pass',diagnostic='',earliest_stage=None,stages={x:dict(status='pass') for x in s},artifacts={'native/tool.log':'SIMULATED FULL LOG'})))"
        with tempfile.TemporaryDirectory() as temp:
            d=Path(temp);r=CommandChecker([sys.executable,'-c',script])(INITIAL,IDENTITY,d);validate_check(r,digest(INITIAL));self.assertNotIn('artifacts',r);self.assertEqual((d/'checker-artifacts/native/tool.log').read_text(),'SIMULATED FULL LOG')
    def test_binary_checker_artifact_bytes_and_hashes(self):
        raw=b'\x00\xffnative tool log\r\n';import base64
        script="import sys,json; r=json.load(sys.stdin); print(json.dumps(dict(candidate_sha256=r['candidate_sha256'],evaluation_manifest_sha256=None,controls_sha256=None,artifacts={'native/raw.log':dict(encoding='base64',sha256="+repr(digest(raw))+",data="+repr(base64.b64encode(raw).decode())+")})))"
        with tempfile.TemporaryDirectory() as temp:
            d=Path(temp);CommandChecker([sys.executable,'-c',script])(INITIAL,IDENTITY,d);self.assertEqual((d/'checker-artifacts/native/raw.log').read_bytes(),raw)
    def test_checker_artifact_escape_rejected(self):
        script="import json; print(json.dumps(dict(evaluation_manifest_sha256=None,controls_sha256=None,artifacts={'../escape.log':'bad'})))"
        with tempfile.TemporaryDirectory() as temp:
            d=Path(temp);r=CommandChecker([sys.executable,'-c',script])(INITIAL,IDENTITY,d);self.assertEqual(r['status'],'transport_error');self.assertFalse((d/'escape.log').exists())
    def test_transport_error_and_timeout(self):
        for command,timeout,expected in [([sys.executable,'-c','raise SystemExit(255)'],5,'transport_error'),([sys.executable,'-c','import time; time.sleep(2)'],0.02,'timeout')]:
            with self.subTest(expected=expected),tempfile.TemporaryDirectory() as temp:
                r=CommandChecker(command,timeout)(INITIAL,IDENTITY,Path(temp));self.assertEqual(r['status'],expected)
class RealCheckerServiceSimulatedTests(unittest.TestCase):
    """Exercise the real service orchestration with stub tool outcomes only."""
    def service(self,failed=None,control_pass=True,tool_present=True):
        from unittest.mock import patch
        from types import SimpleNamespace
        from cdc_repair.checker import check
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)/'evaluator';bench=root/'benchmarks/dut';(bench/'fixed/rtl').mkdir(parents=True);(bench/'sim').mkdir();(bench/'manifest.yaml').write_text('fixture')
            top=bench/'fixed/rtl/dut.v';top.write_bytes(INITIAL);(bench/'sim/run.sh').write_text('xrun')
            manifest=Path(temp)/'assets.json';save(manifest,{'assets':[]});controls=Path(temp)/'controls.json';save(controls,{'evaluation_manifest_sha256':digest(manifest.read_bytes()),'golden':{'dut':{s:'pass' if control_pass else 'checker_invalid' for s in STAGES}}})
            calls=[]
            def response(stage,dest,key):
                calls.append(stage);p=dest/(stage+'.log');p.parent.mkdir(parents=True,exist_ok=True)
                text='xmvlog: *E, syntax failure' if stage=='compile' else 'PROTOCOL VIOLATION [P1] unstable' if stage=='enhanced' else 'TESTS FAILED'
                p.write_text(text if failed==stage else 'ALL TESTS PASSED');return {key:failed!=stage,'log':str(p)}
            ev=SimpleNamespace(top_rtl_for=lambda c:top,manifest_scalar=lambda c,k:'dut' if k=='top_module' else 'sim/run.sh',evaluate=lambda r,c,d:response('compile',d,'compile_ok'))
            base=SimpleNamespace(simulate=lambda r,c,d:response('functional',d,'simulate_ok'))
            def enhanced(row):
                data=response('enhanced',root/'build/fake-enhanced','ok');data['status']='PASS' if data.pop('ok') else 'FAIL';return data
            en=SimpleNamespace(run_one=enhanced,runtime_text=lambda text:text)
            def lint(*args):calls.append('structural_lint');return [{'rule_id':'CDC-T','message':'simulated lint hit'}] if failed=='structural_lint' else []
            lint_module=SimpleNamespace(lint_findings=lint)
            candidate=INITIAL if failed!='ports' else b'module wrong(); endmodule'
            request={'circuit':'dut','candidate':candidate.decode(),'candidate_sha256':digest(candidate),'evaluation_manifest_sha256':digest(manifest.read_bytes()),'controls_sha256':digest(controls.read_bytes())}
            with patch('cdc_repair.checker.setup',return_value=(root,ev,base,en,lint_module)),patch('cdc_repair.checker.shutil.which',return_value='/SIMULATED/xrun' if tool_present else None):
                result=check(request,root,manifest,Path(temp)/'work',controls)
            validate_check(result,digest(candidate));return result,calls
    def test_real_service_stops_at_each_earliest_failure(self):
        for stage in STAGES:
            with self.subTest(stage=stage):
                result,calls=self.service(stage);self.assertEqual(result['earliest_stage'],stage);self.assertEqual(result['status'],'design_failure');self.assertEqual(calls,list(STAGES[1:STAGES.index(stage)+1]))
    def test_real_service_all_pass_runs_in_order(self):
        result,calls=self.service();self.assertEqual(result['status'],'pass');self.assertEqual(calls,list(STAGES[1:]))
    def test_real_service_infrastructure_gates(self):
        for kwargs,expected in [({'control_pass':False},'checker_invalid'),({'tool_present':False},'tool_unavailable')]:
            result,calls=self.service(**kwargs);self.assertEqual(result['earliest_stage'],'compile');self.assertEqual(result['status'],expected);self.assertEqual(calls,[])
    def test_real_service_protocol_artifacts_do_not_become_cdc(self):
        result,calls=self.service('enhanced');self.assertTrue(result['stages']['enhanced']['protocol_failures']);self.assertFalse(result['stages']['enhanced']['cdc_reset_evidence'])
if __name__=='__main__':unittest.main()

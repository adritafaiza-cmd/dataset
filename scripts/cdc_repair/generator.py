"""Lazy single-GPU BF16 Qwen3.8 backend with a durable generation receipt."""
import json,os,re,time,platform
from pathlib import Path
from .core import read,save,seal,verify,sha,write_once

def extract(text):
    blocks=re.findall(r'^```(?:verilog|systemverilog|sv|v)?[ \t]*\r?\n(.*?)^```[ \t]*$',text,flags=re.M|re.S|re.I)
    return '\n'.join(blocks) if blocks else text

class QwenGenerator:
    def __init__(self,experiment,arm):
        self.experiment=Path(experiment);self.arm=arm;self.manifest=read(self.experiment/'manifest.json');self.loaded=False
    def load(self):
        os.environ.setdefault('CUBLAS_WORKSPACE_CONFIG',':4096:8')
        os.environ.setdefault('HF_HUB_OFFLINE','1');os.environ.setdefault('TRANSFORMERS_OFFLINE','1')
        import torch,transformers
        from transformers import AutoTokenizer,Qwen3_5ForConditionalGeneration,GenerationConfig
        if not torch.cuda.is_available() or torch.cuda.device_count()!=1:raise RuntimeError('Exactly one visible NVIDIA GPU is required')
        torch.use_deterministic_algorithms(True);torch.backends.cuda.matmul.allow_tf32=False;torch.backends.cudnn.allow_tf32=False;torch.backends.cudnn.benchmark=False;torch.backends.cudnn.deterministic=True
        m=self.manifest;self.torch=torch;self.transformers=transformers
        self.tokenizer=AutoTokenizer.from_pretrained(m['model_path'],revision=m['model_revision'],trust_remote_code=False)
        self.model=Qwen3_5ForConditionalGeneration.from_pretrained(m['model_path'],revision=m['model_revision'],dtype=torch.bfloat16,device_map={'':0},attn_implementation='sdpa',trust_remote_code=False).eval()
        self.adapter_status=None
        if self.arm=='lora':
            from peft import PeftModel
            adapter=self.experiment/'adapter'
            for name,h in m['adapter_sha256'].items():
                if sha(adapter/name)!=h:raise ValueError('Frozen adapter hash mismatch')
            self.model=PeftModel.from_pretrained(self.model,str(adapter),is_trainable=False,autocast_adapter_dtype=False).eval();status=self.model.get_model_status()
            if not status.enabled or status.active_adapters!=['default'] or status.num_adapter_layers<1:raise RuntimeError('LoRA adapter is not active')
            self.adapter_status={'active_adapters':status.active_adapters,'num_adapter_layers':status.num_adapter_layers,'sha256':m['adapter_sha256']}
        if any(p.device.type!='cuda' or p.dtype!=torch.bfloat16 for p in self.model.parameters()):raise RuntimeError('Model must be BF16 entirely on GPU')
        eos=self.model.generation_config.eos_token_id
        if eos is None:raise RuntimeError('Missing pinned model EOS')
        self.eos=eos if isinstance(eos,list) else [eos]
        pad=self.tokenizer.pad_token_id
        self.config=GenerationConfig(**m['settings'],eos_token_id=eos,pad_token_id=pad if pad is not None else self.eos[0],bos_token_id=self.model.generation_config.bos_token_id)
        self.loaded=True
    def __call__(self,user_prompt,target,identity):
        receipt=target/'model-generation';receipt.mkdir(exist_ok=True)
        if verify(receipt,identity=identity):return (receipt/'candidate.sv').read_bytes()
        if verify(receipt,'inference-complete.json',identity):return self.finish(receipt,identity)
        if not self.loaded:self.load()
        torch=self.torch;tokenizer=self.tokenizer
        write_once(receipt/'user-prompt.txt',user_prompt)
        request=tokenizer.apply_chat_template([{'role':'user','content':user_prompt}],tokenize=False,add_generation_prompt=True,enable_thinking=False)
        write_once(receipt/'request.txt',request)
        inputs=tokenizer(request,add_special_tokens=False,return_tensors='pt',truncation=False)
        count=inputs.input_ids.shape[1]
        if count+self.manifest['settings']['max_new_tokens']>self.model.config.text_config.max_position_embeddings:raise RuntimeError('Prompt exceeds model context; inputs will not be truncated')
        inputs={k:v.to('cuda:0') for k,v in inputs.items()};seed=self.manifest['seed']+identity['repair_number'];self.transformers.set_seed(seed)
        torch.cuda.synchronize();start=time.monotonic()
        with torch.inference_mode():sequence=self.model.generate(**inputs,generation_config=self.config)
        torch.cuda.synchronize();elapsed=time.monotonic()-start
        tokens=sequence[0,count:].tolist();ended=bool(tokens and tokens[-1] in self.eos)
        response=tokenizer.decode(tokens,skip_special_tokens=False,clean_up_tokenization_spaces=False)
        content=tokenizer.decode(tokens[:-1] if ended else tokens,skip_special_tokens=False,clean_up_tokenization_spaces=False)
        metadata={'generation_config':self.config.to_dict(),'seed':seed,'input_tokens':count,'output_tokens':len(tokens),'termination_reason':'eos' if ended else 'max_new_tokens','runtime_seconds':elapsed,'adapter_status':self.adapter_status,'model':self.manifest['model_path'],'revision':self.manifest['model_revision'],'precision':'bfloat16','torch':torch.__version__,'transformers':self.transformers.__version__,'gpu':torch.cuda.get_device_name(0),'python':platform.python_version(),'attention':'sdpa','deterministic_algorithms':True,'chat_template':tokenizer.chat_template}
        save(receipt/'inference.json',{'response':response,'content':content,'token_ids':tokens,'metadata':metadata})
        seal(receipt,'inference-complete.json',identity)
        return self.finish(receipt,identity)
    @staticmethod
    def finish(receipt,identity):
        # Resume finalization after durable inference without loading a tokenizer,
        # model, GPU, or running generate again.
        if not verify(receipt,'inference-complete.json',identity):raise ValueError('Incomplete inference receipt')
        data=read(receipt/'inference.json')
        write_once(receipt/'response.txt',data['response'])
        save(receipt/'response.json',{'token_ids':data['token_ids'],'text':data['response']})
        write_once(receipt/'candidate.sv',extract(data['content']))
        save(receipt/'metadata.json',data['metadata'])
        seal(receipt,identity=identity)
        return (receipt/'candidate.sv').read_bytes()

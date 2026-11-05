"""Conservative Verilog top/port check; unsupported syntax is infrastructure evidence."""
import re
from pathlib import Path

def preprocess(text,include_dirs=(),defines=None,depth=0):
    if depth>32:raise NotImplementedError('include nesting exceeds supported limit')
    macros=set(defines or ());stack=[];active=True;out=[]
    text=re.sub(r'/\*.*?\*/|//[^\n]*','',text,flags=re.S)
    text=text.replace('\\\n',' ')
    for line in text.splitlines():
        m=re.match(r'\s*`(ifdef|ifndef|elsif|else|endif|define|undef|include)\b(.*)',line)
        if not m:
            if active:out.append(line)
            continue
        kind,arg=m.group(1),m.group(2).strip();name=re.match(r'\w+',arg);name=name.group() if name else ''
        if kind in ('ifdef','ifndef'):
            cond=name in macros;cond=not cond if kind=='ifndef' else cond;stack.append([active,cond]);active=active and cond
        elif kind=='elsif':
            if not stack:raise NotImplementedError('unmatched preprocessor elsif')
            parent,taken=stack[-1];cond=not taken and name in macros;stack[-1][1]=taken or cond;active=parent and cond
        elif kind=='else':
            if not stack:raise NotImplementedError('unmatched preprocessor else')
            parent,taken=stack[-1];active=parent and not taken;stack[-1][1]=True
        elif kind=='endif':
            if not stack:raise NotImplementedError('unmatched preprocessor endif')
            active=stack.pop()[0]
        elif active and kind=='define':macros.add(name)
        elif active and kind=='undef':macros.discard(name)
        elif active and kind=='include':
            match=re.fullmatch(r'"([^"\n]+)"',arg)
            if not match:raise NotImplementedError('unsupported include directive')
            paths=[Path(d)/match.group(1) for d in include_dirs];path=next((p for p in paths if p.is_file()),None)
            if path is None:raise NotImplementedError('missing port-preprocessor include '+match.group(1))
            included,macros=preprocess(path.read_text(),[path.parent,*include_dirs],macros,depth+1);out.append(included)
    if stack:raise NotImplementedError('unmatched preprocessor conditional')
    return '\n'.join(out),macros

def interface(text,top,include_dirs=(),defines=None):
    text,_=preprocess(text,include_dirs,defines)
    matches=list(re.finditer(r'\bmodule\s+(?:automatic\s+)?'+re.escape(top)+r'\b',text))
    if len(matches)!=1:raise ValueError(f'expected exactly one module {top}; found {len(matches)}')
    pos=matches[0].end()
    def space(p):
        while p<len(text) and text[p].isspace():p+=1
        return p
    def group(p):
        if p>=len(text) or text[p]!='(':raise ValueError('unsupported or missing module port header')
        start=p+1;depth=1;p+=1
        while p<len(text) and depth:
            depth+=(text[p]=='(')-(text[p]==')');p+=1
        if depth:raise ValueError('unterminated module header')
        return text[start:p-1],p
    pos=space(pos)
    if pos<len(text) and text[pos]=='#':_,pos=group(space(pos+1));pos=space(pos)
    header,pos=group(pos);body=text[pos:].split('endmodule',1)[0];ports={};direction=None
    for chunk in header.split(','):
        chunk=chunk.strip()
        if not chunk:continue
        if re.search(r'`|\\|\.',re.sub(r'\[[^\]]*\]',' ',chunk)):raise NotImplementedError('macro/escaped/interface port syntax requires manual checker support')
        m=re.search(r'\b(input|output|inout)\b',chunk)
        if m:direction=m.group(1)
        clean=re.sub(r'\[[^\]]*\]',' ',chunk).split('=')[0]
        names=re.findall(r'[A-Za-z_$][\w$]*',clean)
        if not names:raise ValueError('missing port identifier')
        name=names[-1]
        if name in ports:raise ValueError('duplicate port '+name)
        ports[name]=direction
    if any(d is None for d in ports.values()):
        for match in re.finditer(r'\b(input|output|inout)\b([^;]+);',body):
            clean=re.sub(r'\[[^\]]*\]',' ',match.group(2))
            for chunk in clean.split(','):
                names=re.findall(r'[A-Za-z_$][\w$]*',chunk.split('=')[0])
                if names and names[-1] in ports:ports[names[-1]]=match.group(1)
    if any(d is None for d in ports.values()):raise NotImplementedError('unresolved non-ANSI port directions')
    return ports

def compare(reference,candidate,top,reference_dirs=(),candidate_dirs=(),defines=None):
    try:expected=interface(reference,top,reference_dirs,defines)
    except Exception as exc:return {'status':'checker_invalid','diagnostic':'','details':str(exc)}
    try:actual=interface(candidate,top,candidate_dirs,defines)
    except NotImplementedError as exc:return {'status':'inconclusive','diagnostic':'','details':str(exc)}
    except ValueError as exc:return {'status':'design_failure','diagnostic':str(exc)}
    missing=sorted(set(expected)-set(actual));extra=sorted(set(actual)-set(expected));wrong=sorted(k for k in set(expected)&set(actual) if expected[k]!=actual[k])
    if missing or extra or wrong:return {'status':'design_failure','diagnostic':f'Port mismatch: missing={missing}; unexpected={extra}; direction_mismatch={wrong}'}
    return {'status':'pass','diagnostic':'','details':{'ports':expected,'scope':'module, names and directions; widths and elaboration handled by compile'}}

def simulation_options(script,root,bench,reference_parent):
    """Read static include directories/defines from the canonical xrun script."""
    dirs=[Path(reference_parent)];defines=re.findall(r'-define\s+["\']?(\w+)',script)
    for token in re.findall(r'-incdir\s+("[^"]+"|\S+)',script):
        value=token.strip('"').replace('${ROOT}',str(root)).replace('$ROOT',str(root)).replace('${BENCH}',str(bench)).replace('$BENCH',str(bench))
        if '$' in value or '`' in value:raise NotImplementedError('dynamic include directory requires checker integration support')
        dirs.append(Path(value))
    for token in re.findall(r'\+define\+([^\s"\']+)',script):defines.extend(x.split('=')[0] for x in token.split('+'))
    return dirs,defines

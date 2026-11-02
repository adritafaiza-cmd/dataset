import urllib.request,json,sys
from pathlib import Path
out=Path(__file__).parent
for repo in sys.argv[1:]:
 key=repo.split('/')[-1]
 def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'CDC-training-collection'}),timeout=60).read()
 try:
  commit=json.loads(get(f'https://api.github.com/repos/{repo}/commits/HEAD'))['sha']
  lic=json.loads(get(f'https://api.github.com/repos/{repo}/license?ref={commit}'))
  raw=get(lic['download_url']);(out/f'{key}-LICENSE').write_bytes(raw)
  data={'repo':repo,'commit':commit,'license_path':lic['path'],'license_spdx':lic.get('license',{}).get('spdx_id')};(out/f'{key}-meta.json').write_text(json.dumps(data,indent=2));print(data,flush=True)
 except Exception as e:print(repo,str(e),flush=True)

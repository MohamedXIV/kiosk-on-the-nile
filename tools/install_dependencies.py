"""Fetch pinned upstream artifacts; reject any integrity mismatch before extraction."""
import hashlib, io, json, os, pathlib, shutil, subprocess, urllib.request, zipfile
ROOT=pathlib.Path(__file__).resolve().parent.parent
CACHE=ROOT/'.cache'; CACHE.mkdir(exist_ok=True)
lock=json.loads((ROOT/'tools/dependencies.lock.json').read_text())
def artifact(name):
 item=lock[name]; path=CACHE/'downloads'/item['url'].rsplit('/',1)[-1]; path.parent.mkdir(exist_ok=True)
 if not path.exists():
  print('Downloading',name,flush=True)
  temp=path.with_suffix('.part')
  with urllib.request.urlopen(item['url'],timeout=60) as response,temp.open('wb') as out: shutil.copyfileobj(response,out)
  temp.replace(path)
 digest=hashlib.file_digest(path.open('rb'),'sha256').hexdigest()
 if digest!=item['sha256']: raise RuntimeError(f'{name}: authoritative SHA256 mismatch; refusing artifact')
 print('Verified',name,flush=True)
 return path
engine=artifact('godot')
with zipfile.ZipFile(engine) as z:
 name=next(n for n in z.namelist() if n.endswith('linux.x86_64'))
 destination=CACHE/'bin'/'godot-4.7.2'; destination.parent.mkdir(exist_ok=True)
 if not destination.exists(): destination.write_bytes(z.read(name)); destination.chmod(0o755)
compiler=artifact('ink')
compiler_dir=CACHE/'inklecate'
if not (compiler_dir/'inklecate').exists():
 with zipfile.ZipFile(compiler) as z:z.extractall(compiler_dir)
 (compiler_dir/'inklecate').chmod(0o755)
plugin=CACHE/'inkgd-upstream'
if not plugin.exists():subprocess.run(['git','clone','--filter=blob:none','--no-checkout',lock['inkgd']['repository'],str(plugin)],check=True)
subprocess.run(['git','-C',str(plugin),'fetch','--depth','1','origin',lock['inkgd']['commit']],check=True,stdout=subprocess.DEVNULL)
if not (ROOT/'addons/inkgd/ink_player.gd').exists():
 data=subprocess.check_output(['git','-C',str(plugin),'archive','--format=zip',lock['inkgd']['commit'],'addons/inkgd'])
 with zipfile.ZipFile(io.BytesIO(data)) as z:z.extractall(ROOT)
 license_data=subprocess.check_output(['git','-C',str(plugin),'show',lock['inkgd']['commit']+':LICENSE'])
 (ROOT/'addons/inkgd/UPSTREAM_LICENSE.txt').write_bytes(license_data)
font=ROOT/'assets/fonts/Cairo.ttf'
if not font.exists():
 d=json.load(urllib.request.urlopen('https://api.github.com/repos/google/fonts/contents/ofl/cairo',timeout=30))
 for entry in d:
  if entry['name'].endswith('.ttf') or entry['name']=='OFL.txt':
   data=urllib.request.urlopen(entry['download_url'],timeout=30).read()
   blob=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
   if blob!=entry['sha']:raise RuntimeError('Font upstream Git blob verification failed')
   target=font if entry['name'].endswith('.ttf') else font.with_name('OFL.txt')
   target.write_bytes(data)
   print('Verified font asset',target.name,flush=True)
templates=artifact('templates')
template_dir=CACHE/'data/godot/export_templates/4.7.2.stable'; template_dir.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(templates) as z:
 for member in z.namelist():
  basename=pathlib.PurePosixPath(member).name
  if (basename.startswith('web_') and basename.endswith('.zip')) or basename=='version.txt':
   target=template_dir/basename
   if not target.exists():target.write_bytes(z.read(member))
print('Pinned dependencies ready',flush=True)

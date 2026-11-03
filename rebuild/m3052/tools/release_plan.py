#!/usr/bin/env python3
"""Only native/bootstrap changes require an APK; game changes produce signed data."""
import hashlib,json,re,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def bootstrap_hash():
 paths=[ROOT/'project.godot',ROOT/'export_presets.cfg']
 paths+=sorted(p for p in (ROOT/'updater').glob('*') if p.suffix in ['.gd','.tscn','.json'])
 paths+=sorted(p for p in (ROOT/'tools/android_updater').glob('*') if p.suffix in ['.java','.xml','.py'])
 h=hashlib.sha256()
 for p in paths:
  h.update(str(p.relative_to(ROOT)).encode());h.update(b'\0');h.update(p.read_bytes())
 return h.hexdigest()
def main():
 code=int(re.search(r'VERSION_CODE\s*:?=\s*(\d+)',(ROOT/'updater/update_model.gd').read_text()).group(1))
 old_path=ROOT.parents[1]/'updates/latest.json'
 old=json.loads(old_path.read_text()).get('latest',{}) if old_path.exists() else {}
 needed=code>int(old.get('version_code',0))
 if code<int(old.get('version_code',0)):raise RuntimeError('Android version cannot go backwards')
 if not needed and old.get('bootstrap_sha256')!=bootstrap_hash():raise RuntimeError('Bootstrap changed: bump Android version before release')
 result={'shell_needed':str(needed).lower(),'code':str(code),'bootstrap_sha256':bootstrap_hash()}
 if os.environ.get('GITHUB_OUTPUT'):
  with open(os.environ['GITHUB_OUTPUT'],'a') as f:
   for k,v in result.items():f.write(f'{k}={v}\n')
 print(json.dumps(result))
if __name__=='__main__':main()

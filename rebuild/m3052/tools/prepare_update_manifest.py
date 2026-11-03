#!/usr/bin/env python3
"""Prepare distribution metadata privately; this does not publish an update."""
import hashlib,json,sys
from pathlib import Path
apk=Path(sys.argv[1]).resolve()
report=json.loads(apk.with_suffix('.build.json').read_text())
assert report['signature']=='PASS' and report['updater_native']
assert report['certificate_sha256']=='278a2899340d58b3db0aced5e0f306ebb121550bc34dc1e6948783424652fe3b'
assert report['sha256']==hashlib.sha256(apk.read_bytes()).hexdigest()
assert report['bytes']==apk.stat().st_size
code=report['version_code']
latest={k:report[k] for k in ['version_code','package','certificate_sha256','bytes','sha256','bootstrap_sha256']}
latest['url']=f'https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases/download/abyssal-{code}-android/ABYSSAL_DOMINION_{code}.apk'
apk.with_name('latest.json').write_text(json.dumps({'schema':1,'channel':'test','latest':latest},indent=2)+'\n')
print('MANIFEST_PREPARED: publish only after verified APK release')

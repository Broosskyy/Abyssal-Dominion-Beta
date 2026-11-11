"""Embed generated GLB-derived fleet metadata in the exported provenance index."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
metadata=json.loads((root/'assets/classic_baked/manifest.json').read_text())
assert metadata['status']=='BAKED_FROM_ORIGINAL_GLBS' and metadata['angles']==8
assert len(metadata['atlases'])==23
for entry in metadata['atlases']:
    assert len(entry['frames'])==8 and entry['reference_extent']>0
    assert (root/'assets/classic_baked'/f"{entry['name']}.png").stat().st_size>4000
index=root/'assets/provenance.json'
catalog=json.loads(index.read_text())
catalog['classic_fleet']=metadata
index.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
print('PASS: 23 source-GLB Classic atlases embedded for native exports')

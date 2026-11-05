#!/usr/bin/env python3
"""Remove nonphysical spike triangles from decimated Meshy GLB ship meshes.
No external packages: patches only binary index triplets, preserving PNG/PBR
buffers, vertex positions and original model identity. The damage was caused
by UV-aware quadric decimation merging distant vertices across mesh seams.
"""
import json
import math
from pathlib import Path
import struct

ROOT=Path(__file__).resolve().parents[1]
MODEL_DIR=ROOT/'assets/npc/meshy/models'
OUT=ROOT/'assets/npc/meshy/repair_report.json'

def repair(path):
    raw=bytearray(path.read_bytes())
    if raw[:4]!=b'glTF':raise ValueError('Not a GLB: '+str(path))
    total=struct.unpack_from('<I',raw,8)[0]
    if len(raw)!=total:raise ValueError('GLB truncated: '+str(path))
    chunk_len,chunk_type=struct.unpack_from('<II',raw,12)
    if chunk_type!=0x4e4f534a:raise ValueError('GLB missing JSON')
    document=json.loads(raw[20:20+chunk_len])
    bin_off=20+chunk_len+8
    if raw[bin_off-4:bin_off]!=b'BIN\0':raise ValueError('GLB missing BIN')
    def accessor(index):
        acc=document['accessors'][index]
        view=document['bufferViews'][acc['bufferView']]
        offset=bin_off+view.get('byteOffset',0)+acc.get('byteOffset',0)
        return acc,view,offset
    removed=0;scanned=0
    for mesh in document.get('meshes',[]):
        for primitive in mesh.get('primitives',[]):
            if primitive.get('mode',4)!=4:continue
            index_acc,index_view,index_start=accessor(primitive['indices'])
            position_acc,position_view,position_start=accessor(primitive['attributes']['POSITION'])
            component={5121:'B',5123:'H',5125:'I'}[index_acc['componentType']]
            index_stride=index_view.get('byteStride',struct.calcsize('<'+component))
            point_stride=position_view.get('byteStride',12)
            indices=index_acc['count'];positions=position_acc['count']
            if indices%3:raise ValueError('Invalid triangle indices: '+str(path))
            points=[struct.unpack_from('<fff',raw,position_start+i*point_stride) for i in range(positions)]
            for face in range(indices//3):
                ids=[struct.unpack_from('<'+component,raw,index_start+(face*3+i)*index_stride)[0] for i in range(3)]
                if any(idx>=positions for idx in ids):raise ValueError('Vertex index overflow: '+str(path))
                a,b,c=[points[idx] for idx in ids]
                ab=[b[d]-a[d] for d in range(3)]
                ac=[c[d]-a[d] for d in range(3)]
                edges=(
                    sum((a[d]-b[d])**2 for d in range(3)),
                    sum((b[d]-c[d])**2 for d in range(3)),
                    sum((c[d]-a[d])**2 for d in range(3))
                )
                biggest=max(edges)
                if biggest <= .32**2:continue
                cross=(
                    ab[1]*ac[2]-ab[2]*ac[1],
                    ab[2]*ac[0]-ab[0]*ac[2],
                    ab[0]*ac[1]-ab[1]*ac[0]
                )
                twice_area=math.sqrt(sum(v*v for v in cross))
                aspect=biggest/max(twice_area,1e-12)
                spike=(biggest>1.0**2 or (biggest>.32**2 and aspect>22.0) or
                       (biggest>.55**2 and aspect>10.0))
                if spike and ids[0]!=ids[1]:
                    # Degenerate triangle: no render, no shifts in glTF offsets,
                    # no damage to other triangles or PBR image buffer data.
                    for vertex in (1,2):
                        struct.pack_into('<'+component,raw,index_start+(face*3+vertex)*index_stride,ids[0])
                    removed+=1
                scanned+=1
    if removed:path.write_bytes(raw)
    return {'file':path.name,'triangles_scanned':scanned,'spikes_removed':removed,'bytes':len(raw)}

def main():
    results=[repair(path) for path in sorted(MODEL_DIR.glob('*.glb'))]
    if len(results)!=9:raise ValueError('Expected all nine Meshy NPC GLBs')
    OUT.write_text(json.dumps({'schema':1,'description':'Preserve actual GLB ships; discard broken extreme UV-decimation spikes','models':results},indent=2)+'\n')
    print(json.dumps({'models':len(results),'spikes_removed':sum(r['spikes_removed'] for r in results),'details':results}))

if __name__=='__main__':main()

#!/usr/bin/env python3
"""M392 island asset acceptance gate.

No external APIs, no Meshy credit usage and no placeholder approval.
Every asset has a stable ID and a deterministic preview slot. Pending assets
are valid catalog entries but are NEVER treated as shipped image content.
Approved PNG requires a separate reviewed silhouette with matching checksums.

Usage:
  python3 tools/validate_m392_islands.py
  python3 tools/validate_m392_islands.py --report /tmp/m392-report.json
  python3 tools/validate_m392_islands.py --require-approved  # final art milestone
"""
from __future__ import annotations

import argparse
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"assets/visuals/m392_island_catalog.json"
IDS={f"{r}{i:02d}" for r in "ABCDE" for i in range(1,7)}
SIZES={"small","medium","large","landmark"}
LEGACY={"tropical","rock","snow","snow2"}
STAGES={"planned","reference","in_review","approved"}


def require(ok:bool,message:str)->None:
    if not ok:raise ValueError(message)


def source_path(path:str,asset_id:str,folder:str,extension:str)->Path:
    assert folder.startswith("assets/m392/")
    expected=f"res://{folder}/{asset_id.lower()}{extension}"
    require(path==expected,f"{asset_id}: path must be {expected}")
    output=(ROOT/path.removeprefix("res://")).resolve()
    require(output.is_relative_to(ROOT.resolve()),f"{asset_id}: attempted path traversal")
    return output


def _poly_area(points:list[list[float]])->float:
    return .5*abs(sum(p[0]*q[1]-q[0]*p[1]
                       for p,q in zip(points,points[1:]+points[:1])))


def _orientation(a,b,c)->float:
    return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])


def _proper_cross(a,b,c,d)->bool:
    p=_orientation(a,b,c)
    q=_orientation(a,b,d)
    r=_orientation(c,d,a)
    s=_orientation(c,d,b)
    return p*q<0 and r*s<0


def _contains(point:tuple[float,float],points:list[list[float]])->bool:
    x,y=point
    found=False
    prev=points[-1]
    for curr in points:
        ax,ay=prev
        bx,by=curr
        if (ay>y)!=(by>y) and x<(bx-ax)*(y-ay)/(by-ay)+ax:
            found=not found
        prev=curr
    return found


def _check_collision(path:Path,asset_id:str,image)->None:
    raw=json.loads(path.read_text(encoding="utf-8"))
    require(raw.get("schema")==1,f"{asset_id}: bad shoreline schema")
    require(raw.get("asset_id")==asset_id and raw.get("reviewed") is True,
            f"{asset_id}: shoreline not independently reviewed")
    points=raw.get("points")
    require(isinstance(points,list) and 8<=len(points)<=512,
            f"{asset_id}: shoreline needs 8..512 vertices")
    require(all(isinstance(p,list) and len(p)==2 and
                all(isinstance(v,(int,float)) and 0<=v<=1 for v in p)
                for p in points),f"{asset_id}: invalid normalized silhouette vertices")
    require(list(raw.get("size",[]))==list(image.size),
            f"{asset_id}: collision size differs from real approved PNG")
    require(.03<=_poly_area(points)<=.85,f"{asset_id}: suspicious coastline area")
    for i in range(len(points)):
        for j in range(i+2,len(points)):
            if i==0 and j==len(points)-1:continue
            require(not _proper_cross(points[i],points[(i+1)%len(points)],
                                      points[j],points[(j+1)%len(points)]),
                    f"{asset_id}: self-intersecting coastline")
    # Confirm reviewed collision is mostly placed on visible island pixels.
    # This is a coarse automated safety test, NOT a substitute for judging
    # docks/coves/ship-sized navigation in the Godot map itself.
    alpha=image.getchannel("A")
    covered=opaque=0
    for iy in range(12,88):
        for ix in range(8,92):
            x=(ix+.5)/100
            y=(iy+.5)/100
            if _contains((x,y),points):
                covered+=1
                if alpha.getpixel((min(image.width-1,int(x*image.width)),
                                   min(image.height-1,int(y*image.height))))>=180:
                    opaque+=1
    require(covered>80 and opaque/covered>=.74,
            f"{asset_id}: collision over transparent water / silhouette disagreement")


def _check_image(path:Path,asset_id:str):
    try:
        from PIL import Image
    except ImportError as exc:
        raise ValueError("Install free Pillow package to validate approved PNGs") from exc
    with Image.open(path) as im:
        require(im.format=="PNG" and im.mode=="RGBA",
                f"{asset_id}: source must be genuine RGBA PNG")
        require(512<=im.width<=4096 and 512<=im.height<=4096,
                f"{asset_id}: unsuitable dimensions {im.size}")
        alpha=im.getchannel("A")
        min_a,max_a=alpha.getextrema()
        require(min_a==0 and max_a==255,
                f"{asset_id}: requires transparent background and fully opaque land")
        rect=alpha.getbbox()
        require(rect is not None and rect[0]>=8 and rect[1]>=8
                and rect[2]<=im.width-8 and rect[3]<=im.height-8,
                f"{asset_id}: subject cropped to frame / not isolated")
        histogram=alpha.histogram()
        transparent=histogram[0]/(im.width*im.height)
        require(.07<transparent<.89,
                f"{asset_id}: alpha background ratio is invalid ({transparent:.1%})")
        im.load()
        return im.copy()


def validate(require_approved:bool=False)->dict:
    data=json.loads(MANIFEST.read_text(encoding="utf-8"))
    require(data.get("schema")==1,"island catalog schema must be 1")
    require(len(data.get("regions",[]))==5,"exactly five island regions required")
    require([(r["id"],r["realm_min"],r["realm_max"]) for r in data["regions"]]
            ==[(name,i*4+1,i*4+4) for i,name in enumerate("ABCDE")],
            "regional realm ranges must match M388 20-map geography")
    assets=data.get("items",[])
    require(len(assets)==30,"M392 requires precisely 30 first-wave island definitions")
    ids=[a.get("id") for a in assets]
    require(set(ids)==IDS and len(ids)==len(set(ids)),"missing or repeated 30 stable IDs")
    stats={"catalog":data["catalog"],"schema":1,"definitions":len(assets),
           "approved_png":0,"pending_png":0,"reference_only":0,
           "by_region":dict(Counter(a["region"] for a in assets)),
           "approved_ids":[],"pending_ids":[],"gameplay_swap_ready":False}
    for a in assets:
        asset_id=str(a["id"])
        require(re.fullmatch(r"[A-E]0[1-6]",asset_id) is not None,f"invalid {asset_id}")
        require(a.get("region")==asset_id[0],f"{asset_id}: wrong biome")
        require(a.get("size_class") in SIZES,f"{asset_id}: invalid size class")
        require(a.get("fallback_art") in LEGACY,f"{asset_id}: unknown playable fallback")
        require(a.get("status") in STAGES,f"{asset_id}: invalid stage")
        require(bool(a.get("name")) and len(str(a.get("description","")))>12
                and len(str(a.get("reference_prompt","")))>50,
                f"{asset_id}: missing master art brief")
        png=source_path(a.get("source_png",""),asset_id,"assets/m392/islands",".png")
        mesh=source_path(a.get("mesh_glb",""),asset_id,"assets/m392/models",".glb")
        collision=source_path(a.get("collision_json",""),asset_id,"assets/m392/collision",".json")
        for suffix,count in [("4",4),("8",8)]:
            prefix=f"res://assets/m392/views/{asset_id.lower()}_{suffix}"
            require(a.get("views_"+suffix)==prefix,
                    f"{asset_id}: missing {count}-view sprite directory")
        approved=a.get("status")=="approved"
        require(bool(a.get("approved"))==approved,
                f"{asset_id}: inconsistent art approval flag")
        if not approved:
            require(not a.get("collision_reviewed",False) and not a.get("sha256_png")
                    and not a.get("sha256_collision"),
                    f"{asset_id}: pending art cannot pretend to have verified collision checksums")
            stats["pending_png"]+=1
            stats["pending_ids"].append(asset_id)
            if a["status"]=="reference":stats["reference_only"]+=1
            continue
        require(bool(a.get("collision_reviewed",False)),f"{asset_id}: coastline must be independently approved")
        require(png.is_file() and collision.is_file(),
                f"{asset_id}: cannot approve without real PNG and paired coastline")
        for path,field in [(png,"sha256_png"),(collision,"sha256_collision")]:
            signature=sha256(path.read_bytes()).hexdigest()
            require(signature==a.get(field),f"{asset_id}: {path.name} checksum mismatch")
        image=_check_image(png,asset_id)
        _check_collision(collision,asset_id,image)
        if mesh.exists():
            require(mesh.stat().st_size>2000,f"{asset_id}: GLB not real")
            # GLBs are optional. When supplied, CI additionally expects a
            # built four- or eight-angle sprite set, not an imaginary export.
            frames=[]
            for direction in (4,8):
                folder=ROOT/"assets/m392/views"/f"{asset_id.lower()}_{direction}"
                if folder.is_dir():
                    current=sorted(folder.glob("*.png"))
                    require(len(current)==direction,
                            f"{asset_id}: {direction}-angle bake must contain exactly {direction} PNGs")
                    for frame in current:_check_image(frame,asset_id)
                    frames.append(direction)
            require(bool(frames),f"{asset_id}: model present without verified sprite bake")
        stats["approved_png"]+=1
        stats["approved_ids"].append(asset_id)
    require(not require_approved or stats["approved_png"]>0,
            "final-art milestone requires at least one independently approved asset")
    stats["gameplay_swap_ready"]=stats["approved_png"]>0
    return stats


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--require-approved",action="store_true")
    parser.add_argument("--report",type=Path)
    options=parser.parse_args()
    try:
        result=validate(options.require_approved)
        if options.report:
            options.report.parent.mkdir(parents=True,exist_ok=True)
            options.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
        print(json.dumps({"status":"PASS",**result},ensure_ascii=False))
    except (ValueError,KeyError,OSError,TypeError,json.JSONDecodeError) as exc:
        print(json.dumps({"status":"FAIL","reason":str(exc)},ensure_ascii=False),file=sys.stderr)
        raise SystemExit(1)

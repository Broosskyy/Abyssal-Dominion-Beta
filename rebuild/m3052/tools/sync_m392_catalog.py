#!/usr/bin/env python3
"""Generate/verify signed-data-safe M392 GDScript mirrors from authored JSON.

No network calls, no new native APK, no Meshy credits. Asset approval must
still pass tools/validate_m392_islands.py, including alpha/collision checks.

  python3 tools/sync_m392_catalog.py --check
  python3 tools/sync_m392_catalog.py --write  # after editing JSON / shoreline
"""
from __future__ import annotations
import argparse
from hashlib import sha256
import json
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
CATALOG=ROOT/"assets/visuals/m392_island_catalog.json"
TARGET=ROOT/"island_asset_embedded.gd"
HEADER="""extends RefCounted
## M392 embedded catalog is generated from the authored JSON. Never edit it
## directly; rerun tools/sync_m392_catalog.py before committing new art.
## Embedding avoids changing APK bootstrap export presets and lets signed
## content packs carry all metadata plus reviewed polygon pairs.
"""
REGEX=re.compile(r'const (CATALOG_JSON|APPROVED_COLLISIONS_JSON) := """\n(.*?)\n"""',re.S)


def expected()->tuple[dict,dict]:
    catalog=json.loads(CATALOG.read_text(encoding="utf-8"))
    collisions={}
    for item in catalog["items"]:
        if item.get("status")!="approved":continue
        path=ROOT/item["collision_json"].removeprefix("res://")
        source=path.read_bytes()
        digest=sha256(source).hexdigest()
        if digest!=item.get("sha256_collision"):
            raise ValueError(f"Approved {item['id']} collision hash mismatch")
        collisions[item["id"]]={"sha256":digest,"collision":json.loads(source)}
    return catalog,collisions


def extract()->tuple[dict,dict]:
    text=TARGET.read_text(encoding="utf-8")
    matches=dict(REGEX.findall(text))
    if set(matches)!={"CATALOG_JSON","APPROVED_COLLISIONS_JSON"}:
        raise ValueError("M392 embedded data constants are missing or malformed")
    return json.loads(matches["CATALOG_JSON"]),json.loads(matches["APPROVED_COLLISIONS_JSON"])


def generate(data:dict,collisions:dict)->str:
    return (HEADER+
        'const CATALOG_JSON := """\n'+json.dumps(data,ensure_ascii=False,indent=2)+'\n"""\n'+
        'const APPROVED_COLLISIONS_JSON := """\n'+
        (json.dumps(collisions,ensure_ascii=False,indent=2) if collisions else "{}")+
        '\n"""\n')


def main()->None:
    p=argparse.ArgumentParser()
    group=p.add_mutually_exclusive_group()
    group.add_argument("--check",action="store_true")
    group.add_argument("--write",action="store_true")
    args=p.parse_args()
    source,coasts=expected()
    if args.write:
        TARGET.write_text(generate(source,coasts),encoding="utf-8")
    loaded,embedded=extract()
    if loaded!=source or embedded!=coasts:
        raise ValueError("M392 JSON and compiled content differ; run --write and retest")
    print(json.dumps({"status":"PASS","island_definitions":len(source['items']),
                      "approved_coasts_embedded":len(coasts)},ensure_ascii=False))


if __name__=="__main__":
    try:main()
    except (OSError,ValueError,KeyError,json.JSONDecodeError) as exc:
        print(json.dumps({"status":"FAIL","error":str(exc)},ensure_ascii=False),file=sys.stderr)
        sys.exit(1)

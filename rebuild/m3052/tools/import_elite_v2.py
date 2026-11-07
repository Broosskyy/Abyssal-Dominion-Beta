#!/usr/bin/env python3
"""Import user-authored Elite V2 albedos and ten source-rendered thumbnails.
Original GLB is intentionally NOT copied: all 11 Corsair skins share one mesh.
"""
import hashlib
import io
import json
from pathlib import Path
import sys
import zipfile
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
PREFIX="Abyssal_Elite_V2_1Modell_10Texturen/"
ZIP_SHA="4a1aca524bd58b4af2693e770750aab3491314ecbbccf6306651e85c4b2f28bd"
MODEL_SHA="add93320eaddcd84861ad483800ad0b6ea68f1a7b261fe8bab746e7b2021eb8a"
NAMES=["Obsidian","Bordeaux","Tiefblau","Waldgruen","Violett","Petrol","Elfenbein","Stahlblau","Karmesin","Knochen"]
TEXTURES=[
 "Elite_01_Obsidian_Albedo.png", "Elite_02_Bordeaux_Albedo.png",
 "Elite_03_Tiefblau_Albedo.png", "Elite_04_Waldgruen_Albedo.png",
 "Elite_05_Violett_Albedo.png", "Elite_06_Petrol_Albedo.png",
 "Elite_07_Elfenbein_Albedo.png", "Elite_08_Stahlblau_Albedo.png",
 "Elite_09_Karmesin_Albedo.png", "Elite_10_Knochen_Albedo.png"
]

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def main() -> None:
    archive=Path(sys.argv[1])
    if digest(archive.read_bytes())!=ZIP_SHA:
        raise SystemExit("Wrong ZIP bytes: refusing mismatched Elite V2 package")
    destination=ROOT/"assets"/"elite_v2"
    destination.joinpath("textures").mkdir(parents=True,exist_ok=True)
    destination.joinpath("previews").mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(archive) as z:
        model=z.read(PREFIX+"model/Black_Crown_Corsair.glb")
        original=ROOT/"assets/npc/meshy/models/black_crown_corsair_elite_test.glb"
        if digest(model)!=MODEL_SHA or digest(original.read_bytes())!=MODEL_SHA:
            raise SystemExit("Common source GLB differs from installed Black Crown original")
        mobile=Image.open(io.BytesIO(z.read(PREFIX+"preview/Uebersicht_Handy.png"))).convert("RGB")
        if mobile.size!=(1200,2700):
            raise SystemExit("Preview collage geometry unexpected")
        variants=[]
        for i,(name,filename) in enumerate(zip(NAMES,TEXTURES)):
            source=z.read(PREFIX+"textures_1024_mobile/"+filename)
            with Image.open(io.BytesIO(source)) as img:
                if img.size!=(1024,1024): raise SystemExit("Expected original mobile 1024 albedo: "+filename)
                img.verify()
            target=destination/"textures"/filename
            target.write_bytes(source)
            # Each of these ten portraits is a supplied original model render.
            # Crop only its label/background into a real shipyard THUMBNAIL,
            # never substitute this 2D thumbnail for the actual 3D ship.
            col=i%2
            row=i//2
            x=col*600
            y=row*540
            portrait=mobile.crop((x+8,y+8,x+592,y+496))
            portrait.thumbnail((490,400),Image.Resampling.LANCZOS)
            preview=destination/"previews"/("elite_%02d.png"%(i+1))
            portrait.save(preview,optimize=True)
            variants.append({"level":i+1,"name":name,"texture":"res://assets/elite_v2/textures/"+filename,"preview":"res://assets/elite_v2/previews/elite_%02d.png"%(i+1),"sha256":digest(source)})
        (destination/"manifest.json").write_text(json.dumps({"schema":1,"source_glb_sha256":MODEL_SHA,"geometry_duplicated":False,"mobile_albedo_size":1024,"variants":variants},indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
        print("Imported %d color textures and %d original-model thumbnails, without duplicating any GLB" %(len(variants),len(variants)))

if __name__=="__main__":main()

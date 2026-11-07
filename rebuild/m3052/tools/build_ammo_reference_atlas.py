#!/usr/bin/env python3
"""M3106 one-time import of user's original uploaded ammo artwork into an atlas.
Source artwork: 166946.png (24 ammo cards); 166943.png (cannon, harpoon);
167949.png (rainbow Leuchtkugeln); 167950.png (snow).
Do not synthesize icons here: crop and scale the actual original artwork.
"""
from pathlib import Path
from io import BytesIO
from urllib.request import Request, urlopen
from PIL import Image,ImageOps
import json

ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT / "assets/ui/ammo"
URLS={"main":"https://d2ol7oe51mr4n9.cloudfront.net/user_3LWZe0666PFFnQApXCXkCavaViS/578ac2b2-f606-4d89-b77b-aac9f7590760.png","base":"https://d2ol7oe51mr4n9.cloudfront.net/user_3LWZe0666PFFnQApXCXkCavaViS/8b9c899b-c604-49c9-b07a-e87edc48bd84.png","flare":"https://d2ol7oe51mr4n9.cloudfront.net/user_3LWZe0666PFFnQApXCXkCavaViS/2f61146d-44e9-4a78-80b2-bb3919517964.png","snow":"https://d2ol7oe51mr4n9.cloudfront.net/user_3LWZe0666PFFnQApXCXkCavaViS/12ce0a88-4bda-409d-b3bd-a9b557c59ad9.png"}
TYPES=["cannon","chain","harpoon","flare","pumpkin","snow","ice",
"fire","poison","shrapnel","lightning","holy","shadow","wind","earth",
"water","cursed","bleed","necro","gold","crystal","explosive","arcane",
"spectral","lava","light","armor_piercing","gas"]
GRID={
"fire":(0,0),"ice":(1,0),"poison":(2,0),"shrapnel":(3,0),
"lightning":(4,0),"holy":(5,0),"shadow":(0,1),"wind":(1,1),
"earth":(2,1),"water":(3,1),"cursed":(4,1),"bleed":(5,1),
"necro":(0,2),"gold":(1,2),"crystal":(2,2),"explosive":(3,2),
"arcane":(4,2),"spectral":(5,2),"lava":(0,3),"light":(1,3),
"chain":(2,3),"armor_piercing":(3,3),"gas":(4,3),"pumpkin":(5,3)
}
CELL=96

def get_image(url):
    req=Request(url,headers={"User-Agent":"AbyssalDominion-AssetBuilder/1.0"})
    with urlopen(req,timeout=75) as f:
        return Image.open(BytesIO(f.read())).convert("RGB")

def generate():
    source=get_image(URLS["main"])
    cannon_and_harpoon=get_image(URLS["base"])
    leucht=get_image(URLS["flare"])
    snow=get_image(URLS["snow"])
    assert source.size==(1536,1024),source.size
    assert cannon_and_harpoon.size==(1536,1024),cannon_and_harpoon.size
    assert leucht.size==(1536,1024),leucht.size
    assert snow.size==(1536,1024),snow.size
    atlas=Image.new("RGB",(7*CELL,4*CELL),(4,7,12))
    for i,name in enumerate(TYPES):
        if name in GRID:
            column,row=GRID[name]
            crop=source.crop((column*256+9,row*256+8,column*256+247,row*256+207))
        elif name=="cannon":
            crop=cannon_and_harpoon.crop((8,20,505,455))
        elif name=="harpoon":
            crop=cannon_and_harpoon.crop((5,515,505,1018))
        elif name=="flare":
            crop=leucht.crop((1029,8,1531,495))
        elif name=="snow":
            crop=snow.crop((5,513,778,1018))
        else:
            raise ValueError(name)
        thumb=ImageOps.fit(crop,(CELL-6,CELL-6),method=Image.Resampling.LANCZOS,centering=(.5,.47))
        x=(i%7)*CELL+3
        y=(i//7)*CELL+3
        atlas.paste(thumb,(x,y))
    DEST.mkdir(parents=True,exist_ok=True)
    target=DEST/"user_ammo_atlas.webp"
    atlas.save(target,"WEBP",quality=80,method=6)
    provenance={"origin":"user-provided original image collages, cropped for in-game UI",
                "files":["166946.png","166943.png","167949.png","167950.png"],
                "columns":7,"rows":4,"cell":CELL,"order":TYPES,
                "no_generated_replacement_art":True}
    (DEST/"user_ammo_atlas.json").write_text(json.dumps(provenance,indent=2)+"\n")
    print(f"Generated {target}, {target.stat().st_size} bytes; {len(TYPES)} actual user motifs")

if __name__=="__main__":
    generate()

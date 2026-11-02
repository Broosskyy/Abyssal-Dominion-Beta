"""Install explicitly reviewed SeaBattles PNGs in the ignored local test pack."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("audit_directory", type=Path)
    args = parser.parse_args()
    project = Path(__file__).resolve().parent.parent
    audit = args.audit_directory.resolve()
    report = json.loads((audit / "scan_report.json").read_text())
    if not any(x.get("package") == "com.RoyaleGames.SeaBattles" for x in report["package_metadata"]):
        raise ValueError("Source package is not SeaBattles")
    target = project / "assets/classic/private_seabattles"
    target.mkdir(parents=True, exist_ok=True)
    selected = []

    def copy(name, slot, kind="Texture2D", identity=None, width=None):
        rows = [x for x in report["resources"] if x["type"] == kind and x["name"] == name
                and (identity is None or x["id"] == identity) and (width is None or x["width"] == width)]
        if len(rows) != 1:
            raise ValueError(f"Ambiguous source selection: {name}")
        row = rows[0]
        source = audit / row["png"]
        if hashlib.file_digest(source.open("rb"), "sha256").hexdigest() != row["png_sha256"]:
            raise ValueError(f"PNG changed since audited export: {name}")
        out = target / slot
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, out)
        selected.append({"slot": slot, "id": row["id"], "name": name, "source_png": row["png"], "source_sha256": row["png_sha256"]})

    for name in ["elite8", "Warship", "Pinnace", "FlyingDutchman"]:
        copy(name, "ships/" + name.lower() + ".png")
    copy("Tiamat", "monsters/tiamat.png")
    for identity, name, slot in [
        ("17b90585340354e37b4c231e2b07b451:1", "8", "islands/snow.png"),
        ("e5a7937dfb2ab4a36979b7c17fd0e953:1", "7", "islands/snow2.png"),
        ("57e9e303722d74b189316842c16c6458:1", "5", "islands/rock.png"),
        ("10804415ce2f9449783e705a6a0d2991:1", "9", "islands/tropical.png"),
    ]:
        copy(name, slot, identity=identity)
    copy("WaveNoise", "ocean/wave_noise.png")
    copy("login-button", "ui/button_normal.png", kind="Sprite", width=256)
    copy("gold-button", "ui/button_hover.png", kind="Sprite")
    copy("80_subMenuBtnBkgMC_bmpref0", "ui/button_pressed.png", kind="Sprite")
    copy("CannonShootEffect", "effects/cannon_flash.png", kind="Sprite")
    copy("13_minimap", "ui/minimap.png", kind="Sprite")
    actors = {}
    for label, name in [("PlayerShip", "elite8"), ("NPC_0", "warship"), ("NPC_1", "pinnace"),
                        ("NPC_2", "flyingdutchman"), ("NPC_3", "elite8"), ("NPC_4", "warship")]:
        actors[label] = {"path": f"ships/{name}.png", "columns": 4, "rows": 2,
                         "idle_frames": [0, 1, 2, 3], "moving_frames": [4, 5, 6, 7],
                         "world_width": 12.0, "heading_offset": 45.0,
                         "source_layout": "Four diagonal headings; upper row furled sails, lower row deployed sails"}
    actors["SeaMonster"] = {"path": "monsters/tiamat.png", "columns": 4, "rows": 8, "idle_frames": [0, 1, 2, 3],
                             "animation_rows": 8, "animation_fps": 7.0, "world_width": 17.0, "heading_offset": 45.0}
    for i, name in [(0, "snow"), (1, "snow2"), (2, "rock"), (3, "tropical")]:
        actors[f"Island_{i}"] = {"path": f"islands/{name}.png"}
    pack = {"source_label": "SeaBattles 1.24.0", "package": "com.RoyaleGames.SeaBattles", "source_is_seabattles": True,
            "actors": actors, "ocean": {"path": "ocean/wave_noise.png", "usage": "noise"},
            "shot_effect": {"path": "effects/cannon_flash.png", "world_width": 1.7}, "selected": selected,
            "notes": ["Original source PNGs; no model rasterization used for this pack.",
                      "Four headings and two sail states must not be treated as eight headings.",
                      "Existing circular collision bounds are independent of image silhouettes."]}
    (target / "pack.json").write_text(json.dumps(pack, ensure_ascii=False, indent=2))
    print("Installed", len(selected), "verified source PNGs")


if __name__ == "__main__":
    main()

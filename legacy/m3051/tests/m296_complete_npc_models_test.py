import hashlib
import json
from pathlib import Path
import struct


ROOT = Path(__file__).resolve().parents[1]
CONTRACT = json.loads((ROOT / "data/m296_complete_npc_models_contract.json").read_text())


def _glb(path):
    raw = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", raw)
    assert (magic, version, length) == (b"glTF", 2, len(raw))
    json_length, kind = struct.unpack_from("<I4s", raw, 12)
    assert kind == b"JSON" and json_length % 4 == 0
    doc = json.loads(raw[20:20 + json_length])
    bin_length, kind = struct.unpack_from("<I4s", raw, 20 + json_length)
    assert kind == b"BIN\x00" and bin_length % 4 == 0
    assert 28 + json_length + bin_length == len(raw)
    data = raw[28 + json_length:]
    assert doc["buffers"][0]["byteLength"] <= len(data)
    assert len(data) - doc["buffers"][0]["byteLength"] < 4
    return doc, data


def test_m296_distinct_complete_models_and_manifest_integrity():
    assert CONTRACT["milestone"] == "M296" and CONTRACT["master_concept"] == "V3.8"
    assert CONTRACT["both_single_node_single_mesh"] and CONTRACT["structural_details_baked_into_glb"]
    assert not CONTRACT["runtime_structural_overlays_for_new_assets"] and not CONTRACT["final_art"]
    manifest = json.loads((ROOT / "assets/placeholder_pack/manifest.json").read_text())["assets"]
    hashes = []
    for row in CONTRACT["assets"]:
        path = ROOT / row["path"].removeprefix("res://")
        raw = path.read_bytes()
        assert len(raw) == row["bytes"] == manifest[row["id"]]["bytes"]
        assert hashlib.sha256(raw).hexdigest() == row["sha256"] == manifest[row["id"]]["sha256"]
        assert manifest[row["id"]]["path"] == row["path"]
        assert manifest[row["id"]]["triangles"] == row["triangles"]
        assert manifest[row["id"]]["surfaces"] == row["surfaces"]
        assert "GLB_PLACEHOLDER" in manifest[row["id"]]["classification"]
        hashes.append(row["sha256"])
    assert len(set(hashes + [manifest["npc_scout_01"]["sha256"], manifest["npc_raider_01"]["sha256"]])) == 4


def test_m296_glb_accessors_bounds_indices_and_complete_geometry():
    for row in CONTRACT["assets"]:
        doc, data = _glb(ROOT / row["path"].removeprefix("res://"))
        assert len(doc["nodes"]) == len(doc["meshes"]) == 1
        assert doc["nodes"][0]["mesh"] == 0
        assert not doc.get("skins") and not doc.get("animations")
        primitives = doc["meshes"][0]["primitives"]
        assert len(primitives) == row["surfaces"] and all(p["mode"] == 4 for p in primitives)
        triangles = 0
        for primitive in primitives:
            position = doc["accessors"][primitive["attributes"]["POSITION"]]
            normal = doc["accessors"][primitive["attributes"]["NORMAL"]]
            assert position["count"] == normal["count"]
            assert all(lo < hi for lo, hi in zip(position["min"], position["max"]))
            if "indices" in primitive:
                indices = doc["accessors"][primitive["indices"]]
                assert indices["count"] % 3 == 0 and indices["componentType"] in (5123, 5125)
                idx_view = doc["bufferViews"][indices["bufferView"]]
                idx_start = idx_view.get("byteOffset", 0) + indices.get("byteOffset", 0)
                idx_format = "<H" if indices["componentType"] == 5123 else "<I"
                width = struct.calcsize(idx_format)
                assert idx_start + width * indices["count"] <= len(data)
                assert max(struct.unpack_from(idx_format, data, idx_start + width * i)[0]
                           for i in range(indices["count"])) < position["count"]
                triangles += indices["count"] // 3
            else:
                assert position["count"] % 3 == 0
                triangles += position["count"] // 3
        assert triangles == row["triangles"]
        assert len(primitives) > 6  # includes baked details, not just a recolor


def test_m296_runtime_slot_and_authority_boundary():
    resolver = (ROOT / "scripts/visual/p0_visual_slot_resolver.gd").read_text()
    visual_library = (ROOT / "scripts/visual/asset_visual_library.gd").read_text()
    decorator = (ROOT / "scripts/visual/p0_npc_fallback_decorator.gd").read_text()
    assert "AssetVisualLibrary" in visual_library and "P0NpcFallbackDecorator.apply(visual, id" in visual_library
    assert "NPC-SHIP-EARLY-001\":\"npc_friendly_coastal_sloop" in resolver
    assert "NPC-SHIP-EARLY-004\":\"npc_gunship_01" in resolver
    for row in CONTRACT["assets"]:
        assert ('id == "' + row["id"] + '" and str(visual.get_meta("source_path", "")) == "' +
                row["path"] + '": return') in decorator
    assert "server combat truth" in CONTRACT["does_not_change"]
    assert "ship collision or hit boxes" in CONTRACT["does_not_change"]
    assert CONTRACT["native_qa"] == "NOT_EVALUATED"


def test_m296_release_identity_and_reproducible_builder():
    release = json.loads((ROOT / "data/release_identity.json").read_text())
    assert (release["milestone"], release["client_version"], release["version"],
            release["build_number"]) == ("M301", "0.301.0", "0.301.0", 301)
    builder = (ROOT / "tools/m296_build_npc_glbs.py").read_text()
    assert "SOURCE_SHA256" in builder and "npc_gunship_01" in builder
    assert "npc_friendly_coastal_sloop" in builder

from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")

def test_m220_release_and_contract():
    release = json.loads(read("data/release_identity.json"))
    assert release["milestone"] in {"M220", "M221", "M222", "M223", "M224", "M225", "M226", "M227", "M228", "M229", "M230", "M231", "M232", "M233", "M234", "M235", "M236", "M237", "M238", "M239","M240","M241","M242", "M243", "M244", 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'}
    assert release["client_version"] in {"0.220.0", "0.221.0", "0.222.0", "0.223.0", "0.224.0", "0.225.0", "0.226.0", "0.227.0", "0.228.0", "0.229.0", "0.230.0", "0.231.0", "0.232.0", "0.233.0", "0.234.0", "0.235.0", "0.236.0", "0.237.0", "0.238.0", "0.239.0", "0.240.0","0.241.0","0.242.0", "0.243.0", "0.244.0", '0.245.0','0.246.0','0.247.0','0.248.0','0.249.0','0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'}
    contract = json.loads(read("data/m220_navigation_world_guidance_contract.json"))
    assert contract["milestone"] == "M220"
    assert "Tap-to-Sail" in contract["locks"]["movement"]
    assert "actually resolve" in contract["locks"]["objective_truth"]

def test_m220_course_preview_is_presentation_only():
    source = read("scripts/gameplay/player_input.gd")
    hud = read("scripts/ui/game_hud.gd")
    assert "func navigation_presentation()" in source
    assert '"final_target":navigation_target' in source
    assert '"steering_target":steering' in source
    assert "M192: keep the captain's final tap destination" in source
    assert "func _draw_navigation_course" in hud
    assert "draw_dashed_line" in hud
    assert "M220NavigationPresentationCatalog.edge_label" in hud

def test_m220_recenter_preserves_zoom_and_sailing_intent():
    source = read("scripts/gameplay/camera_rig.gd")
    block = source.split("func recenter() -> void:",1)[1].split("func is_recentering",1)[0]
    assert "pan_offset = Vector3.ZERO" in block
    assert "zoom_factor =" not in block
    assert "cancel_navigation" not in block

def test_m220_keeps_historical_navigation_and_hud_locks():
    player = read("scripts/gameplay/player_input.gd")
    hud = read("scripts/ui/game_hud.gd")
    assert "Other ships/NPCs/monsters never become route blockers." in player
    assert '"loot"] and distance<=34.0' in hud
    layout = read("scripts/ui/nautical_layout.gd")
    assert "No persistent bottom command/map-selection bar" in layout
    assert "lower-right combat anchor" in layout

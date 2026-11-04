from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
def main():
 r=json.loads(read("data/release_identity.json")); assert r["build_number"]>=171 and r["master_concept"]=="V3.8"
 cfg=json.loads(read("data/m171_runtime_presentation_interaction.json")); assert len(cfg["runtime_presentation_bindings"])>=5
 hud=read("scripts/ui/game_hud.gd"); assert "ids = ActionItemCatalog.item_ids()" in hud; assert "storm_bolt", "infernal_barrel" not in hud[hud.find("func combat_picker_layout"):hud.find("func halloween_event_prompt")]
 nautical=read("scripts/ui/nautical_hud.gd"); assert "for id in health.ammo_effect_until.keys()" in nautical; assert 'var labels := {"iron"' not in nautical
 arsenal=read("scripts/ui/arsenal_panel.gd"); assert "inventory.effective_offers()" in arsenal; assert "const LABELS" not in arsenal
 boot=read("scripts/core/game_bootstrap.gd"); assert "M171RuntimePresentationCatalog.new()" in boot
 reg=json.loads(read("data/admin_content_type_registry.json"))["content_types"]
 for k in cfg["no_code_types"]: assert k in reg
 print("M171_RUNTIME_PRESENTATION_INTERACTION_PASS")
if __name__=="__main__": main()

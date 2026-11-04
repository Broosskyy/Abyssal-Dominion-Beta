from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
layout=(ROOT/'scripts/ui/nautical_layout.gd').read_text()
hud=(ROOT/'scripts/ui/nautical_hud.gd').read_text()
factory=(ROOT/'scripts/core/procedural_factory.gd').read_text()
water=(ROOT/'scripts/visual/water_surface.gd').read_text()
assert '"events"' in layout and '"quests"' in layout and '"home"' in layout
assert 'AKTIVE MISSION' in hud and 'const ICON_IDS' in hud
assert 'ShoreRock_' in factory and 'LandmarkRock' in factory
assert 'surface_roughness' in water and 'specular_strength' in water and 'SPECULAR = clamp' in water
print('M21 mockup-convergence contract: PASS')

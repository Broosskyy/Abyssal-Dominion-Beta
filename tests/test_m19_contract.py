from pathlib import Path
import json, re
ROOT=Path(__file__).resolve().parents[1]
def read(rel): return (ROOT/rel).read_text(encoding='utf-8')
def test_m19_version_and_engine_baseline():
    pkg=json.loads(read('package.json')); release=json.loads(read('data/release_identity.json'))
    assert int(release['build_number'])>=19 and pkg['version']==release['version']
    assert 'renderer/rendering_method="gl_compatibility"' in read('project.godot')
def test_macro_first_island_profiles():
    world=read('scripts/world/world_map_system.gd'); assert '_build_island_composition' in world and '_find_island_position' in world and world.count('"radius":')>=6 and 'occupied' in world and 'clearance' in world and 'port_position.is_finite()' in world
def test_island_visual_physics_footprint_stays_linked():
    factory=read('scripts/core/procedural_factory.gd'); assert 'aspect: Vector2 = Vector2.ONE' in factory and 'yaw_degrees' in factory and 'prop_density' in factory and 'BoxShape3D.new()' in factory and 'radius * 1.52 * sx' in factory and 'foam.aspect' in factory
def test_vegetation_density_is_profile_driven():
    factory=read('scripts/core/procedural_factory.gd'); anchors=re.search(r'var base_positions := \[(.*?)\]',factory,re.S); assert 'tree_count := clampi' in factory and 'density' in factory and anchors and anchors.group(1).count('Vector3(')>=6
def test_ocean_uses_layered_compatibility_shading():
    water=read('scripts/visual/water_surface.gd'); assert 'uniform vec3 mid_color' in water and 'normal_uv_b' in water and 'mix(normal_a, normal_b' in water and 'screen_texture' not in water and 'depth_texture' not in water

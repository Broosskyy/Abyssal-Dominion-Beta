from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class M20Contract(unittest.TestCase):
    def read(self, rel):
        return (ROOT / rel).read_text(encoding='utf-8')

    def test_ship_silhouette_detail(self):
        text = self.read('scripts/core/procedural_factory.gd')
        for token in ['_create_ship_detail', 'CaptainCabin', 'DeckCannon', 'Bowsprit', 'CaptainPennant']:
            self.assertIn(token, text)

    def test_wake_has_stern_foam_and_turn_response(self):
        text = self.read('scripts/visual/ship_wake.gd')
        self.assertIn('SternFoam', text)
        self.assertIn('turn_ratio', text)
        self.assertIn('ship.turn_input', text)

    def test_combat_vfx_has_splash_smoke_sparks(self):
        projectile = self.read('scripts/gameplay/cannon_projectile.gd')
        self.assertIn('WaterSplashScript', projectile)
        self.assertIn('_spawn_water_splash', projectile)
        self.assertIn('water_splash.gd', projectile)
        self.assertIn('smoke', self.read('scripts/visual/muzzle_flash.gd').lower())
        self.assertIn('spark', self.read('scripts/visual/impact_fx.gd').lower())

    def test_touch_comfort_targets_and_deadzone(self):
        layout = self.read('scripts/ui/nautical_layout.gd')
        controls = self.read('scripts/gameplay/player_input.gd')
        self.assertIn('var fire_radius := (50.0 if compact else 68.0) * sx', layout)
        self.assertIn('var wheel := Rect2', layout)
        self.assertIn('min_touch := 56.0', layout)
        self.assertIn('magnitude < 0.12', controls)
        self.assertIn('inverse_lerp(0.12, 1.0, magnitude)', controls)

    def test_project_identity(self):
        project = self.read('project.godot')
        self.assertIn('config/name=', project)
        self.assertIn('config/version=', project)


if __name__ == '__main__':
    unittest.main()

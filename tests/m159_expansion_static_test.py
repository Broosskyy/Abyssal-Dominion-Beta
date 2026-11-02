from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
for f in ['data/m159_guild_island_expansion.json','data/m159_items_and_ship_extensions.json','data/m159_admin_badge_contract.json','data/m159_content_expansion_audit.json']:
    json.loads((root/f).read_text(encoding='utf-8'))
inv=(root/'scripts/progression/player_inventory.gd').read_text()
assert 'const MAX_DECK := 10' in inv and '"crystal_blessing": 1' in inv
composer=(root/'scripts/guild/guild_island_composer.gd').read_text()
assert 'M159GuildIslandDepth.enrich(root)' in composer
boot=(root/'scripts/core/game_bootstrap.gd').read_text()
assert 'M159ShipExtensionVisuals' in boot and 'M159AdminBadge' in boot
vfx=(root/'scripts/visual/m159_ship_extension_visuals.gd').read_text()
assert 'VisibleDeckStack' in vfx and 'BlessingVFX' in vfx and 'range(count)' in vfx
badge=(root/'scripts/ui/m159_admin_badge.gd').read_text()
assert 'server_authority_verified' in badge and 'DEV ADMIN' in badge
print('M159 STATIC PASS')

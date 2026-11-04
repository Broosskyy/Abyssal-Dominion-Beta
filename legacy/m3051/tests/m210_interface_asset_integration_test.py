from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]

def test_release():
 d=json.loads((ROOT/'data/release_identity.json').read_text())
 assert d['milestone'] in {'M210','M211','M212','M213','M214','M215','M216','M217','M218','M219','M220','M221','M222','M223','M224','M225','M226','M227','M228','M229','M230','M231','M232','M233','M234','M235','M236','M237','M238','M239','M240','M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['version'] in {'0.210.0','0.211.0','0.212.0','0.213.0','0.214.0','0.215.0','0.216.0','0.217.0','0.218.0','0.219.0','0.220.0','0.221.0','0.222.0','0.223.0','0.224.0','0.225.0','0.226.0','0.227.0','0.228.0','0.229.0','0.230.0','0.231.0','0.232.0','0.233.0','0.234.0','0.235.0','0.236.0','0.237.0','0.238.0','0.239.0','0.240.0','0.241.0','0.242.0','0.243.0','0.244.0', '0.245.0','0.246.0','0.247.0','0.248.0','0.249.0','0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['master_concept']=='V3.8'

def test_contract_and_intake():
 c=json.loads((ROOT/'data/m210_interface_asset_integration_contract.json').read_text())
 assert c['ui_rules']['primary_attack']=='lower_right'
 assert c['asset_pipeline']['generation_sheet_max_assets']==8
 assert c['asset_pipeline']['art_cannot_change_gameplay'] is True
 i=json.loads((ROOT/'data/m210_authored_asset_intake_manifest.json').read_text())
 assert all(x['count']<=8 for x in i['first_day_batches'])

def test_runtime_catalog_and_ui():
 s=(ROOT/'scripts/ui/m210_interface_asset_runtime_catalog.gd').read_text()
 assert 'M204InventoryPresentationCatalog.icon_slot' in s
 assert 'authored_replacement_safe' in s
 a=(ROOT/'scripts/ui/arsenal_panel.gd').read_text()
 assert 'M210InterfaceAssetRuntimeCatalog.item_slot' in a
 assert 'AUSRÜSTEN' in a
 n=(ROOT/'scripts/ui/nautical_hud.gd').read_text()
 assert 'MUNITION & HARPUNEN' in n and 'ITEMS & VORRÄTE' in n

def test_production_dirs():
 for p in ['assets/production/authored_2d/source_masters','assets/production/authored_2d/runtime','assets/production/authored_2d/atlases','assets/production/authored_3d']:
  assert (ROOT/p).is_dir()

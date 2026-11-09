"""Web-only imports, minimal export, and content-addressed optional art packs.

Run prepare only in a disposable build checkout, after baking original GLBs.
No simulation, account, world, or protocol code is generated or forked here.
"""
from __future__ import annotations
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import re
from zipfile import ZipFile, ZIP_DEFLATED, ZipInfo

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = ["tests/**", "tools/**", "qa/**", "README.md", "builds/**",
    "assets/npc/meshy/**", "assets/player/*.glb", "assets/player/*shaded_shaded.png",
    "assets/elite_v2/textures/**", "assets/expansion/halloween.webp", "assets/expansion/columbus.webp",
    "assets/world_v2/guild_island.png", "ship_mesh_layer.gd", "stern_hull_taper.gd"]

def prepare() -> None:
    presets = ROOT / "export_presets.cfg"
    head, rest = presets.read_text().split("[preset.1]", 1)
    web, tail = rest.split("[preset.2]", 1)
    web = re.sub(r'exclude_filter="[^"]*"', 'exclude_filter="'+','.join(EXCLUDED)+'"', web)
    web = web.replace('assets/visuals/island_collision.json"', 'assets/visuals/island_collision.json,assets/classic_baked/manifest.json"')
    web = re.sub(r'html/custom_html_shell="[^"]*"', 'html/custom_html_shell="res://web/browser_shell.html"', web)
    presets.write_text(head+"[preset.1]"+web+"[preset.2]"+tail)
    project = ROOT / "project.godot"
    text = project.read_text().replace('run/main_scene="res://updater/launcher.tscn"', 'run/main_scene="res://start_hub.tscn"')
    text = text.replace('[autoload]', '[autoload]\nBrowserContent="*res://web/browser_content.gd"')
    project.write_text(text)
    changed = 0
    for file in (ROOT / 'assets').rglob('*.import'):
        name = file.relative_to(ROOT).as_posix()
        limit = 0
        if name.startswith(('assets/elite_v2/previews/', 'assets/player/')) and 'preview' in name: limit = 512
        elif name.startswith('assets/ui/painted/'): limit = 1024 if file.stem.endswith('.jpg') else 256
        elif name.startswith(('assets/expanded/', 'assets/ui/icons/')): limit = 256
        elif name.startswith('assets/world_v2/'): limit = 1280 if 'splash' in name else 1024 if 'harbor' in name else 256
        elif name.startswith('assets/reference/islands/'): limit = 1024
        elif name.startswith('assets/reference/monsters/'): limit = 2048
        elif name.startswith('assets/expansion/'): limit = 512
        if limit:
            text = file.read_text()
            text = re.sub(r'process/size_limit=\d+', f'process/size_limit={limit}', text)
            if not file.name.endswith('.svg.import'):
                text = re.sub(r'compress/mode=\d+', 'compress/mode=1', text)
                text = re.sub(r'compress/lossy_quality=[0-9.]+', 'compress/lossy_quality=0.82', text)
            file.write_text(text)
            changed += 1
    print(f'Prepared Web-only exclusions and {changed} bounded texture imports')

def zipped(entries: dict[str, bytes]) -> bytes:
    import io
    output = io.BytesIO()
    with ZipFile(output, 'w', compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(entries.items()):
            info = ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            archive.writestr(info, data)
    return output.getvalue()

def finalize(directory: Path, source: Path) -> None:
    with ZipFile(source) as archive:
        entries = {n: archive.read(n) for n in archive.namelist() if not n.endswith('/')}
    assert 'project.binary' in entries
    assert not any(n.endswith('.glb') or 'assets/npc/meshy/' in n or 'Elite_01_Obsidian_Albedo' in n for n in entries)
    optional_names: set[str] = set()
    for name in entries:
        if (re.fullmatch(r'assets/classic_baked/(elite_\d\d|event_\w+)\.png\.import', name) or
            re.fullmatch(r'assets/elite_v2/previews/elite_\d\d\.png\.import',name) or
            re.fullmatch(r'assets/expansion/preview_(halloween|columbus)\.webp\.import',name)):
            optional_names.add(name)
            optional_names.update(re.findall(r'"res://([^"\n]+\.ctex)"', entries[name].decode()))
            source_name = name.removesuffix('.import')
            if source_name in entries: optional_names.add(source_name)
    assert len([n for n in optional_names if n.endswith('.import')]) == 24
    optional = {n: entries.pop(n) for n in optional_names}
    data = zipped(optional)
    digest = hashlib.sha256(data).hexdigest()
    filename = f'ships-{digest[:20]}.zip'
    (directory / filename).write_bytes(data)
    manifest = {'schema': 1, 'packs': {'ship_designs': {'file': filename, 'bytes': len(data), 'sha256': digest}}}
    entries['web/content_manifest.json'] = json.dumps(manifest).encode()
    core = zipped(entries)
    core_name = f'core-{hashlib.sha256(core).hexdigest()[:20]}.zip'
    (directory / core_name).write_bytes(core)
    wasm = (directory / 'index.wasm').read_bytes()
    engine_name = 'engine-'+hashlib.sha256(wasm).hexdigest()[:20]
    for file in list(directory.glob('index.*')):
        if file.suffix == '.wasm' or '.worklet.js' in file.name:
            file.rename(directory / file.name.replace('index.', engine_name+'.', 1))
    html = directory / 'index.html'
    text = html.read_text()
    match = re.search(r'const config = (\{[^\n]+\});', text)
    if not match: raise RuntimeError('Exported shell configuration not found')
    config = json.loads(match.group(1))
    config.update(executable=engine_name, mainPack=core_name, fileSizes={core_name:len(core),engine_name+'.wasm':len(wasm)})
    html.write_text(text[:match.start(1)]+json.dumps(config, separators=(',', ':'))+text[match.end(1):])
    (directory / 'index.pck').unlink(missing_ok=True)
    source.unlink(missing_ok=True)
    report = {'schema':1,'start_files':[core_name,engine_name+'.wasm','index.js'],
        'core_zip_bytes':len(core),'optional_ship_bytes':len(data),'engine_raw_bytes':len(wasm),
        'engine_gzip_bytes':len(gzip.compress(wasm, compresslevel=9)),
        'initial_gzip_estimate_bytes':len(core)+len(gzip.compress(wasm,compresslevel=9))+(directory/'index.js').stat().st_size,
        'core_file_count':len(entries),'optional_file_count':len(optional),
        'shared_logic':'simulation.gd/network_client.gd/server unchanged', 'packs':manifest['packs']}
    (directory / 'delivery-report.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report,indent=2))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('command',choices=['prepare','finalize'])
    parser.add_argument('--directory',type=Path,default=ROOT/'builds/web')
    parser.add_argument('--source',type=Path,default=ROOT/'builds/web/full.zip')
    args = parser.parse_args()
    prepare() if args.command == 'prepare' else finalize(args.directory,args.source)

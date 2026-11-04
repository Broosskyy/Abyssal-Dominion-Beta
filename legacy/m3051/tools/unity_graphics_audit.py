"""Full static export used by import_seabattles_local.py --all.

No APK execution, network requests, or repository writes. Identifiers include the
serialized file, not just names/path IDs (those collide across split packages).
"""
from __future__ import annotations

import collections
import gc
import hashlib
import json
import io
import os
import re
import shutil
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

def save_png_atomic(image, path: Path) -> None:
    """Publish only a completed PNG, including when a watcher scans the tree."""
    buffer = io.BytesIO()
    image.save(buffer, format="PNG", compress_level=4)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".pending")
    with temporary.open("wb") as stream:
        stream.write(buffer.getvalue())
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def category(name: str, kind: str) -> str:
    n = name.casefold()
    rules = {
        "water": ("water", "ocean", "foam", "caustic", "agua", "sea_surface"),
        "effects": ("smoke", "particle", "spark", "glow", "flare", "flame", "fire", "explos", "wfx_", "trail", "snowflake", "shock", "muzzle"),
        "islands": ("island", "isla", "coast", "terrain", "sand", "rock", "cliff", "palm", "tropical", "snow_ground"),
        "monsters": ("tiburon", "kraken", "orca", "tortuga", "serpiente", "levi", "monster", "megalodon", "tiamat", "mobydick", "piran", "medusa", "devorador_profundidades"),
        "ships": ("elite", "ship", "barco", "fragata", "corsario", "warship", "pinnace", "galeon", "velkaris", "nythrael", "jackhavor", "morghael", "zhaeroth", "seahawk", "brado", "soberano", "capitan", "almirante"),
        "ui": ("ui", "icon", "btn", "button", "panel", "rango", "rank", "lang_", "frame", "fondo", "gold", "pearl", "checkmark", "background"),
    }
    for group, terms in rules.items():
        if any(term in n for term in terms):
            return group
    return "ui" if kind == "Sprite" else "unclassified"


def safe_name(value: str) -> str:
    return re.sub(r"[^a-zA-Z0-9_.-]+", "_", value).strip("._")[:100] or "unnamed"

def seabattles_category(row: dict) -> str:
    """Package-specific hints confirmed against SeaBattles 1.24.0 contact sheets."""
    name = row["name"].casefold()
    if name.startswith("unitywatermark"):
        return "system"
    if name == "wavenoise":
        return "water"
    if any(t in name for t in ("effect", "flamepuff", "sparkle", "softglow", "fognoise", "fogphantom")):
        return "effects"
    if any(t in name for t in ("rocket", "cannonball", "inventory", "icon", "btn")):
        return "ui"
    if row["type"] == "Texture2D" and row.get("format") == "ETC2_RGBA8" and re.fullmatch(r"[a-f0-9]{32}", row["serialized_file"]):
        width, height = row["width"], row["height"]
        if name.isdigit() and width >= 640 and height in (476, 952):
            return "islands"
        if width == height * 2 and width in (1024, 2048):
            return "ships"
        if height == width * 2 and width in (1024, 2048):
            return "monsters"
    return category(row["name"], row["type"])


def prepare_source(source: Path, target: Path, report: dict, depth: int = 0) -> None:
    """Unwrap APK/APKS/ZIP; keep .resS siblings and Addressables together."""
    from import_seabattles_local import safely_copy_zip_members
    if depth > 4:
        raise ValueError("Nested package depth exceeds 4")
    with zipfile.ZipFile(source) as archive:
        names = archive.namelist()
        for meta in ("meta.sai_v2.json", "meta.sai_v1.json"):
            if meta in names:
                report["package_metadata"].append(json.loads(archive.read(meta)))
        children = [i for i in archive.infolist() if i.filename.lower().endswith((".apk", ".apks")) and not i.is_dir()]
        if children:
            for i, item in enumerate(children):
                nested = target / f"package_{depth}_{i}{Path(item.filename).suffix}"
                nested.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(item) as src, nested.open("wb") as dst:
                    shutil.copyfileobj(src, dst, 1024 * 1024)
                prepare_source(nested, target / f"part_{i}", report, depth + 1)
                nested.unlink()
        else:
            report["packages"].append({"source": source.name, "files_copied": safely_copy_zip_members(archive, target)})


def alpha_stats(image) -> dict:
    hist = image.getchannel("A").histogram()
    area = image.width * image.height
    low, high = image.getchannel("A").getextrema()
    return {"min": low, "max": high, "transparent_pixels": hist[0],
            "partial_pixels": sum(hist[1:255]), "opaque_pixels": hist[255],
            "transparent_fraction": round(hist[0] / area, 6)}


def decoder_selfcheck() -> dict:
    """Color/alpha fixtures encoded with etcpak, decoded through UnityPy."""
    import etcpak
    import texture2ddecoder
    import numpy as np
    from PIL import Image
    from UnityPy.export.Texture2DConverter import parse_image_data
    from UnityPy.enums import TextureFormat, BuildTarget
    results = []
    rgba = np.zeros((8, 8, 4), dtype=np.uint8)
    rgba[:4, :4] = [240, 20, 15, 0]
    rgba[:4, 4:] = [20, 230, 15, 80]
    rgba[4:, :4] = [20, 15, 240, 170]
    rgba[4:, 4:] = [230, 210, 20, 255]
    for fmt, encode in [(TextureFormat.ETC2_RGB, etcpak.compress_etc2_rgb),
                        (TextureFormat.ETC2_RGBA8, etcpak.compress_etc2_rgba)]:
        payload = encode(rgba.tobytes(), 8, 8)
        image = parse_image_data(payload, 8, 8, fmt, (2022, 3, 0, 0), BuildTarget.Android)
        a = np.array(image)
        target = rgba[::-1]
        rgb_error = abs(a[:, :, :3].astype(int) - target[:, :, :3].astype(int))
        alpha_error = abs(a[:, :, 3].astype(int) - target[:, :, 3].astype(int))
        results.append({"format": fmt.name,
                        "fixture_rgb_mean_error": float(rgb_error.mean()),
                        "fixture_alpha_max_error": int(alpha_error.max()) if fmt == TextureFormat.ETC2_RGBA8 else None,
                        "pass": bool(rgb_error.mean() < 15 and (fmt != TextureFormat.ETC2_RGBA8 or alpha_error.max() <= 8))})
    return {"fixtures": results, "all_pass": all(x["pass"] for x in results),
            "scope": "Synthetic ETC2 RGB/RGBA8 fixtures; does not establish ETC2 presence in source APK"}


def extract_all(source: Path, output: Path) -> int:
    import UnityPy
    from UnityPy.enums import TextureFormat
    from PIL import Image
    output = output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    report = {"source": source.name, "source_sha256": hashlib.file_digest(source.open("rb"), "sha256").hexdigest(),
              "mode": "offline_static_all_textures_and_sprites", "unitypy": UnityPy.__version__,
              "package_metadata": [], "packages": [], "resources": [], "failures": [],
              "non_raster_resources": [], "file_inventory": [], "category_method": "name heuristic; not semantic verification",
              "decoder_selfcheck": decoder_selfcheck()}
    with tempfile.TemporaryDirectory(prefix="unity_graphics_") as tmp:
        root = Path(tmp)
        prepare_source(source, root, report)
        is_seabattles = any(m.get("package") == "com.RoyaleGames.SeaBattles" for m in report["package_metadata"])
        paths = []
        from import_seabattles_local import candidate_asset
        for path in sorted(root.rglob("*")):
            if not path.is_file() or path.name.startswith("."):
                continue
            with path.open("rb") as stream:
                magic = stream.read(8)
            is_split_head = path.name.endswith(".split0") and candidate_asset(path.name[:-7])
            is_hashed_asset = False
            if re.fullmatch(r"[0-9a-fA-F]{32}", path.name):
                from UnityPy.helpers.ImportHelper import check_file_type
                from UnityPy.enums import FileType
                with path.open("rb") as stream:
                    kind, _ = check_file_type(stream)
                    is_hashed_asset = kind in (FileType.AssetsFile, FileType.BundleFile)
            if is_split_head:
                prefix = path.name[:-1]
                indices = sorted(int(p.name[len(prefix):]) for p in path.parent.glob(prefix + "*") if p.name[len(prefix):].isdigit())
                if indices != list(range(len(indices))):
                    report["failures"].append({"stage": "split_inventory", "file": str(path.relative_to(root)), "error": "Missing Unity split segments", "indices": indices})
                    continue
                report.setdefault("split_files", []).append({"file": str(path.relative_to(root)), "segments": len(indices), "order": "numeric; UnityPy native split reassembly"})
            if candidate_asset(path.name) or is_split_head or is_hashed_asset or magic.startswith((b"UnityFS", b"UnityRaw", b"UnityWeb")) or path.name == "unity default resources":
                paths.append(path)
        # One environment makes cross-file sprite texture references resolvable.
        env = UnityPy.Environment()
        for path in paths:
            print("Loading", path.name, flush=True)
            try:
                env.load_file(str(path))
                report["file_inventory"].append({"file": str(path.relative_to(root)), "status": "loaded"})
            except Exception as exc:
                report["failures"].append({"stage": "load", "file": str(path.relative_to(root)), "error": str(exc)})
        seen = set()
        for obj in env.objects:
            kind = obj.type.name
            if kind not in ("Texture2D", "Sprite", "Mesh", "ParticleSystem"):
                continue
            serialized = obj.assets_file.name
            identity = f"{serialized}:{obj.path_id}"
            if identity in seen:
                continue
            seen.add(identity)
            row = {"id": identity, "serialized_file": serialized, "path_id": obj.path_id, "type": kind}
            try:
                data = obj.read()
                row["name"] = str(getattr(data, "m_Name", getattr(data, "name", "")))
                if kind not in ("Texture2D", "Sprite"):
                    row["reason"] = "3D mesh or procedural effect; not a stored bitmap"
                    report["non_raster_resources"].append(row)
                    continue
                row["category"] = category(row["name"], kind)
                if kind == "Texture2D":
                    row.update(width=data.m_Width, height=data.m_Height, format=TextureFormat(data.m_TextureFormat).name,
                               stream_path=str(getattr(getattr(data, "m_StreamData", None), "path", "")))
                    if data.m_Width <= 0 or data.m_Height <= 0:
                        raise ValueError("Empty/runtime-generated Texture2D has no exportable dimensions")
                    if data.m_Width * data.m_Height > 67108864:
                        raise ValueError("Texture exceeds 64 megapixel export limit")
                picture = data.image
                if picture is None:
                    raise ValueError("Decoder returned no image")
                picture = picture.convert("RGBA")
                row.update(width=picture.width, height=picture.height, alpha=alpha_stats(picture))
                if is_seabattles:
                    row["category"] = seabattles_category(row)
                digest = hashlib.sha256(identity.encode()).hexdigest()[:12]
                relative = Path("png") / row["category"] / kind.lower() / f"{safe_name(row['name'])}__{digest}.png"
                path = output / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                save_png_atomic(picture, path)
                with Image.open(path) as verify:
                    if verify.mode != "RGBA" or verify.size != picture.size or verify.tobytes() != picture.tobytes():
                        raise ValueError("PNG roundtrip changed RGBA pixels")
                row.update(png=relative.as_posix(), png_sha256=hashlib.file_digest(path.open("rb"), "sha256").hexdigest(), status="success", png_roundtrip="exact")
                report["resources"].append(row)
                if len(report["resources"]) % 100 == 0:
                    print("Exported", len(report["resources"]), flush=True)
            except Exception as exc:
                row.update(stage="decode_or_export", error=f"{type(exc).__name__}: {exc}")
                report["failures"].append(row)
        del env
        gc.collect()
    report["summary"] = {
        "successful_pngs": len(report["resources"]), "failed_resources": len(report["failures"]),
        "by_type": dict(collections.Counter(r["type"] for r in report["resources"])),
        "by_category": dict(collections.Counter(r["category"] for r in report["resources"])),
        "texture_formats": dict(collections.Counter(r["format"] for r in report["resources"] if "format" in r)),
        "pngs_with_transparency": sum(r["alpha"]["min"] < 255 for r in report["resources"]),
        "etc2_source_textures": sum(r.get("format", "").startswith("ETC2") for r in report["resources"]),
    }
    (output / "scan_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    (output / "failed_resources.json").write_text(json.dumps(report["failures"], ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report["summary"], ensure_ascii=False), flush=True)
    return 0

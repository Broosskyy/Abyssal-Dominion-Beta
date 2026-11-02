#!/usr/bin/env python3
"""Build the M7 source-recovery summary from generated JSON catalogs."""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
EXTRACTED = ROOT.parents[1] / "unity_extracted" / "legacy"

CATEGORIES = {
    "ships_and_combat": ("ship", "cannon", "projectile", "ammo", "health", "damage", "repair", "target"),
    "world_ports_islands": ("map", "port", "island", "castle", "tower", "chest", "world"),
    "quests_progression": ("quest", "achievement", "rank", "reward", "leaderboard", "bonus"),
    "economy_inventory": ("shop", "store", "inventory", "auction", "purchase", "currency", "checkout"),
    "social_guild_chat": ("guild", "chat", "donation", "diplomacy"),
    "network_backend": ("network", "server", "playfab", "firestore", "fusion", "matchmaking"),
    "ui_input_mobile": ("ui", "input", "joystick", "mobile", "camera", "minimap"),
}


def main() -> int:
    inventory = json.loads((DOCS / "unity_legacy_inventory.json").read_text(encoding="utf-8"))
    scripts = json.loads((EXTRACTED / "structure" / "script_types.json").read_text(encoding="utf-8"))
    user_scripts = [s for s in scripts if s["assembly"] in {"Assembly-CSharp.dll", "Assembly-CSharp-firstpass.dll"}]
    full_names = sorted(".".join(part for part in (s["namespace"], s["class"]) if part) for s in user_scripts)
    categories: dict[str, list[str]] = {}
    for category, terms in CATEGORIES.items():
        categories[category] = [name for name in full_names if any(term in name.lower() for term in terms)]

    namespace_counts = Counter(name.rsplit(".", 1)[0] if "." in name else "<global>" for name in full_names)
    payload = {
        "schema": 1,
        "unity_version": list(inventory["unity_versions"]),
        "serialized_objects": inventory["object_count"],
        "type_counts": inventory["type_counts"],
        "user_script_type_count": len(user_scripts),
        "top_namespaces": dict(namespace_counts.most_common(40)),
        "categories": categories,
        "all_user_script_types": full_names,
    }
    (DOCS / "seefight_recovered_systems.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    counts = inventory["type_counts"]
    lines = [
        "# M7 – SeeFight Unity source recovery",
        "",
        "## Ergebnis",
        "",
        "Die drei bereitgestellten Archive wurden als Unity-2021.3.45f1-Build ausgewertet. Die Rohdaten bleiben ein nachvollziehbarer Test-/Referenzbestand und sind in allen Godot-Release-Presets ausgeschlossen.",
        "",
        "| Bereich | Gefunden |",
        "| --- | ---: |",
        f"| Serialisierte Unity-Objekte | {inventory['object_count']:,} |",
        f"| GameObjects | {counts.get('GameObject', 0):,} |",
        f"| MonoBehaviour-Komponenten | {counts.get('MonoBehaviour', 0):,} |",
        f"| Script-Typen gesamt | {counts.get('MonoScript', 0):,} |",
        f"| Projektspezifische Script-Typen | {len(user_scripts):,} |",
        f"| Texturen | {counts.get('Texture2D', 0):,} |",
        f"| Sprites | {counts.get('Sprite', 0):,} |",
        f"| Meshes | {counts.get('Mesh', 0):,} |",
        f"| Materialien | {counts.get('Material', 0):,} |",
        f"| Animationen | {counts.get('AnimationClip', 0):,} |",
        f"| AudioClips | {counts.get('AudioClip', 0):,} |",
        "",
        "## Wiederhergestellte Systemgruppen",
        "",
    ]
    for category, names in categories.items():
        examples = ", ".join(f"`{name}`" for name in names[:8])
        lines.extend([f"- **{category}**: {len(names)} Typen. {examples}", ""])
    lines.extend([
        "## Grenzen der Rekonstruktion",
        "",
        "Der PC-Build ist IL2CPP-kompiliert. Klassen-/Namespace-Namen, serialisierte Komponenten, Szenenstruktur, Asset-Daten und Konfigurationen sind auslesbar; der ursprüngliche C#-Quelltext mit Kommentaren und exakter Formatierung ist nicht Bestandteil des Builds. Godot-Systeme werden daher funktionsgleich aus den wiederhergestellten Strukturen neu implementiert.",
        "",
        "413 Texture2D-Objekte konnten nicht direkt als PNG dekodiert werden; davon meldeten 394 ein nicht unterstütztes Format/Layout und 19 einen ungültigen Ressourcenpfad. Sie bleiben im Originalarchiv und im Inventar referenziert. Alle 660 Meshes, 740 Materialbeschreibungen, 35 Animationen, 26 TextAssets und acht AudioClips wurden gesichert; die PCM-Audios wurden zusätzlich als WAV erzeugt.",
        "",
        "## Plattformregel",
        "",
        "Die vollständigen Unity-Referenzpakete sind nicht Teil von Android-, iOS-, Web- oder Desktop-Releases. Für Produktion werden daraus optimierte Godot-Assets bzw. neu lizenzierte/erstellte Ersatzassets abgeleitet.",
        "",
    ])
    (DOCS / "M7_RECOVERY_REPORT.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"user_scripts": len(user_scripts), "categories": {k: len(v) for k, v in categories.items()}}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

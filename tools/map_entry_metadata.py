#!/usr/bin/env python3
"""Map original IL2CPP metadata declarations to the new local entry flow."""
import csv
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "docs/il2cpp/Assembly-CSharp.metadata-skeleton.cs"
text = source.read_text()
types = []
for name in ["Code.Demo.UI.UILogin", "Code.Demo.UI.UIRegister", "Code.Demo.UI.UIResetPassword"]:
    match = re.search(r"// TYPE #\d+: " + re.escape(name) + r"\n(.*?)(?=// TYPE #|\Z)", text, re.S)
    if match:
        types.append({"type": name, "fields": re.findall(r"//\s+FIELD (.+)", match[1]),
                      "methods": re.findall(r"//\s+METHOD (.+)", match[1])})
panels = []
with (root / "docs/unity_legacy_inventory.csv").open(newline="") as file:
    for row in csv.reader(file):
        if len(row) > 3 and row[0].endswith("/level2") and row[1] == "GameObject" and row[3] in ["Login Panel", "Register Panel", "Login_Register", "Login Window (1)"]:
            panels.append({"source": row[0], "type": row[1], "path_id": row[2], "name": row[3]})
report = {"source": str(source.relative_to(root)), "types": types, "panel_inventory": panels,
          "boundary": "Metadata only, not original method bodies or authentication backend. Password/email/recovery fields are NOT implemented in the local profile selector."}
(root / "docs/m13_entry_metadata.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({"types": len(types), "panels": len(panels)}))

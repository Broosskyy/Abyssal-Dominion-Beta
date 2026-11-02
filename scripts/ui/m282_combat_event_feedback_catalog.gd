class_name M282CombatEventFeedbackCatalog
extends RefCounted
static func overview(runtime:M282CombatEventFeedbackRuntime)->Dictionary:
	if runtime==null:return {"title":"Combat Event Feedback","state":"SERVER REQUIRED","detail":"Keine M282 Combat-Feedback-Replica gebunden."}
	var s:=runtime.snapshot(); return {"title":"Combat Event Feedback","state":"SERVER REPLICA" if int(s.get("feedback_revision",-1))>=0 else "WAITING","detail":"Feedback rev %d · server tick %d · entries %d"%[int(s.get("feedback_revision",-1)),int(s.get("server_tick",-1)),int(s.get("entry_count",0))]}
static func coalescing()->Dictionary:return {"title":"Damage / Heal Coalescing","state":"DENSITY CONTROL","detail":"Bestätigte Standardtreffer/Heals können pro Ziel+Typ gebündelt werden; Crit/Block/Miss bleiben als wichtige Einzelereignisse lesbar. Finale Dichte bleibt messungsbasiert."}
static func hit_confirmation()->Dictionary:return {"title":"Hit · Crit · Block · Heal","state":"SERVER CONFIRMED","detail":"Nur serverbestätigte M269/M270-Ereignisse erzeugen bestätigte Zahlen/Marker. Lokaler Muzzle-Flash oder Projectile-Flug beweist keinen Treffer."}
static func impacts()->Dictionary:return {"title":"Impact VFX Hooks","state":"PRESENTATION ONLY","detail":"Projectile-/Salven-Impact-Hooks dürfen Trefferwirkung verstärken, wenden aber niemals Schaden/Heal/Status an und bestätigen keinen Impact selbst."}
static func sea_chart()->Dictionary:return {"title":"Sea-Chart Combat Feed","state":"CENTER-PRESERVING","detail":"Kompakter zielnaher Feed statt Zahlenwand; Kartenmitte, Tap-to-Sail, Angriff unten rechts und Kamera-Joystick unten links bleiben frei."}
static func responsive()->Dictionary:return {"title":"Mobile / Desktop Feedback","state":"PARITY FOUNDATION","detail":"Mobile bündelt stärker, Desktop bietet mehr Raum; Priorität und serverbestätigte Wahrheit bleiben plattformgleich."}
static func authority()->Dictionary:return {"title":"Combat Feedback Authority","state":"FAIL-CLOSED","detail":"Client darf darstellen/dismiss/navigation auslösen, aber keine Damage-/Heal-Zahl, Crit, Block, Projectile-Impact oder Revision autorisieren; TEST/GLOBAL bleiben getrennt."}
